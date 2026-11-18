# NeuShare 后端 Python 化迁移计划（路线 A：FastAPI 完全替换）

> 版本：v1.5 ｜ 日期：2026-11-17 ｜ 状态：实施中（阶段 0–4 已完成；M0 黄金基准 + M2 契约修复完成，只读 89/89、全量 147/147 一致；阶段 5、7 待做）
> 背景：基于上一轮代码审查发现的高并发问题，决定用 Python（FastAPI 异步生态）重写现有 Spring Boot 后端，保持 API 契约不变，前端与鸿蒙端零改动。
> v1.1 变更：补充 `neushare-ai`（已落地的 LangChain + FastAPI AI 微服务，见 `fix/phase2-audit` 分支）与新 Python 后端的对接清单，避免迁移后 AI 服务失联。
> v1.2 变更：新增第十一章——为 `neushare-ai` 增加『用户自带 API Key + 充值余额』门禁（演示版），解决所有用户白嫖服务端 DeepSeek 额度的问题。
> v1.3 变更：阶段 0–4 落地完成（含 19 个管理员接口），新增「实施进度」章节记录实测证据。
> v1.4 变更：新增 M0「契约黄金基准」——把"契约一致"从读代码推断升级为实跑比对（Java 8081 vs Python 8082），暴露 8 类真实差异，详见 `neushare-backend-py/tests/contract/FINDINGS.md`。
> v1.5 变更：M2 第一轮修复完成（F1–F8 全部落地），复测只读 89/89、全量 147/147 一致、Java 自检 89/89。

---

## 实施进度（滚动更新，2026-11-17）

| 阶段 | 状态 | 说明 / 证据 |
|------|------|------------|
| 0 基础设施骨架 | ✅ 完成 | `app/core|db|middleware|cache` 全部就位；`uvicorn app.main:app --port 8080` 启动正常，`/health` 200，Swagger 可用；MySQL 连接日志 `mysql connection OK: 127.0.0.1:3307/neushare`；Redis 缺失时自动降级不报错。⚠️ `Dockerfile` / 独立 `docker-compose` 尚未编写（阶段 7 前补） |
| 1 公开基础接口 | ✅ 完成 | category / banner / form-card / auth(login,register) 实测返回与 Java 同结构 |
| 2 核心读接口 + 优化 | ✅ 完成 | resource(list/detail/hot/search/download) / post / comment(树) / post_comment / user / stats / banner / category / form_card 全部实测通过；`@cached` 装饰器就绪（Redis 未启动时透明降级为无缓存） |
| 3 需登录写接口 | ✅ 完成 | auth(info/password)、resource(create/update/delete/like)、comment、favorite、follow、post、post_comment、notification 全部实测；原子计数 `UPDATE ... SET x = x + 1` |
| 4 管理员接口 | ✅ 完成 | 19/19 个 `/api/admin/**` 端点落地：用户管理（list/status/delete 级联）、资源（pending/audit/delete）、评论（list/硬删除）、轮播图 CRUD+status、服务卡片 CRUD+status、statistics；401/403 契约与 Java 一致 |
| 5 高并发增强 | ⬜ 待做 | arq 计数器异步落库、通知异步化、slowapi 限流、定时校准、索引、连接池调优 |
| 6 测试与压测 | 🟡 部分完成 | ✅ M0 契约黄金基准：`tests/contract/`（147 用例、89 只读）、`tools/capture_golden.py`、`tools/diff_backends.py`。✅ M2 第一轮修复：F1–F8 全部落地，Python 只读 **89/89**、全量对拍 **147/147 一致**、Java 自检 89/89、既有探针 27/27 与 44/44。⬜ locust 压测对比报告 |
| 7 切换上线 | ⬜ 待做 | Nginx 灰度、`neushare-ai` 的 `JAVA_BACKEND_URL` 切换、4 服务 compose 编排 |
| 附加：AI 门禁（第十一章） | ✅ 已落地 | `neushare-ai/app/crypto.py`、`services/`(api_key/billing/pricing)、`sql/migration_V5_ai_billing.sql`、前端 `AiSettingsView.vue` |

**当前 API 覆盖**：Java 84 个端点 → Python 85 个（多出 `/health` 探活），**缺失 0 个**。
核对方式：解析 Java 各 `*Controller` 的 `@*Mapping` 与 FastAPI `/openapi.json` 做集合差。

### M0 契约黄金基准（2026-11-17 实测）

端点"存在"不等于契约"一致"。为此起两个实例做逐字段比对：

- Java 参考实现：JDK 17 + `target/neushare-backend-1.0.0.jar`，端口 **8081**，库 `neushare_golden_java`
- Python 实现：`uvicorn`，端口 **8082**，库 `neushare_golden_py`
- 两库从**同一份 dump** 恢复，147 个用例（84 端点全覆盖 + 63 负例/边界/写链路）**交错回放**，保证两边数据同步演进

结果：

| 回放目标 | 通过 | 失败 |
|---|---|---|
| Java 自己（验证工具可信） | **89 / 89** | 0 |
| Python 实现 | 37 | **52** |

差异归并为 8 类根因（详见 `neushare-backend-py/tests/contract/FINDINGS.md`）：

| 编号 | 级别 | 问题 | 影响用例 |
|---|---|---|---|
| F1 | P0 | 时间格式：Java `2026-11-14T13:01:48` vs Python `2026-11-14 13:01:48`（`date-format` 对 `LocalDateTime` 不生效） | 37 |
| F2 | P0 | 分页未规范化：`pageNum≤0`/`pageSize=-1` Python 直接 500；`pageSize` 无 100 上限 | 6 |
| F3 | P0 | 信封逃逸：405/未知路由返回 `{"detail": ...}`，前端读不到 `code` | 2 |
| F4 | P0 | 参数错误文案：`query.keyword: Field required` vs `缺少必填参数：keyword` | 7 |
| F5 | P1 | 404 业务码：Java `code=500` vs Python `code=404`（文案相同） | 3 |
| F6 | P1 | `comment.user` 缺 `children: null` 字段 | 1 |
| F7 | P1 | `favorite.list.fileExists`：Java `null` vs Python `true` | 1 |
| F8 | P2 | 统计接口并列名次顺序（Java `HashMap` 迭代序，自身不可复现） | 1 |

另外发现 Java 侧两处**契约不稳定**（不算 Python 缺陷，但说明"读源码推不出真实契约"）：
同一请求的校验消息拼接顺序每次不同；并列名次顺序取决于哈希桶。

进入阶段 5 之前，先把只读用例修到 **89/89**（修复顺序见 FINDINGS 第 6 节）。

**M2 第一轮修复结果（同日完成）**：F1–F8 全部落地，复测 Python 只读 **89/89**、全量交错对拍 **147/147 一致（0 差异）**、Java 自检 89/89、既有探针 27/27 与 44/44。两处有意保留的偏差（`pageSize=0` 复刻 Java 的 500、`stats` 并列名次顺序不敏感）已在代码注释与 FINDINGS 第 7 节记录。

**本机验证环境**（2026-11-17）：
- MySQL：`D:\temp_20261114_01\_mysql_demo`（端口 3307，库 `neushare`，115 资源 / 10 用户 / 20 帖子）
- Redis：未启动 → 缓存与限流相关能力走降级分支（阶段 5 需先起 Redis）
- 后端：`.venv`（Python 3.14.7）+ `uvicorn` 8080

---

## 目录

- [实施进度（滚动更新，2026-11-17）](#实施进度滚动更新2026-11-17)
- [一、目标与范围](#一目标与范围)
- [二、技术栈与架构](#二技术栈与架构)
- [三、API 契约保持策略（关键约束）](#三api-契约保持策略关键约束)
- [四、neushare-ai 对接清单（迁移必做）](#四neushare-ai-对接清单迁移必做)
- [五、高并发优化点的对应实现方案](#五高并发优化点的对应实现方案)
- [六、分阶段实施计划](#六分阶段实施计划)
  - [阶段 0：基础设施骨架](#阶段-0基础设施骨架15-天)
  - [阶段 1：公开基础接口](#阶段-1公开基础接口1-天--低风险快速验证)
  - [阶段 2：核心读接口 + 高并发优化](#阶段-2核心读接口--高并发优化3-天--性能验证重点)
  - [阶段 3：需登录写接口 + 事务与竞态](#阶段-3需登录写接口--事务与竞态3-天)
  - [阶段 4：管理员接口](#阶段-4管理员接口1-天)
  - [阶段 5：高并发增强](#阶段-5高并发增强2-天--拉开与-java-版的性能差距)
  - [阶段 6：测试与压测](#阶段-6测试与压测15-天)
  - [阶段 7：切换上线](#阶段-7切换上线05-天)
- [七、总时间估算](#七总时间估算单人)
- [八、风险与缓解](#八风险与缓解)
- [九、交付物清单](#九交付物清单)
- [十、下一步确认](#十下一步确认)
- [十一、AI 服务门禁功能（自带 Key + 充值余额，演示版）](#十一ai-服务门禁功能自带-key--充值余额演示版)

---

## 一、目标与范围

### 核心目标

用 FastAPI + 异步生态重写现有 Spring Boot 后端，**保持 API 契约 100% 不变**，使 Vue 前端和鸿蒙端零改动即可切换；同时在重写过程中落地高并发优化（缓存、计数器异步落库、竞态修复、SQL 聚合），解决代码审查发现的 8 个 P0/P1 性能问题。

### 范围

- ✅ 重写全部 14 个 Controller 的接口（约 50 个端点）
- ✅ 数据库保持不变（继续用现有 MySQL 8 + 现有表结构 + 现有数据）
- ✅ 引入 Redis 作为缓存与计数器层
- ✅ 引入异步任务队列处理通知 / 计数落库 / 校准
- ✅ 为 `neushare-ai` 增加『用户自带 API Key + 充值余额』门禁（演示版，详见第十一章），避免所有用户白嫖服务端 DeepSeek 额度
- ❌ 不修改前端、不修改鸿蒙端、不改数据库表结构
- ❌ 不改变任何接口的请求 / 响应字段（字段名、状态码、分页参数全部对齐）

### 非目标（本期不做）

- ~~AI / RAG 能力集成~~ —— **更正**：`neushare-ai`（LangChain + LangGraph + FastAPI AI 微服务）已在 `fix/phase2-audit` 分支落地，本期**不重写它**，但必须保证它能平滑对接新 Python 后端（详见第四章对接清单）
- 数据库迁移到其他引擎
- 微服务拆分

---

## 二、技术栈与架构

### 选型

| 层 | 选型 | 版本建议 | 对应 Java 原组件 |
|----|------|---------|----------------|
| Web 框架 | FastAPI | 0.115+ | Spring MVC |
| ASGI 服务器 | uvicorn（dev）/ gunicorn + uvicorn worker（prod） | 最新 | Tomcat |
| 异步 ORM | SQLAlchemy 2.0（async） | 2.0+ | MyBatis-Plus |
| MySQL 驱动 | asyncmy | 0.2+ | mysql-connector-j |
| 数据校验 | Pydantic v2 | 2.x | Jakarta Validation |
| 缓存 | Redis + redis-py（async） | 5.x | （原无） |
| 异步任务 | arq（基于 Redis，原生 async） | 最新 | （原 @Scheduled 同步） |
| JWT | PyJWT | 2.x | jjwt |
| 密码 | passlib[bcrypt] | 最新 | BCrypt |
| 限流 | slowapi | 最新 | （原无） |
| 跨域 | CORSMiddleware（FastAPI 内置） | — | CorsConfig |
| 测试 | pytest + pytest-asyncio + httpx | 最新 | spring-boot-starter-test |
| 部署 | Docker | — | Docker |

### 分层架构（对齐原 Java 三层 + 新增缓存层）

```
neushare-backend-py/
├── app/
│   ├── main.py                  # FastAPI 实例、中间件、路由注册、lifespan
│   ├── core/
│   │   ├── config.py            # 配置（环境变量注入，无硬编码密钥）
│   │   ├── security.py          # JWT 生成/解析（只解析一次）、密码 hash
│   │   ├── exceptions.py        # 全局异常处理器 + 业务异常
│   │   └── response.py          # 统一响应模型 Result / PageResult（字段对齐）
│   ├── db/
│   │   ├── session.py           # asyncmy 引擎 + 异步会话工厂
│   │   └── redis.py             # redis 异步客户端
│   ├── middleware/
│   │   └── auth.py              # JWT 依赖注入（替代拦截器，claims 只解析一次）
│   ├── models/                  # SQLAlchemy ORM 模型（对应 entity）
│   ├── schemas/                 # Pydantic 请求/响应模型（对应 dto/vo）
│   ├── api/v1/                  # 路由层（对应 controller），按模块分文件
│   │   ├── auth.py  resource.py  comment.py  favorite.py  follow.py
│   │   ├── post.py  post_comment.py  notification.py  user.py
│   │   ├── stats.py  banner.py  category.py  form_card.py  admin.py
│   ├── services/                # 业务逻辑层（对应 service/impl）
│   ├── cache/                   # 缓存装饰器与 key 管理
│   ├── tasks/                   # arq 异步任务（通知、计数落库、校准）
│   └── utils/
├── tests/                       # 契约测试 + 压测脚本
├── alembic/                     # （可选）数据库迁移，本期只读不改表
├── Dockerfile
├── docker-compose.yml           # Python 后端 + Redis，复用现有 MySQL
├── requirements.txt
└── .env.example
```

### 与现有 neushare-ai 服务的关系

`neushare-ai` 是已落地的独立 AI 微服务（FastAPI :8000，LangChain + LangGraph），**本期不重写它**，但新主后端上线后它必须能继续工作。两者关系：

```
                    ┌─────────────────────────────┐
                    │   前端 Vue / 鸿蒙端          │
                    └──────┬──────────────┬───────┘
                     /api/*│              │/ai/*
                           ▼              ▼
              ┌─────────────────┐  ┌──────────────────┐
              │ 主后端           │  │ neushare-ai      │
              │ (新Python :8080) │  │ (Python :8000)   │
              │  替换原 Java     │  │  保持不变         │
              └────────┬────────┘  └────────┬─────────┘
                       │                    │
        /api/resource/search◄─── HTTP 调用 ──┘（search_resources 工具）
                       │                    │
                       ▼                    ▼
              ┌──────────────────────────────────────┐
              │  MySQL（共享，不改表结构）            │
              │  Redis（主后端缓存+计数，ai可复用）    │
              └──────────────────────────────────────┘
```

- **端口**：`neushare-ai` 已占用 **8000**，新 Python 主后端必须用其他端口（建议沿用 Java 的 **8080**，这样前端/鸿蒙的 `BASE_URL` 完全不变）
- **数据**：`neushare-ai` 的 `resource_loader` 直连 MySQL 查 `resource` 表（不经 API），只要新后端不改表结构即不受影响
- **鉴权**：`neushare-ai` 用 PyJWT 验签，放行 HS256/384/512；新主后端用 PyJWT 签发，只要**共享同一个 `JWT_SECRET`** 且算法在 HS* 范围内，token 即互通

### 与现有 Java 后端的并存策略（灰度切换）

```
nginx / 前端 baseURL
       │
       ├── /ai/**  → 始终指向 neushare-ai（:8000），全周期不参与切换
       │
       ├── 灰度阶段：/api/stats/*  /api/resource/hot  → Python 主后端（验证）
       │            其余 /api/** → Java（原服务保留）
       │
       └── 全量阶段：全部 /api/** → Python 主后端，Java 下线
```

> ⚠️ 灰度路由配置必须显式把 `/ai/**` 排除在 `/api/**` 匹配之外（按前缀最长匹配优先），否则 AI 接口会被误切到主后端导致 404。

---

## 三、API 契约保持策略（关键约束）

前端与鸿蒙端零改动的前提是**响应字段完全对齐**。重写时必须遵守项目 CLAUDE.md 中的全部约定：

1. **统一响应**：`{ code, message, data }`，成功 code=200，失败 code=500/400/401/403
2. **分页**：请求 `pageNum` / `pageSize`，响应 `{ records, total, current, size, pages }`
3. **状态值**：资源 0/1/2，用户 0/1（整数，非字符串）
4. **VO 字段名**：`uploadNickname` / `avatarUrl` / `isFavorite` / `isFollowing` / `children` 等必须与原 Java 完全一致
5. **参数风格**：原后端大量用 `@RequestParam`，Python 侧对应 FastAPI 的 `Query()`；少数用 `@RequestBody` 的对应 `Body()` / Pydantic 模型。**不得擅自改成 JSON body**
6. **401/403 响应体**：与原拦截器手写的 JSON 字符串完全一致（`{"code":401,"message":"未登录或登录已过期","data":null}`）

### 验收手段

写一套**契约对比测试**：对同一组请求，分别打 Java 版和 Python 版，断言响应 JSON 结构与字段完全一致（值可因时间戳 / 自增 ID 略有差异，但字段集合与类型必须一致）。

---

## 四、neushare-ai 对接清单（迁移必做）

`neushare-ai`（`fix/phase2-audit` 分支已落地）是独立 AI 微服务，本期不重写，但新主后端切换后它必须继续可用。以下对接点按**必做 / 可选优化**分级，全部有代码依据。

### 4.1 必做对接点（不做则 AI 服务失联）

#### （1）端口规划：主后端避开 8000

- `neushare-ai` 已占用 **:8000**（[config.py:58](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/config.py#L58) `AI_SERVICE_PORT` 默认 8000）
- 本计划阶段 0 验收原写的是 `localhost:8000`，**必须改为 `localhost:8080`**（沿用 Java 原端口），否则与 neushare-ai 端口冲突，且前端 `BASE_URL` 需改动
- 影响文件：阶段 0 验收命令、`docker-compose.yml` 端口映射、前端 Vite 代理目标

#### （2）`search_resources` 工具的 HTTP 调用目标切换

- `neushare-ai` 的 `search_resources` 工具通过 HTTP 调主后端搜索接口（[tools.py:36-40](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/agent/tools.py#L36-L40)）：
  ```python
  httpx.get(f"{settings.java_backend_url}/api/resource/search", params={...})
  ```
- `java_backend_url` 默认 `http://localhost:8080`（[config.py:55](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/config.py#L55)）
- **切换动作**：Java 下线后，把 neushare-ai 的 `JAVA_BACKEND_URL` 环境变量指向新 Python 主后端。若新主后端也跑 8080，**默认值无需改动**；若端口不同，必须显式设置该环境变量
- **契约要求**：新主后端的 `/api/resource/search` 响应结构必须保持 `{ code, data: { list|records, total, ... } }`，且列表项字段含 `id/title/coverUrl|cover_url/categoryName|category_name/type/source`——因为 tools.py 对这些字段做了兼容读取（[tools.py:48-57](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/agent/tools.py#L48-L57)）。契约测试必须把 `/api/resource/search` 列为重点对齐项

#### （3）JWT 互通验证（灰度第一天就会踩）

- `neushare-ai` 用 PyJWT 验签，放行 `HS256/HS384/HS512`（[jwt.py:13](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/auth/jwt.py#L13)），从 `JWT_SECRET` 读密钥（有 dev fallback）
- 原 Java 用 jjwt 签发（按密钥长度自动选算法，56 字节选 HS384）
- 新主后端用 PyJWT 签发，**只要共享同一个 `JWT_SECRET` 环境变量，且签发算法在 HS* 范围内，token 即互通**
- **必做验证**（加入阶段 0 验收）：用新主后端登录拿到 token，直接请求 `neushare-ai` 的 `/ai/conversations`，断言返回 200 而非 401。灰度期用户在主后端登录、再访问 AI 接口，这条链路必须通
- **禁止**：新主后端使用 RS256 等非对称算法签发 JWT（neushare-ai 不支持），否则 AI 接口全部 401

#### （4）数据库共享：不改表结构即安全

- `neushare-ai` 的 `resource_loader` 直连 MySQL 查 `resource` 表（[resource_loader.py:7-12](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/ingestion/resource_loader.py#L7-L12)），不经 API
- 本期约定「不改数据库表结构」，所以 `resource_loader` 不受主后端语言切换影响
- **约束**：阶段 5 若加索引（`resource(status,create_time)` 等）不影响查询，安全；但**禁止改 `resource` 表字段名/类型**，否则 `resource_loader` 的 SQL 会失效
- `neushare-ai` 还读写 `ai_conversation` / `ai_message` 表（自建表，与主后端无关），保持不动

#### （5）`/ai` 路由在灰度中必须隔离

- 前端 Vite 把 `/ai` 代理到 neushare-ai（:8000），`/api` 代理到主后端（见 [ai.js:11-15](file:///e:/桌面/个人-求职升学/NeuShare/neushare-frontend/src/api/ai.js#L11-L15) `baseURL: '/ai'`）
- 灰度切换 Nginx 路由时，`/ai/**` 必须**始终指向 neushare-ai，不参与 `/api/**` 的切换**（已在第二章并存图标注）
- 按前缀最长匹配：`/ai/chat/stream` 必须命中 `/ai/` 规则，不能被 `/api/` 兜底规则截走

#### （6）docker-compose 服务编排

- 切换后系统同时运行 4 个服务：`mysql` + `redis` + `neushare-backend-py`（主后端 :8080）+ `neushare-ai`（:8000）
- `neushare-backend-py` 和 `neushare-ai` 共享同一 MySQL、同一 Redis、同一 `JWT_SECRET`
- `neushare-ai` 的 `JAVA_BACKEND_URL` 环境变量在 compose 里指向 `neushare-backend-py` 的服务名（如 `http://neushare-backend-py:8080`）

### 4.2 可选优化（不阻塞切换，但提升 AI 质量）

#### （7）索引与资源发布联动（增量入库）

- 现状：`neushare-ai` 启动时 `ensure_index()` 自动建一次，之后靠管理员手动调 `/ai/index/rebuild` 全量重建（[main.py:294-304](file:///e:/桌面/个人-求职升学/NeuShare/neushare-ai/app/main.py#L294-L304)）
- 问题：新资源审核通过后，FAISS 索引不会自动更新，AI 检索不到新资料
- 优化：主后端审核通过资源后，调用 neushare-ai 的 `/ai/index/rebuild`（带 admin token），或后续做增量入库接口。**本期可先保持手动重建，列入阶段 8 之后**

#### （8）AI 推荐资源质量受主后端搜索限制

- `search_resources` 调的是主后端 `/api/resource/search`（即 LIKE 全表扫那个搜索）
- 阶段 2 把搜索改 FULLTEXT 后，AI 推荐质量同步提升；若后续上语义搜索，AI 推荐会更准
- 这是迁移顺带带来的收益，无需额外改动

### 4.3 对接验收清单（加入阶段 0 与阶段 7）

```bash
# 阶段 0 必加验收：
# assert: 新主后端登录拿到的 token，能成功调用 neushare-ai 的 /ai/conversations（返回 200，非 401）
# assert: neushare-ai 的 /ai/health 正常，index_exists 为 true
# assert: 主后端与 neushare-ai 不抢端口（主后端 8080，neushare-ai 8000）

# 阶段 7 切换验收：
# assert: Java 下线后，在 AI 对话框问一个问题，search_resources 能从新主后端拿到结果（不报错、不 fallback 空）
# assert: /ai/** 路由全程指向 neushare-ai，灰度期间 AI 功能可用
# assert: docker compose up 后 4 个服务（mysql/redis/backend-py/neushare-ai）全部 healthy
```

---

## 五、高并发优化点的对应实现方案

将代码审查发现的 P0/P1 问题直接固化进重写中，不做"先重写再优化"：

| 原问题 | Python 实现方案 | 落地阶段 |
|--------|----------------|---------|
| JWT 每请求解析 4 次 | `auth.py` 依赖注入中 `jwt.decode` 一次，claims 存进 `request.state`，后续从 state 取 | 阶段 0 |
| 无缓存 | `cache/` 模块提供 `@cached(key, ttl)` 装饰器，给 hot/banner/category/stats 加缓存 | 阶段 2 + 5 |
| 统计全表加载到内存 | `StatsService` 改 SQL `GROUP BY` 聚合（SQLAlchemy `func.count` / `func.sum`），结果缓存 5min | 阶段 2 |
| 浏览量 / 点赞写热点 | Redis `INCR` 计数，arq 定时每 5min 批量 `UPDATE ... SET view_count = view_count + :delta` 落库 | 阶段 5 |
| 点赞竞态（先查后插） | 数据库唯一约束 + 捕获 `IntegrityError` 转业务异常；热点可加 Redis `SETNX` 占坑 | 阶段 3 |
| 评论树 O(n²) + 重复 | 抽取 `build_comment_tree()` 工具，用 `dict[parent_id]` 分组一次遍历 O(n)，resource 与 post 共用 | 阶段 2 |
| N+1 删除 | 批量 `DELETE ... WHERE id IN (...)`，用户级联用子查询 | 阶段 3 |
| 通知同步拖慢响应 | `NotificationService.send` 改为 arq 任务入队，接口立即返回 | 阶段 5 |
| 搜索 LIKE 全表扫 | 本期先补 MySQL FULLTEXT 索引 + SQL 改 `MATCH AGAINST`；预留 ES 接口 | 阶段 2 |
| 无连接池调优 | asyncmy 引擎配置 `pool_size` / `max_overflow`；uvicorn 多 worker | 阶段 0 |
| 配置硬编码密钥 | `config.py` 全部 `os.getenv`，`.env.example` 给占位符，仓库不存真值 | 阶段 0 |

---

## 六、分阶段实施计划

### 阶段 0：基础设施骨架（1.5 天）

**目标**：项目能跑起来，连上现有 MySQL 和 Redis，有一个返回对齐响应的示例接口。

**任务**：
1. 初始化项目结构、`requirements.txt`、`.env.example`、`.gitignore`（忽略 `__pycache__` / `.env` / `*.pyc`）
2. `config.py`：读取 `DB_URL` / `REDIS_URL` / `JWT_SECRET` / `JWT_EXPIRATION` / `UPLOAD_PATH` / `CORS_ORIGINS`，全部环境变量，无默认真值
3. `db/session.py`：SQLAlchemy async engine（asyncmy），会话依赖注入
4. `db/redis.py`：redis-py async 客户端
5. `core/response.py`：`Result[T]`、`PageResult[T]`，字段与原 Java 一致
6. `core/exceptions.py`：`BusinessException` + 全局异常处理器（含 401/403/DuplicateKey/文件超限等）
7. `core/security.py`：`create_token` / `decode_token`（只解码一次）、`hash_password` / `verify_password`
8. `middleware/auth.py`：`get_current_user` 依赖，从 `Authorization: Bearer` 取 token 解码一次，admin 校验
9. CORSMiddleware 配置（来源从环境变量读，默认 localhost）
10. Dockerfile + docker-compose（Python 服务 + 复用现有 MySQL，新增 Redis 服务）
11. 写一个 `/api/resource/hot` 示例接口（先返回空结构），验证响应模型对齐

**验收**：
```bash
# 机械验收命令
docker compose up -d redis
uvicorn app.main:app --reload --port 8080
# assert: GET http://localhost:8080/api/resource/hot 返回 {"code":200,"message":"操作成功","data":...}
# assert: GET http://localhost:8080/docs 能打开 Swagger
# assert: 主后端端口 8080 与 neushare-ai 的 8000 不冲突（见第四章 4.1(1)）
# assert: 新主后端签发的 token 可调用 neushare-ai 的 /ai/conversations（JWT 互通，见第四章 4.3）
# assert: .env 中无任何真实密钥，配置项齐全
```

---

### 阶段 1：公开基础接口（1 天）—— 低风险快速验证

**目标**：迁移不涉及登录态、无写操作的简单接口，跑通"连接池 → ORM → 响应"全链路。

**任务**（按文件）：
- `api/v1/category.py`：`GET /api/category/list`
- `api/v1/banner.py`：`GET /api/banner/list`（仅启用中）
- `api/v1/form_card.py`：`GET /api/form-card/current`
- `api/v1/auth.py`：`POST /api/auth/login`、`POST /api/auth/register`（含 BCrypt、JWT 签发、用户名唯一约束冲突处理）

**验收**：
```bash
# assert: 上述4个接口的响应 JSON 与 Java 版字段完全一致（契约对比测试通过）
# assert: 注册重复用户名返回 {"code":500,"message":"用户名已存在"} 而非 500 堆栈
# assert: 登录成功返回 {token, user}，user 字段与原 VO 对齐
```

---

### 阶段 2：核心读接口 + 高并发优化（3 天）—— 性能验证重点

**目标**：迁移所有公开读接口，**同时落地缓存、SQL 聚合、评论树优化**，用压测证明比 Java 版快。

**任务**：
- `resource.py`：`list`（含非管理员强制 status=1）、`detail/{id}`（浏览量先写 Redis 计数，不直接写库）、`hot`（加缓存）、`search`（改 FULLTEXT 或保留 LIKE 但加缓存）
- `post.py`：`list`、`detail/{id}`、`hot`
- `comment.py`：`list/{resourceId}` → 用新 `build_comment_tree()` O(n) 构建
- `post_comment.py`：`list/{postId}`
- `user.py`：`{id}`、`{id}/resources`
- `stats.py`：`overview` → SQL 聚合 + Redis 缓存 5min（**重点对比**：Java 版全表加载 vs Python 版聚合）
- `cache/` 模块：实现 `@cached` 装饰器，给 hot/banner/category/stats 加缓存
- 数据库：给 `resource` 加 `(status, create_time)` 联合索引、`post` 加 `is_recommended` 索引（**这一步改表，需单独审批**，或先用原索引跑，索引优化放阶段 5）

**验收**：
```bash
# 契约测试：全部读接口响应与 Java 版字段一致
# 性能对比（locust 或 wrk）：
#   assert: /api/stats/overview 在 1万资源数据量下，Python版 p95 < Java版 p95
#   assert: /api/resource/hot 缓存命中后 QPS 显著高于 Java 版
#   assert: 评论树在 1000 条评论时构建耗时 < 50ms
```

---

### 阶段 3：需登录写接口 + 事务与竞态（3 天）

**目标**：迁移所有需鉴权的写操作，正确处理事务、唯一约束冲突、计数器原子更新。

**任务**：
- `auth.py`：`GET/PUT /api/auth/info`、`PUT /api/auth/password`
- `resource.py`：`create`（含文件上传，对齐原 FormData）、`update`、`delete/{id}`（所有者校验 + 级联批量删除）、`user`、`like/{id}`（POST/DELETE/check）
- `comment.py`：`add`、`delete/{id}`、`user`
- `favorite.py`：`add` / `remove` / `check` / `list`
- `follow.py`：`add` / `remove` / `check` / `following` / `followers`（含关注者 / 被关注者计数原子更新）
- `post.py`：`create` / `update` / `delete/{id}` / `like` / `favorite` / `check` / `user` / `recommend/{id}`
- `post_comment.py`：`add` / `delete/{id}`（含帖子 comment_count 原子递减）
- `notification.py`：`list` / `unread` / `read/{id}` / `read-all` / `delete/{id}`
- 全部写接口加事务（SQLAlchemy async 事务），捕获 `IntegrityError` 转业务异常
- 计数器用 `UPDATE ... SET x = x + 1 WHERE ...` 原子 SQL，与原 Java 一致

**验收**：
```bash
# assert: 并发点赞 100 次同一资源，最终 like_count 精确 = 成功点赞数（无超赞、无 500）
# assert: 删除资源后，其评论/收藏/点赞记录全部清除（批量删除生效）
# assert: 非所有者删除/更新返回 403 业务异常
# assert: 全部写接口契约与 Java 版一致
```

---

### 阶段 4：管理员接口（1 天）

**目标**：迁移 `/api/admin/**` 全部接口，admin 角色校验。

**任务**：
- `admin.py`：statistics、user/list、user/status、user/delete、resource/pending、resource/audit、resource/delete、comment/list、comment/delete、banner 的 CRUD+status、form_card 的 CRUD+status
- admin 校验在 `get_current_admin` 依赖中统一处理

**验收**：
```bash
# assert: 非 admin 访问 /api/admin/* 返回 403
# assert: 审核通过/驳回后资源状态正确，驳回原因写入
# assert: 契约一致
```

---

### 阶段 5：高并发增强（2 天）—— 拉开与 Java 版的性能差距

**目标**：落地缓存层、异步任务、限流，解决剩余 P1 问题。

**任务**：
1. **计数器异步落库**：arq 任务每 5 分钟将 Redis 中的浏览量 / 点赞量增量批量写回 MySQL，详情接口不再直接写库
2. **通知异步化**：`NotificationService.send` 改为 arq 入队，点赞 / 评论 / 关注接口立即返回
3. **限流**：slowapi 给公开接口加令牌桶（如 `/api/auth/login` 防暴力破解、`/api/resource/search` 防刷）
4. **定时校准任务**：arq cron 每日凌晨 3 点执行（替代原 `CounterCalibrationTask`），改批量 SQL 而非 N+1
5. **连接池 / worker 调优**：压测确定最优 `pool_size`、`gunicorn worker` 数
6. **数据库索引补全**（需审批）：`resource(status,create_time)`、`resource(status,view_count)`、`post is_recommended`、FULLTEXT 索引

**验收**：
```bash
# assert: 点赞接口响应时间 < 50ms（通知异步后）
# assert: 详情接口浏览量不直接写库，5 分钟内落库，数据最终一致
# assert: 登录接口连续失败 5 次后被限流（返回 429）
# assert: 全量压测下 Python 版 QPS ≥ Java 版，且 p95 延迟更低
```

---

### 阶段 6：测试与压测（1.5 天）

**目标**：全量契约测试通过 + 性能达标 + 无回归。

**任务**：
1. **契约对比测试**：对全部 ~50 个端点，同请求打 Java 与 Python，断言字段集合一致（写接口用事务回滚隔离）
2. **并发竞态测试**：点赞 / 收藏 / 关注的并发场景，验证无超赞无 500
3. **压测**：locust 脚本模拟 500 并发，对比 Java 版 QPS / p95 / 错误率
4. **边界测试**：pageSize=0、超大 pageSize、空 keyword、超长内容等
5. 出一份压测对比报告（作为简历 / 项目文档的性能证据）

**验收**：
```bash
# assert: 契约测试通过率 100%（字段级一致）
# assert: 并发竞态测试无超赞、无 500
# assert: 压测报告：Python 版 QPS ≥ Java 版，p95 不劣化
```

---

### 阶段 7：切换上线（0.5 天）

**目标**：灰度 → 全量切换，下线 Java。

**任务**：
1. Nginx 配置灰度：先把 `/api/stats/*`、`/api/resource/hot`、`/api/banner/list` 切到 Python，观察 24h
2. 无异常后全量切 `/api/**` 到 Python
3. 前端 `baseURL`、鸿蒙 `BASE_URL` 指向不变（同一域名，后端替换）
4. **neushare-ai 对接切换**：把 `neushare-ai` 的 `JAVA_BACKEND_URL` 环境变量指向新 Python 主后端（compose 服务名）；验证 AI 对话的 `search_resources` 能从新后端拿到结果（见第四章 4.3 验收）
5. **`/ai/**` 路由隔离验证**：确认灰度/全量期间 `/ai/**` 始终指向 neushare-ai（:8000），不被 `/api/**` 规则截走
6. Java 服务保留 7 天回滚窗口后下线

**验收**：
```bash
# assert: 灰度期间前端/鸿蒙端功能无异常，无前端改动
# assert: 全量切换后全部接口可用
```

---

## 七、总时间估算（单人）

| 阶段 | 内容 | 工时 |
|------|------|------|
| 0 | 基础设施骨架 | 1.5 天 |
| 1 | 公开基础接口 | 1 天 |
| 2 | 核心读接口 + 缓存 / SQL 优化 | 3 天 |
| 3 | 需登录写接口 + 事务竞态 | 3 天 |
| 4 | 管理员接口 | 1 天 |
| 5 | 高并发增强 | 2 天 |
| 6 | 测试与压测 | 1.5 天 |
| 7 | 切换上线 | 0.5 天 |
| 附加 | AI 服务门禁（neushare-ai 改造，第十一章） | 4.5 天 |
| **合计** | | **18 天**（约 3.5 周全职；兼职每晚 2h 约 7 周） |

> 阶段 2 完成（约第 5.5 天）即可有可演示的成果：核心读接口跑通 + 性能对比数据，可提前用于简历 / 面试。

---

## 八、风险与缓解

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| 某个接口响应字段与 Java 版不一致，前端报错 | 切换失败 | 阶段 6 契约对比测试全量覆盖；灰度阶段只切读接口 |
| SQLAlchemy async 学习曲线 | 进度延误 | 先做阶段 0/1 熟悉，复杂查询保留 SQL 文本（`text()`）渐进迁移 |
| Redis 引入后数据一致性问题（计数丢失） | 数据不准 | 计数器落库有校准任务兜底；Redis 持久化 RDB |
| Windows 环境 asyncmy / redis 安装问题 | 环境阻塞 | 用 Docker 运行 Python 服务，避免本机依赖；requirements 不锁触发源码编译的版本 |
| 改数据库索引需要 DBA 权限 | 阶段 5 卡住 | 索引优化列为可选项，先用原索引跑通，性能达标可不改 |
| arq 与 uvicorn 共享 Redis，worker 未启动导致通知丢失 | 功能缺失 | docker-compose 保证 arq worker 常驻；通知发送失败有日志告警 |
| neushare-ai 与新主后端对接失败（JWT 不互通 / search 工具失联 / 端口冲突） | AI 功能整体不可用 | 阶段 0 先验证 JWT 互通（第四章 4.3）；主后端端口固定 8080 避开 8000；契约测试覆盖 `/api/resource/search`；灰度期 `/ai/**` 路由隔离 |

---

## 九、交付物清单

1. `neushare-backend-py/` 完整可运行工程
2. API 契约对比测试报告（字段级一致性）
3. 压测对比报告（Python vs Java：QPS / p95 / 错误率）—— **简历亮点**
4. 高并发优化说明文档（缓存策略、计数器方案、竞态处理）
5. 部署文档（docker-compose、环境变量清单、灰度切换步骤）
6. 原 Java 后端保留 7 天回滚，之后归档（不删除，留作对比）
7. **neushare-ai 对接验证报告**：JWT 互通、`search_resources` 工具链路、`/ai` 路由隔离、4 服务 compose 编排的端到端验证记录

---

## 十、下一步确认

本计划已冻结交付边界为**文档**，未改动任何代码。请确认：

1. **计划是否认可**？有无需要调整的阶段顺序、范围或时间？
2. 阶段 5 的**数据库索引变更**是否授权（会改表结构，原 Java 服务也会受影响——但加索引是正向的）？
3. 确认后，从**阶段 0** 开始实施，还是先做一个**最小验证**（只搭骨架 + 迁移 `/api/stats/overview` 一个接口做性能对比）？

> 确认方向后再动手编码，避免范围漂移。

---

## 十一、AI 服务门禁功能（自带 Key + 充值余额，演示版）

> 本章为附加模块，改造对象是已落地的 `neushare-ai` AI 微服务（非主后端迁移），与阶段 0~7 并行，可独立实施。

### 11.1 背景与目标

当前 `neushare-ai` 的 `get_llm()` 固定使用服务端 `.env` 里的一个 `DEEPSEEK_API_KEY`，所有登录用户共用；聊天接口只有 JWT 鉴权 + 每分钟 10 次限流，无任何收费 / 自带 key 门禁——谁登录都能白嫖服务所有者的 DeepSeek 余额。

本章落地「用户自带 Key + 充值余额」双通道门禁，使服务不再被无限白嫖，同时给用户两种使用方式。

### 11.2 门禁逻辑

```
用户发起 AI 聊天
     │
     ├─ 用户已配置自己的 API Key？ ──是──→ 走用户自己的 key（免费，不扣费）
     │
     └─ 否
          │
          ├─ 用户余额 > 0？ ──是──→ 走服务端 key，调用结束按 token 消耗扣余额
          │
          └─ 否 ──→ 拒绝调用（返回 code=402），提示"请配置 API Key 或充值余额"
```

### 11.3 数据库表设计（新增 4 张表，建在现有 neushare 库，前缀 ai_）

| 表 | 关键字段 | 说明 |
|----|---------|------|
| `ai_user_api_key` | id, user_id, provider, api_key(加密), base_url, model, is_active, created_at | 用户自带的 key，AES 加密存储，唯一索引 (user_id, provider) |
| `ai_user_balance` | user_id(PK), balance(分), total_recharged, total_consumed, updated_at | 用户余额，单位：分 |
| `ai_recharge_record` | id, user_id, amount(分), created_at | 充值记录（演示版留痕） |
| `ai_usage_log` | id, user_id, conversation_id, source(server/user_key), model, prompt_tokens, completion_tokens, cost(分), created_at | 每次调用的消耗记录 |

### 11.4 后端改动（neushare-ai）

**新增**：
1. `app/crypto.py` —— AES 加解密（密钥来自环境变量 `ENCRYPT_KEY`）
2. `app/services/api_key.py` —— 用户 key 的增删查、加密、测试连接（调一次最小请求验证有效性）
3. `app/services/billing.py` —— 余额查询、加款、扣费、用量记录
4. `app/services/pricing.py` —— 计费规则（deepseek-v4-flash：输入缓存未命中 ¥1/百万、输出 ¥2/百万 token；缓存命中 ¥0.02/百万，演示固定价）

**修改**：
1. `config.py` —— 加 `ENCRYPT_KEY` 配置项
2. `app/agent/llm.py` —— `get_llm(api_key=None, base_url=None, model=None)` 支持传入自定义 key
3. `app/agent/stream.py` —— 流式结束后返回本次 token 用量（prompt/completion），供扣费
4. `app/main.py` —— `/ai/chat` 与 `/ai/chat/stream` 入口加门禁（11.2 逻辑）；服务端 key 调用结束后按实际 token 扣费、写 usage_log

### 11.5 新增接口

| 方法 | 路径 | 功能 |
|------|------|------|
| GET | `/ai/api-key` | 查用户已配置的 key（不返回明文，只返回是否已配置 / provider / model） |
| POST | `/ai/api-key` | 保存 key（AES 加密入库），body: `{provider, api_key, base_url, model}` |
| DELETE | `/ai/api-key` | 删除已配置的 key |
| POST | `/ai/api-key/test` | 测试 key 是否有效（调一次最小请求，返回成功 / 失败 + 错误信息） |
| GET | `/ai/balance` | 查当前用户余额（元，保留 2 位小数） |
| POST | `/ai/recharge` | 充值（演示版自动加款），body: `{amount}` → 直接加余额 + 写记录 |
| GET | `/ai/usage` | 查当前用户用量记录（分页） |

**门禁拒绝响应**：`{"code": 402, "message": "请先配置 API Key 或充值余额后使用 AI 功能", "data": null}`，前端据此引导跳转设置页。

### 11.6 前端改动（neushare-frontend）

1. **新增 AI 设置页**（`views/AiSettingsView.vue`）：
   - 区域 1：我的 API Key —— 输入框 + 测试连接按钮 + 保存 / 删除，显示当前配置状态
   - 区域 2：我的余额 —— 显示余额 + 充值入口 + 用量记录列表
   - 区域 3：充值 —— 选金额（10 / 50 / 100 / 自定义）→ 展示收款码图片 → 点"已付款，自动到账" → 刷新余额
2. **AI 聊天页改造**（`AiAssistantView.vue` + `AiFloatingWindow.vue`）：收到 402 时弹出引导"去配置 Key 或充值"，跳转设置页；顶栏显示当前余额
3. **路由**：加 `/ai/settings` 路由，登录可访问
4. `api/ai.js`：加上述新接口的封装

### 11.7 扣费规则（演示用）

- 流式回答结束后，从 LLM 响应取 `usage.prompt_tokens` / `usage.completion_tokens`
- 费用（分）= `(prompt_tokens/1e6 * 1 + completion_tokens/1e6 * 2) * 100`，向上取整
- 余额不足时：本次照常回答（扣到 0 或允许小额欠费），下次调用前门禁挡住
- 用户自带 key 的调用：`source = user_key`，`cost = 0`，只记录不扣费

### 11.8 充值流程（演示版，不校验真实支付）

```
用户选金额 → 前端展示服务所有者的个人收款码图片
      ↓
用户扫码（演示时扫不扫均可）
      ↓
用户点"已付款，自动到账"
      ↓
前端调 POST /ai/recharge {amount}
      ↓
后端直接给用户加余额 + 写充值记录（不校验真实到账）
      ↓
前端刷新显示余额到账
```

> 不接商户号、不接真实支付 SDK、不需要营业执照；用个人收款码 + 演示版自动加款即可。如后续要真实收款，可叠加第三方个人支付聚合（有回调）或申请商户号，不在本期范围。

### 11.9 时间估算

| 模块 | 工时 |
|------|------|
| 数据库表 + 加密工具 + 配置 | 0.5 天 |
| 后端：key 管理 + 余额 + 充值 + 用量接口 | 1 天 |
| 后端：聊天门禁 + 扣费逻辑 | 1 天 |
| 前端：AI 设置页 + 充值流程 | 1 天 |
| 前端：聊天页引导改造 + 联调 | 0.5 天 |
| 测试 + 修 bug | 0.5 天 |
| **合计** | **4.5 天** |

### 11.10 验收标准

```bash
# assert: 未配置 key 且余额为 0 的用户调用 /ai/chat 返回 code=402
# assert: 配置了有效 key 的用户调用成功，usage_log 中 source=user_key、cost=0
# assert: 余额充足的用户调用成功，调用后余额按 token 消耗正确扣减
# assert: POST /ai/recharge 后 GET /ai/balance 余额正确增加，有充值记录
# assert: 保存的 key 在数据库中为密文，GET /ai/api-key 不返回明文
# assert: 测试无效 key 时 /ai/api-key/test 返回明确错误信息
```

### 11.11 待确认项

1. **收款码图片**：需提供一张个人收款码图片（微信 / 支付宝）放到前端 `public/` 目录；暂无可先放占位图，演示前替换
2. **计费价格**：演示按 deepseek-v4-flash 官方价（输入缓存未命中 ¥1/百万、输出 ¥2/百万 token；缓存命中 ¥0.02/百万。注意该模型默认开启思考模式，思考过程会计入输出 token，实际消耗会偏高）计算，确认是否采用
