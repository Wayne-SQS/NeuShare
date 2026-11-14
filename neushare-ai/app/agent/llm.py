"""DeepSeek LLM via OpenAI-compatible interface."""
from langchain_openai import ChatOpenAI
from app.config import settings


def get_llm() -> ChatOpenAI:
    base_url = settings.deepseek_base_url.rstrip("/") + "/v1"
    return ChatOpenAI(
        model=settings.deepseek_model,
        api_key=settings.deepseek_api_key,
        base_url=base_url,
        temperature=0.3,
        streaming=True,
    )
