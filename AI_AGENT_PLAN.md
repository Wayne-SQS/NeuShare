# NeuShare AI 智能体实施计划（带勾选跟踪）

> 本文件是唯一执行基线。每完成一项就把 `- [ ]` 改成 `- [x]`，防止上下文窗口重置后遗漏/错乱。
> 创建时间：2026-11-14
> 项目：NeuShare（东北大学校园学习资料分享平台）

## 决策基线（已与用户确认）
- LLM：DeepSeek（deepseek-chat，OpenAI 兼容接口 `https://api.deepseek.com`）
- Embedding：默认本地中文模型 `BAAI/bge-small-zh-v1.5`（sentence-transformers，无需额外 key）；可配置切换为 API 版
- 端范围：首版仅 Web 端（Vue3），可浏览器完整跑通演示
- 知识库：18 份本地 Markdown 笔记全文 + 96 条已发布资源元数据（标题/描述/标签/分类）
- 顺带优化：Web 端显示资源封面（P1）、资源详情页加 AI 入口（P1）、Web 端补齐社区/考研指南（P2）
- 架构：新建 `neushare-ai/` Python 服务（FastAPI :8000），共享 Java 的 `${JWT_SECRET}` 验签，对话历史直写 MySQL，Vite 代理 `/ai` → 8000

## 语料现状（已核实）
- `neushare-backend/uploads/` 下 18 份 `.md` 笔记 + 1 份 `.c` + 1 份 `.sql`（可全文索引）
- MySQL 3307 `neushare.resource`：114 条已发布，其中 local-file 18 条、external 96 条；类型 document 22 / video 56 / tutorial 36 / other 1
- 演示库：端口 3307，root 密码由 .env 注入（明文密钥已从公开仓库清除）

---

## 阶段 0：准备与基建
- [x] 0.1 新建 `neushare-ai/` 目录结构（app/、vectorstore/、tests/、requirements.txt、.env.example）—— README 留到阶段 8 补全
- [x] 0.2 确认 Python 版本（3.10+），创建虚拟环境，安装依赖（锁定版本，避免 LangChain API 断代）—— Python 3.11.4，复用全局 torch 2.14+cu126（CUDA 可用），依赖已装并验证导入
- [ ] 0.3 拿到 DeepSeek API Key（用户提供）→ 写入 `neushare-ai/.env`（不入库，.gitignore 排除）
- [x] 0.4 新建 MySQL 表 `ai_conversation`、`ai_message`：追加到 init.sql + 演示库 3307 执行 —— 已建表并验证，另存 migrate_ai_agent.sql
- [x] 0.5 验证 Java 后端 `/api/resource/search` 可供 Python 调用（需先启动 Java）—— 已实测，Java 8080 在线，Python httpx 调用返回 HTTP 200

## 阶段 1：Python AI 服务 — RAG 索引层
- [x] 1.1 配置模块 `app/config.py`：读取 DEEPSEEK_API_KEY / DEEPSEEK_BASE_URL / JWT_SECRET / MYSQL 连接 / FAISS 路径 / embedding 模型名 —— 已完成，密码含 @ 已做 URL 编码
- [x] 1.2 文档加载器 `app/ingestion/loader.py`：扫描 uploads 下 `.md`/`.c`/`.sql`，用 LangChain loader 加载，metadata 带 source_type=note / file_name —— 加载到 20 份笔记
- [x] 1.3 资源元数据加载器 `app/ingestion/resource_loader.py`：从 MySQL 读已发布资源，组装成 Document（page_content=标题+描述+标签，metadata 带 resource_id/title/category/cover_url/source）—— 加载到 114 条
- [x] 1.4 文本切分 `app/ingestion/splitter.py`：MarkdownHeaderTextSplitter + RecursiveCharacterTextSplitter，chunk≈500 / overlap≈50 —— 共 535 chunk
- [x] 1.5 向量化与 FAISS 存储 `app/ingestion/vectorstore.py`：embedding → FAISS，本地持久化到 vectorstore/，支持增量/全量重建 —— bge-small-zh 本地模型（GPU），FAISS AVX2
- [x] 1.6 构建入口 `app/ingestion/builder.py`：`build_index()` 全量构建；启动时若向量库不存在则自动构建 —— 已实测构建成功，检索质量验证通过
- [x] 1.7 重建接口：`POST /ai/index/rebuild`（管理员校验）—— main.py 已实现，校验 role==admin

## 阶段 2：LangChain Agent 编排
- [x] 2.1 LLM 初始化 `app/agent/llm.py`：ChatOpenAI 指向 DeepSeek（model=deepseek-chat，temperature≈0.3），支持工具调用 —— 代码完成，实测构造需 api_key（待用户提供 key 后联调）
- [x] 2.2 工具① `retrieve_notes(query, k=4)`：FAISS 检索笔记片段，返回带出处的内容 —— 已实测，命中正确笔记
- [x] 2.3 工具② `search_resources(keyword, limit=5)`：HTTP 调 Java `/api/resource/search`，返回相关资源列表 —— 已实测，Java 8080 在线，HTTP 200 通；含 FAISS 降级
- [x] 2.4 Agent 编排 `app/agent/graph.py`：LangGraph create_react_agent，系统提示词（你是 NeuShare 学习助手，先检索知识库再回答，引用来源，推荐相关资源）—— 代码完成，待 key 验证
- [x] 2.5 引用溯源：结构化输出 sources（title/resource_id/file_name/snippet/url）—— stream.py 已实现解析 ToolMessage
- [x] 2.6 流式 `app/agent/stream.py`：`astream` 推 token，区分 content / sources / resources 三类事件 —— 代码完成，待 key 验证

## 阶段 3：鉴权 / 历史 / 限流 / 接口
- [x] 3.1 JWT 验签 `app/auth/jwt.py`：共享 `${JWT_SECRET}`（HS256），解析 Authorization 头提取 userId/username/role，与 Java 互通 —— claim 结构已对齐 Java JwtUtil（sub=userId）
- [x] 3.2 对话历史 ORM `app/db/models.py` + `app/db/session.py`：SQLAlchemy 连 MySQL 3307 —— 密码含 @ 已 URL 编码，连接正常
- [x] 3.3 会话接口：`GET /ai/conversations`、`POST /ai/conversations`、`GET /ai/conversations/{id}/messages`、`DELETE /ai/conversations/{id}` —— main.py 已实现
- [x] 3.4 聊天接口：`POST /ai/chat`（非流式）、`POST /ai/chat/stream`（SSE 流式，带 conversation_id + 可选 resource_id 上下文）—— main.py 已实现
- [x] 3.5 限流 `app/middleware/ratelimit.py`：按 userId 滑动窗口 10 次/分钟（内存计数，首版）—— 已实现
- [x] 3.6 CORS：放行 localhost:3000；健康检查 `GET /ai/health` —— 已实现

## 阶段 4：Web 端前端 — AI 助手页
- [x] 4.1 `vite.config.js` 增加 `/ai` 代理 → `http://localhost:8000`（后端路由即 /ai/*，无需 rewrite）
- [x] 4.2 API 模块 `src/api/ai.js`：chatStream（fetch + ReadableStream 手动解析 SSE，含 429/错误兜底）、会话 CRUD 独立 axios 实例
- [x] 4.3 路由 `/ai`（meta.requiresAuth，懒加载）+ Header nav-menu 与 drawer-nav 两处「AI助手」入口（登录后可见）
- [x] 4.4 `AiAssistantView.vue` 聊天页骨架（左侧会话列表含新建/切换/删除 + 右侧消息流 + 底部输入框；移动端侧栏滑出）
- [x] 4.5 流式渲染：token 增量拼接即打字机，处理 token/sources/resources/error/done 事件，流式中禁用输入
- [x] 4.6 引用来源卡片：展示标题 + 片段（2 行截断），有 resource_id 可点击跳转 `/resource/:id`
- [x] 4.7 推荐资源卡片：封面（加载失败兜底）/标题/分类/来源，点击跳转详情
- [x] 4.8 空态欢迎语 + 4 个示例问题（点击即问）；处理 `?resourceId=` query 上下文芯片
- [x] 4.9 样式：复用 global.css 全部 CSS 变量（靛蓝主色/成功绿/间距/圆角/阴影），风格统一；`vite build` 通过

## 阶段 5：P1 优化项
- [x] 5.1 Web 端 `ResourceCard.vue` 渲染 `coverUrl`（含加载失败兜底），资源广场/热门/详情统一 — 16:9 封面区，coverUrl 为空/加载失败显示渐变兜底
- [x] 5.2 资源详情页 `ResourceDetail.vue` 加「问 AI」按钮 → 跳转 `/ai?resourceId=:id`，未登录时守卫自动带回 redirect

## 阶段 6：P2 Web 端补齐社区 / 考研指南
- [x] 6.1 API 模块 `src/api/post.js`：消费现有后端 `/api/post/*` 接口（tags/imageUrls 为 JSON 字符串，前端 parse）
- [x] 6.2 社区列表页 `CommunityView.vue`：分页 + 标签筛选 + 关键词 + 排序（/api/post/list）
- [x] 6.3 帖子详情页 `PostDetailView.vue`：全文 + 图片 + 递归评论树（CommentItem 组件）+ 评论表单（/api/post/detail + /api/post/comment/*）
- [x] 6.4 发帖页 `CreatePostView.vue`（需登录，tags 自动 JSON.stringify）
- [x] 6.5 考研指南页 `PostgradGuideView.vue`（静态内容：常识/科目/时间线/规划/NEU 贴士/资料入口）
- [x] 6.6 路由（/community、/post/:id、/post/create、/postgrad-guide）+ Header nav/drawer 两处入口

## 已完成的无 key 验证证据（2026-11-14）
- Python 服务启动正常：`GET /ai/health` → `{"status":"ok","index_exists":true}`，日志确认 bge-small-zh 加载 + FAISS(AVX2) 索引预热成功
- Agent 流式错误契约验证：无 key 时 `stream_answer()` 产出 `error → done` 事件，与前端 `chatStream` 解析协议一致
- 前端 `vite build` 通过（exit 0）：AiAssistantView / CommunityView / PostDetailView / CreatePostView / PostgradGuideView / ResourceCard(封面) 均正常产出独立 chunk
- 唯一剩余阻塞：**DeepSeek API Key**（`.env` 第 2 行 `DEEPSEEK_API_KEY=` 仍为空），以及四服务联调（MySQL 3307 / Java 需带 JWT_SECRET 启动）

## 阶段 7：联调与端到端验证
- [ ] 7.1 启动顺序：MySQL(3307) → Python AI(8000) → Java(8080) → Vite(3000)
- [ ] 7.2 索引构建成功：FAISS 含 18 份笔记 + 114 条资源元数据
- [ ] 7.3 端到端实测：提问 → 流式回答 → 引用来源正确 → 推荐资源可点击跳转
- [ ] 7.4 对话历史持久化，刷新页面不丢失，可切换/删除会话
- [ ] 7.5 限流生效（超限返回提示）
- [ ] 7.6 P1：封面渲染正常无裂图；详情页 AI 入口跳转并携带 resourceId 上下文
- [ ] 7.7 P2：社区列表/详情/发帖/考研指南页可访问
- [ ] 7.8 浏览器控制台无报错

## 阶段 8：交付收尾
- [ ] 8.1 启动说明：一键启动脚本或文档（Java + Python + 前端）
- [ ] 8.2 `CLAUDE.md` / `README.md` 增补 AI 服务说明与 API 清单
- [ ] 8.3 `.env.example` 模板（占位符，不含真实 key）
- [ ] 8.4 记录失败尝试与实验证据（按惯例保留）

## 风险与注意
- DeepSeek 无 embedding API → 默认本地 bge-small-zh（首次需下载模型约 100MB，需 torch）
- LangChain 1.x 移除旧 agents API → 一律用 LangGraph create_react_agent 路线，依赖锁版本
- 不得在输出/文件中回显真实 API Key；`.env` 必须 gitignore
- Windows pip 若遇 GBK 解码 requirements.txt → 改为纯 ASCII
- Java 后端未启动时 Python 的 search_resources 工具需优雅降级（返回空，不阻断问答）
