"""配置读取。

规则只有一条：**所有密钥只从环境变量 / .env 读**，代码里不写死、不打印、不进日志。
.env 放在 neushare-ai/ 根目录（和 requirements.txt 同级），已被 .gitignore 忽略。
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",  # .env 里多写了别的键不报错
        case_sensitive=False,
    )

    # 大模型
    deepseek_api_key: str = ""
    deepseek_base_url: str = "https://api.deepseek.com"
    deepseek_model: str = "deepseek-chat"

    # 联网搜索
    tavily_api_key: str = ""
    tavily_max_results: int = 5
    tavily_proxy: str = ""

    # 业务后端与服务行为
    neushare_api_base: str = "http://127.0.0.1:8080"
    cors_origins: str = "http://localhost:5173,http://127.0.0.1:5173"
    rate_limit_per_minute: int = 20
    mock_mode: bool = False

    # 上下文窗口保护（详见 app/memory.py）
    memory_enabled: bool = True
    memory_max_messages: int = 40       # 消息条数到这个值就压缩
    memory_max_tokens: int = 12000      # 或估算 token 到这个值就压缩
    memory_keep_recent: int = 8         # 压缩后保留最近几条完整消息
    memory_clear_tool_enabled: bool = False  # 默认关：直接删原文不可逆，信息保真优先
    memory_clear_tool_tokens: int = 8000  # 开启时的触发阈值
    memory_clear_tool_keep: int = 3       # 保留最近几次工具结果不清理

    # 长期记忆（跨会话，app/long_memory.py）：只有登录用户启用
    memory_long_term_enabled: bool = True
    memory_long_term_max_inject: int = 5  # 每轮最多注入几条记忆

    @property
    def cors_origin_list(self) -> list[str]:
        return [x.strip() for x in self.cors_origins.split(",") if x.strip()]

    @property
    def has_deepseek(self) -> bool:
        return bool(self.deepseek_api_key.strip())

    @property
    def has_tavily(self) -> bool:
        return bool(self.tavily_api_key.strip())

    @property
    def web_search_mode(self) -> str:
        """给 /health 用：说明当前联网到底是真联网、演示还是不可用。"""
        if self.mock_mode:
            return "mock"
        return "tavily" if self.has_tavily else "unavailable"

    @property
    def memory_policy(self) -> str:
        """给 /health 用：一眼看出当前窗口保护策略，演示时不用翻代码。"""
        if not self.memory_enabled:
            return "disabled"
        parts = []
        if self.memory_clear_tool_enabled:
            parts.append(f"clear-tool@{self.memory_clear_tool_tokens}tok")
        parts.append(
            f"summary@{self.memory_max_messages}msg/{self.memory_max_tokens}tok "
            f"keep={self.memory_keep_recent}"
        )
        return " ".join(parts)


@lru_cache
def get_settings() -> Settings:
    """单例，避免每次请求都重读 .env。测试里可直接覆盖返回值。"""
    return Settings()
