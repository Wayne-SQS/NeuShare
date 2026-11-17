# neushare-ai · NeuShare 智能助手服务

Python 版智能体：**FastAPI + LangChain 1.x + LangGraph + Tavily 联网搜索 + DeepSeek**。
它是**独立进程**，不改 Java 业务后端一行代码。

```
Vue3 / HarmonyOS 客户端
        │  /api/ai/*（SSE 流式）
        ▼
neushare-ai  :8000   ← 本服务：Agent 编排、工具、联网、引用溯源
        │                    ├──→ Tavily API（联网网页）
        │                    └──→ DeepSeek API（deepseek-flash，兼容别名 deepseek-chat）
        │  GET /api/resource/list|detail  （只读，不写库）
        ▼
neushare-backend :8080  ← 业务、权限、status=1 审核把关、MySQL
```

权限与数据仍然归 Java 后端管，AI 侧只读、绕不过审核状态——**模型不碰业务表**。
边界是**表级**的，不是「能不能用数据库」：AI 侧可以用自己独占的 checkpoint 表存会话状态
（见第 5 节），但 `resource` / `user` 等业务表一律走 Java 后端接口，不重复实现权限。

---

## 1. 从零跑起来

需要 Python 3.11+（本机 3.14 实测可跑）。在 `neushare-ai/` 目录下依次执行：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

copy .env.example .env      # 然后用记事本打开 .env 填 key
uvicorn app.main:app --reload --port 8000
```

打开 `http://127.0.0.1:8000/docs` 就能点着调接口；`http://127.0.0.1:8000/api/ai/health` 看配置状态。

`.env` 里两个 key：

| 变量 | 是否必填 | 去哪拿 |
|---|---|---|
| `DEEPSEEK_API_KEY` | **必填**（不填 `/chat` 返回 503） | platform.deepseek.com |
| `TAVILY_API_KEY` | 要真联网才填 | tavily.com 注册 → API Keys，形如 `tvly-...` |

### 模型名与上限（2026-11-16 实测）

`.env` 写的是 `DEEPSEEK_MODEL=deepseek-chat`，但**服务端早就不把它当 V3.2 用了**。
拿这把 key 实测 `/models` 和 `/chat/completions`：

| 项 | 实测 / 官方值 |
|---|---|
| `/models` 列出的模型 | `deepseek-flash`（V4.1-Flash）、`deepseek-v4-pro` |
| 用 `deepseek-chat` 发请求，返回 `model` | **`deepseek-flash`**，HTTP 200 |
| `context_window` | **1,048,576 token（1M）** |
| `max_output_tokens` | **393,216 token（384K）** |
| 并发限制（账号粒度） | flash 2500 / v4-pro 500，超限 HTTP 429 |

旧文档里「`deepseek-chat` = 128K 上下文、最大输出 8K」是 V3.2 时代数据，**已过期**。
官方 Change Log：2026-04-24 V4 上线后，`deepseek-chat` / `deepseek-reasoner` 作为兼容别名
分别指向 `deepseek-v4-flash` 的非思考 / 思考模式，原定 2026-07-24 弃用；今天仍可调用，
但属于随时可能失效的兼容层。

那个工具调用的坑要说准：教程里踩到的 400 是「**思考模式 + 强制 `tool_choice`**」的组合，
不是 `flash` 不能用工具。LangChain `create_agent` 走普通 tool calling（不强制），所以跑得通。
将来显式切 `deepseek-flash` 时**必须同时传 `thinking: {"type": "disabled"}`**，只改模型名
会默认开启思考模式，延迟和输出结构都变。

---

## 2. Tavily 联网功能怎么用

1. 拿到 `tvly-` 开头的 key，填进 `.env` 的 `TAVILY_API_KEY`，`MOCK_MODE` 保持 `false`。
2. 重启服务，`/api/ai/health` 里 `web_search_mode` 变成 `tavily` 就是真联网了。
3. 之后问「2027 考研 408 大纲变了吗」「东北大学软件学院招生简章」这类时效性问题，
   Agent 会自己调 `web_search`，回答里带网页标题和 URL。

**没 key 也不会崩**，这是刻意做的降级：

| 状态 | web_search 的行为 |
|---|---|
| 有 key | 真联网。优先走 `langchain_tavily.TavilySearch`；这个包没装就自动用 `httpx` 直调同一个 REST 接口 |
| 没 key | 返回 `mode=unavailable` + 明确说明，system prompt 要求模型如实告诉用户「现在没法联网」，**绝不编造网页** |
| `MOCK_MODE=true` | 返回 `example.com` 的占位条目，用来演示 / 跑测试，不发外网 |

**代理坑（本机特有）**：注册表里有常驻 `HTTP_PROXY/HTTPS_PROXY=http://127.0.0.1:7897`。
Tavily 是海外接口，Clash Verge 没开时会报 `ECONNREFUSED 127.0.0.1:7897`；
要么开代理，要么在 `.env` 填 `TAVILY_PROXY=http://127.0.0.1:7897`，
要么启动前在该终端清掉代理变量。DeepSeek 和 `localhost` 的调用代码里已写 `trust_env=False`
走直连，不受这个影响。

**安全**：`.env` 已被 `.gitignore` 忽略（仓库根和服务目录各一份）。这个仓库是公开的，
密钥一旦提交进 git 历史就得轮换，别指望删文件能了事。

---

## 3. 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/ai/chat` | 对话；`stream=true` 返回 `text/event-stream`，`false` 返回完整 JSON。请求体可带 `access_token`（用户 JWT）启用 BYOK |
| GET | `/api/ai/web-search?q=...` | 不经过大模型，直接看 Tavily 原始结果（调参/演示用，固定走平台 key） |
| GET | `/api/ai/health` | 配置自检（含联网状态与窗口保护策略），不返回任何密钥值 |

```powershell
# 一次性回答
curl -X POST http://127.0.0.1:8000/api/ai/chat `
  -H "Content-Type: application/json" `
  -d '{\"question\":\"平台上有操作系统的复习资料吗\",\"session_id\":\"demo\",\"stream\":false}'

# 流式（curl 会逐段打印）
curl -N -X POST http://127.0.0.1:8000/api/ai/chat `
  -H "Content-Type: application/json" `
  -d '{\"question\":\"2027 考研 408 大纲有变化吗\",\"session_id\":\"demo\",\"stream\":true}'

# 单看联网结果
curl "http://127.0.0.1:8000/api/ai/web-search?q=2027%20%E8%80%83%E7%A0%94%20408%20%E5%A4%A7%E7%BA%B2"
```

SSE 事件：`token`（正文片段）、`tool`（工具跑完）、`source`（来源卡片，含
`type=web|platform` / `title` / `url` / `ref_id`）、`error`、`done`。
前端按 `\n\n` 切事件，收到 `source` 就渲染「来源」卡片，点 `ref_id` 跳站内详情页。

### 用户自带 key（BYOK）

平台 key 是部署者付钱，所以支持用户填自己的 key（`/profile/ai` 设置页）：

| 环节 | 文件 | 说明 |
|---|---|---|
| 配置存储 | Java 侧 `ai_user_api_config` 表（V7 迁移） | key 用 AES-256-GCM 加密落库，主密钥在 `application.yml` 的 `ai.key-encrypt-secret` |
| 用户接口 | Java `GET/PUT /api/ai/config` | 前端设置页用，只回掩码绝不回明文；**特意不放 `/api/user/*` 下，那个路径在 JWT 白名单里** |
| 取 key 接口 | Java `GET /api/ai/config/internal` | 给 AI 服务调，持用户 JWT 校验身份，返回解密 key |
| AI 侧取 key | `app/user_keys.py` | 透传用户的 `Authorization` 调 internal 接口，60 秒缓存，任何失败降级平台 key |
| AI 侧装配 | `app/agent.py` `get_agent_for_user_keys` | 每组用户 key 一个 agent 实例（上限 32 组），改 key = 会话记忆重开 |

前端把 JWT 放进 `ChatRequest.access_token` 即可；没带 / 后端没起 / 用户没配，
一律自动降级平台 key，对话功能不受影响。AI 侧把 `thread_id` 加了 `u{userId}:` 前缀，
BYOK 会话和平台会话互不串台。

---

## 4. 代码怎么读（按这个顺序，对零基础最友好）

| 文件 | 一句话 |
|---|---|
| `app/config.py` | 从 `.env` 读配置，判断「有没有 key、是不是演示模式」 |
| `app/schemas.py` | 用 Pydantic 定义请求/响应，顺手做参数校验 |
| `app/prompts.py` | 写在 system prompt 里的硬规则：分渠道、标来源、不许编造 |
| `app/tools/web_search.py` | **本次新增**：Tavily 联网工具 + 三级降级 + 来源解析 |
| `app/tools/platform.py` | 站内只读工具：资源搜索 / 详情 / 跳页指令 |
| `app/agent.py` | `create_agent` 把模型+工具+提示编成图，`InMemorySaver` 管多轮记忆 |
| `app/memory.py` | 上下文窗口保护：清旧工具输出 + 超阈值压成摘要 |
| `app/long_memory.py` | 长期记忆：跨会话按用户隔离，后台提取事实、每轮召回注入 |
| `app/user_keys.py` | **BYOK**：带用户 JWT 去 Java 后端取他自己配的 key，失败降级平台 key |
| `app/routers/chat.py` | HTTP 层：SSE 流式、限流、来源事件、非流式兜底、BYOK 分流 |
| `app/main.py` | 建 FastAPI app、CORS、挂路由 |

`tests/` 是不依赖任何 key 的测试：先 `pip install pytest`（测试依赖，不放进运行用的
`requirements.txt`），再 `pytest -q`（18 条：冒烟 5 + 上下文保护 5 + BYOK 3 + 长期记忆 5）。

---

## 5. 会话记忆与上下文窗口

**先说根子上的问题**：大模型本身没有记忆，每次调用只看这一轮传进去的消息列表。
多轮对话靠 `InMemorySaver` 按 `thread_id` 存快照，下个请求带同一个 `session_id`
进来时框架自动把历史拼回去，代码里不用手写「查历史、拼 prompt」。

但历史一直涨会出事：模型硬上限是 **1M token**（见第 1 节），真撑满了直接 400；
没超也会让首 token 变慢、成本上升，早期信息被稀释。
所以每次调模型前的核心保护是**历史会话压缩（归纳式）**（在 `app/memory.py`）：

| 层 | 做什么 | 触发 | 代价 | 默认 |
|---|---|---|---|---|
| 历史会话压缩 | `SummarizationMiddleware` 把更早的历史**归纳总结**成一段摘要，只留「摘要 + 最近 8 条」 | 消息 ≥ 40 条 **或** 估算 token ≥ 12000 | 多一次模型调用 | **开** |
| 清旧工具输出 | `ClearToolUsesEdit` 把较早的工具结果原文换成一行占位——**不可逆、无归纳** | 估算 token ≥ 8000 | 零，不发请求 | 关（`MEMORY_CLEAR_TOOL_ENABLED=false`） |

压缩的原则是**先归纳、后压缩，不归纳的内容不许消失**：摘要 prompt 强制完整保留六类内容
——本次会话任务目标、中间完成的重要产物（关键数据/资源 #ID/URL 原样照抄）、用户的
新要求与最新指令、已确认事实及来源（区分平台/联网）、查过哪些工具及结论、未解决问题；
并写明不许借压缩编造资料标题和链接——和工具的防幻觉口径一致。清旧工具输出层是
**默认关闭的可选项**：它省 token 但直接丢原文、没有归纳，信息保真优先；确有成本压力
再显式打开。两个中间件通过 `RemoveMessage` 改写图状态，改动会一起写回 checkpointer。

阈值都在 `.env` 里（`MEMORY_*`），`/api/ai/health` 的 `memory_policy` 会显示当前策略，
`MEMORY_ENABLED=false` 可整体关掉做对照实验。

**注意这些是软阈值，不是模型上限**：12000 只占 1M 的约 1.1%，留得这么保守是为了省成本、
降首 token 延迟、避免 `lost in the middle`，以及防止 Tavily 返回的长网页摘要把窗口撑爆。
想让 Agent 记住更长对话可以上调到 32000 / 64000，但不建议贴着 1M 用。

### 长期记忆（跨会话，`app/long_memory.py`）

短期记忆随会话消亡；长期记忆跟着「人」走：备考方向、提问偏好、复习进度，重启后依然在。
机制对应 LangGraph 的 **store** 抽象，和 checkpointer 并行、互不替代：

| 环节 | 实现 | 说明 |
|---|---|---|
| 存储 | `InMemoryStore` 单例，namespace `("users", userId, "study")` | 按用户隔离；开发期重启会丢，生产换 `PostgresStore` 时代码零改动 |
| 写（提取） | 响应发出后在 **daemon 线程**里把本轮问答发给模型提取事实 | 只提取 goal / preference / progress 三类稳定信息，没有就返回空数组；同步做的话用户每轮都要多等一次模型调用 |
| 读（召回） | 每轮对话开始 `recall(userId)` 取最近 N 条 | 通过自定义 state 字段 `long_term_memory` 传给 agent，`dynamic_prompt` 中间件把它拼进 system prompt——**不进消息历史，不逐轮膨胀** |
| 开关 | `MEMORY_LONG_TERM_ENABLED`（默认开） | 只有登录用户（access_token 能解析出 userId）启用；匿名会话完全不记忆 |

实测：写入「操作系统复习到第 6 章」后，新会话问「我上次复习到哪了？」，模型直接答对——
历史消息里没有这条，答案完全来自长期记忆召回。

**实测**：故意塞 13 条历史并把阈值调到 8 条，压缩后 state 剩 6 条，摘要保留了
「站内资源 #100–104」，接着问「刚才问到第几章」答「第 6 章」，上下文没断。

> 仍然没做的：进程重启丢会话、多副本不共享、`session_id` 未绑定登录用户。见第 8 节。

---

## 6. 护栏（面试要能讲清）

- **工具白名单**：只注册 4 个工具（`web_search` / `search_platform_resources` /
  `get_resource_detail` / `navigate`），模型拿不到别的入口。
- **只读（业务表级）**：站内数据走 Java 后端接口，`status=1` 由后端强制过滤，AI 服务不碰业务表。这不等于「不能用数据库」——Agent 自己的会话状态可以落在独立的 checkpoint 表里，与业务表隔离、单独授权。
- **引用溯源**：联网结果带 URL、站内结果带资源 ID，回答里必须标注；两者冲突都列出来。
- **不编造**：缺 key、调用失败、后端没起，工具都返回明确的 `note`，不是伪造数据。
- **限流**：内存滑动窗口，默认 20 次/分钟/会话；工具异常转成文本回灌，不炸 Agent 循环。
- **跳页白名单**：`navigate` 只放行 5 个页面，防止模型拼出任意 URL。

---

## 7. 三端接入

- **Web（Vue3）**：`fetch` + `ReadableStream` 手动解析 SSE（`EventSource` 不支持 POST，
  而提问可能很长）。收到 `action=navigate` 用 `router.push`。
- **HarmonyOS**：`@ohos.net.http` 的 `on('dataReceive')` 分块接收，自己按 `\n\n` 切事件；
  `navigate` 落地为 `router.pushUrl`。
- **Java 后端**：**不用改**。若前端走同一域名，用 Nginx 把 `/api/ai/` 反代到 8000 即可。

---

## 8. 现在的边界（别吹过头）

- 会话用 `InMemorySaver`，**进程重启就丢**；窗口裁剪和摘要已做，但要持久化得换 Postgres/MySQL checkpointer。
- 限流是单进程内存版，多副本要换 Redis。
- **还没做登录鉴权**：`/api/ai/*` 目前是公开接口，公网部署前必须补 JWT 校验，
  并把 `userId` 从网关透传进来（不能信模型传参）。
- 站内检索目前复用 Java 后端的全文检索，向量 RAG / 重排序 / 评测集在 `docs/04` 的后续路线里。
- Tavily 给的是网页摘要，不是权威定论；涉及报考、考试、政策要提醒用户去官网复核。
