from sqlalchemy import Column, BigInteger, String, DateTime, func
from sqlalchemy.dialects.mysql import JSON, MEDIUMTEXT
from app.db.session import Base


class AiConversation(Base):
    __tablename__ = "ai_conversation"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    title = Column(String(200), nullable=False, default="新对话")
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


class AiMessage(Base):
    __tablename__ = "ai_message"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    conversation_id = Column(BigInteger, nullable=False, index=True)
    role = Column(String(20), nullable=False)
    content = Column(MEDIUMTEXT, nullable=False)
    sources = Column(JSON, nullable=True)
    resources = Column(JSON, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
