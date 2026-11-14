"""Embeddings + FAISS vector store (build / load / search)."""
from pathlib import Path
from app.config import settings

_embeddings = None
_store = None


def _device() -> str:
    try:
        import torch
        return "cuda" if torch.cuda.is_available() else "cpu"
    except Exception:
        return "cpu"


def get_embeddings():
    global _embeddings
    if _embeddings is not None:
        return _embeddings
    if settings.embedding_provider == "zhipu" and settings.zhipu_api_key:
        from langchain_openai import OpenAIEmbeddings
        _embeddings = OpenAIEmbeddings(
            model=settings.zhipu_embedding_model,
            api_key=settings.zhipu_api_key,
            base_url="https://open.bigmodel.cn/api/paas/v4/",
        )
    else:
        from langchain_community.embeddings import HuggingFaceEmbeddings
        _embeddings = HuggingFaceEmbeddings(
            model_name=settings.embedding_model_name,
            model_kwargs={"device": _device()},
            encode_kwargs={"normalize_embeddings": True},
        )
    return _embeddings


def build_vectorstore(docs):
    global _store
    from langchain_community.vectorstores import FAISS
    store = FAISS.from_documents(docs, get_embeddings())
    Path(settings.vectorstore_dir).mkdir(parents=True, exist_ok=True)
    store.save_local(settings.vectorstore_dir)
    _store = store
    return store


def load_vectorstore():
    global _store
    if _store is not None:
        return _store
    from langchain_community.vectorstores import FAISS
    _store = FAISS.load_local(
        settings.vectorstore_dir, get_embeddings(), allow_dangerous_deserialization=True
    )
    return _store


def similarity_search(query: str, k: int = 4, source_type: str | None = None):
    """Search the vector store; filter by source_type in Python for robustness."""
    store = load_vectorstore()
    docs = store.similarity_search(query, k=k * 5)
    if source_type:
        docs = [d for d in docs if d.metadata.get("source_type") == source_type]
    return docs[:k]
