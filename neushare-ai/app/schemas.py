from typing import Optional
from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=4000)
    conversation_id: Optional[int] = None
    resource_id: Optional[int] = None


class ConversationCreate(BaseModel):
    title: str = "新对话"


class ConversationOut(BaseModel):
    id: int
    title: str
    updated_at: str


class MessageOut(BaseModel):
    id: int
    conversation_id: int
    role: str
    content: str
    sources: Optional[list] = None
    resources: Optional[list] = None
    created_at: str
