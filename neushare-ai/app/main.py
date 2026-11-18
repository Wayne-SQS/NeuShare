"""NeuShare AI Service — FastAPI entrypoint."""
import json
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse

from app.config import settings
from app.auth.jwt import extract_user
from app.db.models import AiConversation, AiMessage
from app.db.session import SessionLocal
from app.middleware.ratelimit import is_allowed
from app.ingestion import builder
from app.agent import stream as agent_stream
from app.schemas import ChatRequest, ConversationCreate

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("main")


def _fmt(dt: Optional[datetime]) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S") if dt else ""


@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("starting neushare-ai on port %s", settings.ai_service_port)
    try:
        result = builder.ensure_index()
        if result:
            log.info("index built on startup: notes=%d resources=%d chunks=%d", *result)
        # warmup embeddings + vectorstore so first request is fast
        from app.ingestion.vectorstore import load_vectorstore
        load_vectorstore()
        log.info("vectorstore warmed up")
    except Exception as e:  # noqa: BLE001
        log.exception("startup index warmup failed: %s", e)
    yield
    log.info("neushare-ai shutting down")


app = FastAPI(title="NeuShare AI Service", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _require_user(authorization: Optional[str]) -> dict:
    user = extract_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="未登录或登录已过期")
    return user


def _own_conversation(db, cid: int, user_id: int) -> AiConversation:
    conv = db.get(AiConversation, cid)
    if not conv or conv.user_id != user_id:
        raise HTTPException(status_code=404, detail="会话不存在")
    return conv


@app.get("/ai/health")
def health():
    """自检：联网状态、降级模式、索引状态；不返回任何密钥值。"""
    from app.agent.guardrails import health_payload
    return {"code": 0, "data": health_payload(builder.index_exists())}


# ---------------- conversations ----------------

@app.get("/ai/conversations")
def list_conversations(authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    db = SessionLocal()
    try:
        rows = (
            db.query(AiConversation)
            .filter(AiConversation.user_id == user["userId"])
            .order_by(AiConversation.updated_at.desc())
            .limit(100)
            .all()
        )
        return {
            "code": 0,
            "data": [
                {"id": c.id, "title": c.title, "updated_at": _fmt(c.updated_at)}
                for c in rows
            ],
        }
    finally:
        db.close()


@app.post("/ai/conversations")
def create_conversation(body: ConversationCreate, authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    db = SessionLocal()
    try:
        conv = AiConversation(user_id=user["userId"], title=body.title or "新对话")
        db.add(conv)
        db.commit()
        db.refresh(conv)
        return {"code": 0, "data": {"id": conv.id, "title": conv.title}}
    finally:
        db.close()


@app.get("/ai/conversations/{cid}/messages")
def list_messages(cid: int, authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    db = SessionLocal()
    try:
        _own_conversation(db, cid, user["userId"])
        rows = (
            db.query(AiMessage)
            .filter(AiMessage.conversation_id == cid)
            .order_by(AiMessage.id.asc())
            .all()
        )
        return {
            "code": 0,
            "data": [
                {
                    "id": m.id,
                    "conversation_id": m.conversation_id,
                    "role": m.role,
                    "content": m.content,
                    "sources": m.sources,
                    "resources": m.resources,
                    "created_at": _fmt(m.created_at),
                }
                for m in rows
            ],
        }
    finally:
        db.close()


@app.delete("/ai/conversations/{cid}")
def delete_conversation(cid: int, authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    db = SessionLocal()
    try:
        conv = _own_conversation(db, cid, user["userId"])
        db.delete(conv)
        db.commit()
        return {"code": 0, "data": True}
    finally:
        db.close()


# ---------------- chat ----------------

def _get_or_create_conversation(db, user_id: int, conversation_id: Optional[int], question: str) -> AiConversation:
    if conversation_id:
        conv = _own_conversation(db, conversation_id, user_id)
        if not conv.title or conv.title == "新对话":
            conv.title = question[:30] or "新对话"
            db.commit()
        return conv
    title = question[:30] or "新对话"
    conv = AiConversation(user_id=user_id, title=title)
    db.add(conv)
    db.commit()
    db.refresh(conv)
    return conv


def _recent_history(db, cid: int, limit: int = 6) -> list:
    rows = (
        db.query(AiMessage)
        .filter(AiMessage.conversation_id == cid)
        .order_by(AiMessage.id.desc())
        .limit(limit)
        .all()
    )
    return [{"role": m.role, "content": m.content} for m in reversed(rows)]


@app.post("/ai/chat")
async def chat(body: ChatRequest, authorization: Optional[str] = Header(None)):
    """Non-streaming chat for testing / fallback."""
    user = _require_user(authorization)
    if not is_allowed(user["userId"]):
        return JSONResponse({"code": 429, "message": "提问过于频繁，请稍后再试", "data": None}, 429)

    db = SessionLocal()
    try:
        conv = _get_or_create_conversation(db, user["userId"], body.conversation_id, body.question)
        cid = conv.id
        db.add(AiMessage(conversation_id=cid, role="user", content=body.question))
        db.commit()
        history = _recent_history(db, cid)
    finally:
        db.close()

    full, sources, resources, web_sources, notice = "", [], [], [], ""
    async for etype, payload in agent_stream.stream_answer(body.question, history, body.resource_id):
        if etype == "token":
            full += payload
        elif etype == "sources":
            sources = payload
        elif etype == "resources":
            resources = payload
        elif etype == "web_sources":
            web_sources = payload
        elif etype == "notice":
            notice = payload
        elif etype == "error":
            return JSONResponse({"code": 500, "message": payload, "data": None}, 500)

    db = SessionLocal()
    try:
        db.add(
            AiMessage(
                conversation_id=cid,
                role="assistant",
                content=full,
                sources=json.dumps(sources, ensure_ascii=False) if sources else None,
                resources=json.dumps(resources, ensure_ascii=False) if resources else None,
            )
        )
        db.commit()
    finally:
        db.close()
    return {"code": 0, "data": {"conversation_id": cid, "content": full,
                                "sources": sources, "resources": resources,
                                "web_sources": web_sources, "notice": notice}}


@app.post("/ai/chat/stream")
async def chat_stream(body: ChatRequest, authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    if not is_allowed(user["userId"]):
        return JSONResponse({"code": 429, "message": "提问过于频繁，请稍后再试", "data": None}, 429)

    db = SessionLocal()
    try:
        conv = _get_or_create_conversation(db, user["userId"], body.conversation_id, body.question)
        cid = conv.id
        db.add(AiMessage(conversation_id=cid, role="user", content=body.question))
        db.commit()
        history = _recent_history(db, cid)
    finally:
        db.close()

    async def event_gen():
        full, sources, resources = "", [], []
        try:
            async for etype, payload in agent_stream.stream_answer(
                body.question, history, body.resource_id
            ):
                if etype == "token":
                    full += payload
                    yield f"event: token\ndata: {json.dumps({'delta': payload}, ensure_ascii=False)}\n\n"
                elif etype == "sources":
                    sources = payload
                    yield f"event: sources\ndata: {json.dumps({'sources': payload}, ensure_ascii=False)}\n\n"
                elif etype == "resources":
                    resources = payload
                    yield f"event: resources\ndata: {json.dumps({'resources': payload}, ensure_ascii=False)}\n\n"
                elif etype == "web_sources":
                    yield f"event: web_sources\ndata: {json.dumps({'sources': payload}, ensure_ascii=False)}\n\n"
                elif etype == "notice":
                    yield f"event: notice\ndata: {json.dumps({'message': payload}, ensure_ascii=False)}\n\n"
                elif etype == "error":
                    yield f"event: error\ndata: {json.dumps({'message': payload}, ensure_ascii=False)}\n\n"
                elif etype == "done":
                    yield f"event: done\ndata: {json.dumps({'conversation_id': cid}, ensure_ascii=False)}\n\n"
        finally:
            db2 = SessionLocal()
            try:
                db2.add(
                    AiMessage(
                        conversation_id=cid,
                        role="assistant",
                        content=full,
                        sources=json.dumps(sources, ensure_ascii=False) if sources else None,
                        resources=json.dumps(resources, ensure_ascii=False) if resources else None,
                    )
                )
                db2.commit()
            except Exception as e:  # noqa: BLE001
                log.exception("save assistant message failed: %s", e)
            finally:
                db2.close()

    return StreamingResponse(
        event_gen(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive", "X-Accel-Buffering": "no"},
    )


# ---------------- admin ----------------

@app.post("/ai/index/rebuild")
def rebuild_index(authorization: Optional[str] = Header(None)):
    user = _require_user(authorization)
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="无访问权限")
    try:
        notes, resources, chunks = builder.build_index()
        return {"code": 0, "data": {"notes": notes, "resources": resources, "chunks": chunks}}
    except Exception as e:  # noqa: BLE001
        log.exception("rebuild failed")
        return JSONResponse({"code": 500, "message": str(e), "data": None}, 500)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=settings.ai_service_port, reload=False)
