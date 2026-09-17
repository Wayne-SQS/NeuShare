# NeuShare 智能体 + RAG 设计方案

> 目标：在现有 Vue3 + Spring Boot 3.3.7 + HarmonyOS 三端架构上，接入一个「能检索、能调工具、能流式回答」的校园学业助手，同时把 RAG 检索链路设计清楚。
> 版本事实核对时间：2026-09（Spring AI 2.0 GA 于 2026-06 发布，需要 Boot 4，本项目不可用）

---

## 0. 结论先行：技术选型

| 层 | 选型 | 理由 |
|----|------|------|
| 主框架 | **Spring AI 1.1.x**（BOM 统一管理） | 与 Spring Boot 生态同源，starter 自动装配；2.0 要求 Boot 4，本项目是 3.3.7 用不了 |
| 增强框架 | **LangChain4j 1.13.0** | 补齐 Spring AI 1.x 缺的高级 RAG 能力：查询改写 / 混合检索 / RRF 融合 / 重排序 |
| 编排框架 | **LangGraph4j 1.8.18** | 多智能体状态图编排，2026-06 稳定版，Java 17+，同时兼容 LangChain4j 与 Spring AI |
| Chat 模型 | **DeepSeek `deepseek-chat`**（OpenAI 兼容） | 中文强、便宜、你熟；用 openai starter 改 `base-url` 即可 |
| Embedding | **阿里百炼 `text-embedding-v4`，1024 维** | 中文效果好，¥0.5/百万 token，支持套娃截断（2048→1024→256） |
| 重排序 | **bge-reranker-v2-m3**（硅基流动 / 本地 TEI） | 给 LangChain4j 的 `ReRankingContentAggregator` 提供 ScoringModel |
| 向量库 | **Qdrant（Windows 单 exe，81MB）** | Rust 单二进制，解压就跑，不用装 Docker；Spring AI 官方 starter 走 gRPC 6334 |
| 文档解析 | **Apache Tika** / LangChain4j 文档加载器 | PDF / Word / PPT / Markdown 一把梭 |
| 流式输出 | **SSE**（`Flux<ServerSentEvent>` / LangChain4j `TokenStream`） | Web 用 EventSource，鸿蒙端 http 流式分块解析 |
| 会话记忆 | **MySQL 持久化 ChatMemory** | Spring AI `JdbcChatMemoryRepository` / LangChain4j 自定义 ChatMemoryStore |

> **双引擎不是二选一，而是分层配合**：Spring AI 负责「跑通主链路 + Boot 原生集成」，LangChain4j 负责「把检索质量做上去」，LangGraph4j 负责「多步任务编排」。分工依据与集成方式见第 11 节。

### 关于 Spring Boot 版本

Spring AI 1.1.x 官方基线是 **Spring Boot 3.5.x**，你当前是 3.3.7。两个选择：

- **建议：升到 3.5.x**（JDK 17 仍然支持，改 parent 版本号 + `mvn` 回归一遍即可，MyBatis-Plus 3.5.13 / jjwt 0.13 都兼容）
- 不升：用 **Spring AI 1.0.5 LTS**（更保守，API 与 1.1 基本一致，但 RAG/工具能力略少）

> 别用 Spring AI 2.0.x：它要求 Spring Boot 4 + Spring Framework 7，等于整个项目大版本升级，考研期间不值得。

---

## 1. 最关键的先想清楚：RAG 的语料从哪来

这是 NeuShare 做 RAG 的**真正难点**，也是很多人上来就写代码、写完发现没东西可检索的原因。

看一眼 `resource` 表：

```sql
title / description / tags / category_id / content_url / status
```

`resource` 同时支持两种形态：本地上传文件（`FileUploadUtil` 存到 `uploads/`，映射为 `/files/**`）和外部链接（`content_url` 直接存 URL）。但现状是：

- 种子数据 133 条里绝大多数是**外链**（37 门 B 站网课、29 个 GitHub 项目、119 条课程链接），本地文件很少
- 已经上传的本地文件**从未被内容解析**，只是存了个 URL，检索时只能匹配标题和描述

所以「上传 PDF → 解析 → 切块 → 向量化」这条链路**能力上通、数据上空**——有上传入口，但没有可用的文档语料。知识源要分四类设计：

| 编号 | 知识源 | 内容 | 现状 | 优先级 |
|------|--------|------|------|--------|
| **K1** | 平台资源语义索引 | `title + description + tags + 分类名 + 高赞评论` 拼成短文本 | 现成，几百~几千条 | **P0** |
| **K2** | 站内静态学业语料 | 考研 18 条资料链接、35 所院校、37 门网课、29 个开源项目、`curriculum.json` 课程表 | 现成，在 `entry/src/main/ets/data/*.json` | **P0** |
| **K3** | 用户上传文档 | 上传流程新增「本地文件」→ 落盘 → Tika 解析 → 切块 | 需新增功能 | P1 |
| **K4** | 社区帖子 / 评论 | `post` 表内容 | 噪声大，默认关闭 | P2 |

**K1 + K2 就能让 RAG 立即可用**，且 K2 的内容全是你考研用得上的，做起来有动力。K3 是后期让"文档问答"成立的补充。

### 增量同步策略

不要每次全量重建，做一个轻量同步队列：

```
资源审核通过 (status 0→1)  →  入向量库
资源被驳回 (status 1→2)    →  按 ref_id 删向量
资源被编辑 / 删除          →  先删后加
定时任务 @Scheduled 每 5 分钟  →  扫 ai_embedding_sync 表里未处理/失败的记录，带重试上限
```

向量库里每个 chunk 必须带元数据：`source_type`（RESOURCE/POST/STATIC/DOC）、`ref_id`、`doc_id`、`title`，删改全靠它过滤。

```java
// 删除某资源的所有向量
vectorStore.delete(Filter.Expression.eq("ref_id", String.valueOf(resourceId)));
```

---

## 2. 智能体设计：不是聊天框，是能干活的工具编排

框架能力 = **ChatClient + Tool Calling + ChatMemory + RAG Advisor**，四件套组合：

```
用户提问
   │
   ├─① ChatMemory 取最近 20 条历史
   ├─② QuestionAnswerAdvisor 先检索向量库，把 Top-5 chunk 塞进 system prompt
   ├─③ LLM 判断：直接回答 / 还是调工具
   │      └─ 调工具 → 执行 Java 方法 → 结果回灌 → 再让 LLM 总结
   └─④ SSE 逐 token 吐给前端
```

### 工具清单（Tool Calling）

| 工具 | 入参 | 作用 | 备注 |
|------|------|------|------|
| `search_resources` | query, categoryId, type, limit | **语义检索**资源库（走向量，不是 LIKE） | 核心 |
| `get_resource_detail` | resourceId | 详情 + 评论摘要 | |
| `search_course_video` | keyword | 37 门 B 站网课库检索 | K2 |
| `query_school` | name | 35 所院校考研信息 | K2 |
| `recommend_study_plan` | goal, daysLeft | 结合语料生成复习计划 | 纯 LLM + K2 |
| `get_my_favorites` | — | 当前用户收藏（从 JWT 取 userId，不信任入参） | 个性化 |
| `navigate` | page, params | **返回结构化跳转指令，端上执行跳页** | 差异化卖点 |

`navigate` 是让它从"聊天机器人"变成"智能体"的关键：模型返回 `{"action":"navigate","page":"ResourceDetail","params":{"id":42}}`，Web 用 `router.push`、鸿蒙用 `router.pushUrl` 真跳过去。

### 护栏（必须做，不然面试被问死）

- **工具白名单**：只注册上面这几个，参数全部校验，MyBatis-Plus 用 wrapper 防注入
- **权限隔离**：`status = 1` 才进检索结果；`get_my_favorites` 的 userId 从 JWT 解析，绝不接受模型传参
- **引用溯源**：每个 chunk 带 `ref_id`，回答里标注引用，前端渲染「来源」卡片，点击跳资源详情页 —— 这是 RAG 可信度的核心
- **兜底话术**：system prompt 里写死「检索不到就明说没有，不许编造资料标题和链接」
- **限流**：单用户 20 次/分钟；单次会话 token 上限；日调用预算熔断

---

## 3. 数据库新增表

已单独生成：`sql/migration_V4_ai_agent.sql`，四张表：

| 表 | 用途 |
|----|------|
| `ai_chat_session` | 会话（用户、标题、模型、时间） |
| `ai_chat_message` | 消息（角色、内容、工具调用 JSON、token 消耗） |
| `ai_knowledge_doc` | 知识文档元数据（来源类型、关联 ID、标题、文件路径、切块数、状态） |
| `ai_embedding_sync` | 向量同步队列（增量入库/删除、失败重试、错误信息） |

设计要点：
- 向量只存 Qdrant，MySQL 只存**元数据 + 关联关系**，两边靠 `doc_id` / `ref_id` 对齐
- `ai_embedding_sync` 是幂等的关键：异步任务挂了重启后能续跑，失败次数上限 3 次后告警

---

## 4. API 设计

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/ai/chat` | **SSE 流式**对话，返回 `text/event-stream` |
| GET | `/api/ai/sessions` | 会话列表 |
| GET | `/api/ai/sessions/{id}/messages` | 历史消息 |
| DELETE | `/api/ai/sessions/{id}` | 删除会话 |
| GET | `/api/ai/search?q=&topK=` | **独立语义搜索**（可直接替换首页关键词搜索，做成「AI 搜索」tab） |
| POST | `/api/ai/knowledge/doc` | 上传文档入库（K3） |
| POST | `/api/admin/ai/reindex` | 管理员全量重建索引 |

`/api/ai/search` 建议单独做出来 —— 它可以脱离聊天框，直接给首页加一个「语义搜索」开关，A/B 对比 LIKE 搜索的效果，面试时能讲数据。

---

## 5. 两个必踩的坑（提前写下来）

### 坑 1：一个 starter 只能配一个 base-url，chat 和 embedding 是两家厂商

DeepSeek 只有 chat，没有 embedding API。Spring AI 的 openai starter 自动装配用的是**同一份** api-key + base-url，配了 DeepSeek 就没法配阿里云。

解法：chat 走自动配置，embedding **手动造 bean**（自动配置是 `@ConditionalOnMissingBean`，自己定义就会让位）：

```java
@Configuration
public class AiEmbeddingConfig {

    @Value("${neushare.ai.embedding.api-key}")
    private String apiKey;

    @Bean
    public EmbeddingModel embeddingModel() {
        OpenAiApi api = OpenAiApi.builder()
                .apiKey(apiKey)
                .baseUrl("https://dashscope.aliyuncs.com/compatible-mode/v1")
                .build();
        return new OpenAiEmbeddingModel(
                api,
                MetadataMode.EMBED,
                OpenAiEmbeddingOptions.builder()
                        .model("text-embedding-v4")
                        .dimensions(1024)   // 套娃截断，别用默认 2048，存储和检索成本翻倍
                        .build()
        );
    }
}
```

### 坑 2：换 embedding 模型必须全量重建索引

不同模型的向量空间不兼容。今天用 v4，明天换 BGE-M3，混在一起检索结果就是垃圾。
**约定**：`ai_knowledge_doc` 里记 `embedding_model` 字段，启动时校验与当前配置一致，不一致直接拒绝启动并提示 reindex。

---

## 6. 三端接入

### Web（Vue 3）

- 新增 `views/ai/AssistantView.vue` + `api/ai.js`
- 首页右下角悬浮 AI 入口球，点开抽屉式聊天面板
- SSE 用 `fetch` + `ReadableStream` 手动解析（EventSource 不支持 POST，而提问内容可能很长）

### HarmonyOS

- 新增 `pages/AiAssistantPage.ets`，复用 `ColorTokens` / `BreakpointSystem` 保持视觉一致
- SSE：`@ohos.net.http` 的 `on('dataReceive')` 分块接收，自己按 `\n\n` 切事件
- `navigate` 工具返回的 action 用 `router.pushUrl` 落地

### 后端

- `com.neushare.ai` 包：`controller` / `service` / `tools` / `config` / `entity`
- **不要污染现有 service**，AI 侧只读 + 通过现有 Service 接口调用

---

## 7. 落地路线（按半天/整块时间切，适配考研节奏）

| 步骤 | 内容 | 预估 |
|------|------|------|
| 1 | Boot 3.3.7 → 3.5.x，引入 Spring AI BOM，跑通非流式 `/api/ai/chat` | 半天 |
| 2 | K1 资源语义索引 + `/api/ai/search` 语义搜索接口 | 1 天 |
| 3 | SSE 流式 + 会话持久化（4 张表 + ChatMemory） | 1 天 |
| 4 | Tool Calling 7 个工具 + 护栏（限流、鉴权、溯源） | 1 天 |
| 5 | K2 静态语料入库 + `navigate` 跳页联动 | 1 天 |
| 6 | K3 文档上传解析 RAG（Tika + 切块 + 引用溯源 UI） | 2 天 |
| 7 | 鸿蒙端 AI 页面 | 1 天 |
| 8 | **LangChain4j 接入**：独立 collection 入库 + 门面接口 + 双引擎适配器 | 1 天 |
| 9 | **高级 RAG**：查询改写 + 混合检索 + RRF + 重排序 | 1.5 天 |
| 10 | **LangGraph4j 工作流**：学习路径规划的多步编排 + Checkpoint | 1.5 天 |
| 11 | 五组对照评测 + 简历话术整理 | 半天 |

**建议先做到第 2 步就停下来验证**：如果语义搜索的召回质量不行，后面全是白搭。

---

## 8. 评测：做一个 50 条的问答集（面试最值钱的部分）

大多数学生项目只说"我做了 RAG"，说不出效果。你做一个 `docs/ai-eval-set.md`：

- 50 条真实用户问题 + 人工标注的标准答案资源 ID
- 指标：**Recall@5**（正确资源出现在 Top-5 的比例）、**MRR**、首 token 延迟、平均单次成本
- 五组对照实验，一组一组加能力，才能说清楚每个技术的贡献：

| 组 | 方案 | 用到的技术 |
|----|------|-----------|
| A | 关键词 LIKE 搜索 | 基线 |
| B | 纯向量检索 | Spring AI + Qdrant |
| C | 向量 + BM25 混合 + RRF | LangChain4j `DefaultContentAggregator` |
| D | C + 查询改写 | LangChain4j `CompressingQueryTransformer` |
| E | D + 重排序 | LangChain4j `ReRankingContentAggregator` |

跑出「A 41% → B 78% → E 89%」这种递增曲线，比任何形容词都有说服力，而且能直接对应到简历上每一项技术的价值。

---

## 9. 成本估算

| 项 | 量 | 费用 |
|----|-----|------|
| 资源入库（一次性） | 1000 条 × 200 token = 20 万 token | ¥0.1 |
| 静态语料入库（一次性） | 约 5 万 token | ¥0.025 |
| 每次检索（query 向量化） | ~500 token | ¥0.00025 |
| 每次对话 | ~2k token | DeepSeek 约 ¥0.004 |

**日常跑起来一个月几块钱**，够用了。注意别在循环里重复向量化同一份内容。

---

## 10. 风险与待办

- [ ] **安全**：`application.yml` 里的 MySQL 密码和 JWT 密钥已提交到公开仓库，需立刻改密码、改密钥，并把配置文件加入 `.gitignore` 改用 `.env` / 环境变量
- [ ] Spring AI 1.x 与 Boot 3.3.7 的兼容性风险 → 先升 3.5.x
- [ ] **两个框架的向量索引必须分 collection**，不能指向同一个
- [ ] LangChain4j 的 `AgenticServices` 是实验性 API，别写进"生产使用"
- [ ] 只索引 `status = 1` 的已发布资源，审核状态变化要同步删向量
- [ ] K4 评论噪声大，默认不入库
- [ ] Qdrant 放 D 盘绿色运行，别装 C 盘

---

## 11. LangChain 技术栈如何融入（LangChain4j + LangGraph4j）

Java 生态里没有 Python 版 LangChain，对应物是 **LangChain4j**（它不是 LangChain 的移植，是为 Java 独立设计的）。引入它不是为了凑技术名词，而是因为 Spring AI 1.x 在**高级 RAG** 上有明确缺口。

### 11.1 能力对比：为什么两个都要

| 能力 | Spring AI 1.1 | LangChain4j 1.13 |
|------|:---:|:---:|
| Boot 自动装配深度 | 强（原生） | 有 starter，弱一些 |
| 基础 RAG（`QuestionAnswerAdvisor`） | 有 | 有（`EmbeddingStoreContentRetriever`） |
| 多轮查询压缩改写 | 无 | `CompressingQueryTransformer` |
| 查询扩写（一个 query 变 N 个） | `MultiQueryExpander` | `ExpandingQueryTransformer` |
| 多路召回 RRF 融合 | 需手写 | `DefaultContentAggregator` 内置 |
| 重排序（Cross-Encoder） | **无内置** | `ReRankingContentAggregator` 内置 |
| 声明式 AI 接口 | 无（用 ChatClient） | `AiServices` 接口即实现 |
| 支持的模型 / 向量库数量 | 较少 | 更多（Cohere rerank、HF、IBM 等） |
| MCP 支持 | 一等公民 | 支持 |

结论很清楚：**Spring AI 负责让它跑起来，LangChain4j 负责让它检索得准。**

### 11.2 分层架构：门面 + 双适配器

不要让两套框架的 API 散落在业务代码里。定义一层自己的门面接口，两套实现可切换：

```
Controller / Service（业务层，只认 AiGateway）
        ↓
   AiGateway（自研接口：chat / search / indexDoc）
        ↓
   ┌────────────────────┬────────────────────────┐
   │ SpringAiGatewayImpl │ LangChain4jGatewayImpl │
   │ 基础 RAG + 工具      │ 高级 RAG（改写+混合+重排）│
   └────────────────────┴────────────────────────┘
        ↓                        ↓
   共用：Qdrant / MySQL 元数据 / DeepSeek / 阿里 embedding
```

```java
public interface AiGateway {
    Flux<String> streamChat(Long userId, String sessionId, String question);
    List<Citation> search(String query, int topK);
    void indexDoc(KnowledgeDoc doc);
}
```

配置 `neushare.ai.engine=spring-ai | langchain4j` 切换实现。这样既能 A/B 对比两个框架的实际效果，又能在某个框架出问题时快速降级 —— **这本身就是简历上一个很好的架构点**。

### 11.3 强警告：两个框架的向量索引不能共用

`VectorStore`（Spring AI）和 `EmbeddingStore`（LangChain4j）是**两套独立抽象**，即使底层都是 Qdrant，存储约定（payload 结构、id 生成、元数据键名）也不一样，**不能指向同一个 collection**。

正确做法：

```
Qdrant
├── neushare_kb_springai    ← Spring AI 写入
└── neushare_kb_l4j         ← LangChain4j 写入
```

同一份语料各自入库一次（成本极低，1000 条资源才 ¥0.1），元数据侧共用 `ai_knowledge_doc` 表，用 `engine` 字段区分。切换引擎时只改配置，索引互不污染。

### 11.4 高级 RAG 链路（LangChain4j 的主战场）

```
用户问题 "那它呢？"
   ↓ ① CompressingQueryTransformer
   （结合历史，压缩成独立查询："操作系统进程调度的复习资料"）
   ↓ ② 并行双路召回
   向量检索（Qdrant）      BM25 关键词检索（Lucene / ES）
   ↓ ③ DefaultContentAggregator 用 RRF 融合两路排名
   ↓ ④ ReRankingContentAggregator + bge-reranker-v2-m3 精排
   ↓ ⑤ 注入 prompt，LLM 生成，附引用
```

```java
@Bean
public RetrievalAugmentor retrievalAugmentor(ChatLanguageModel compressionModel,
                                              EmbeddingStore<TextSegment> store,
                                              EmbeddingModel embeddingModel,
                                              ScoringModel scoringModel) {
    // ① 多轮查询压缩：把"那它呢？"还原成完整问题
    QueryTransformer transformer = CompressingQueryTransformer.builder()
            .chatLanguageModel(compressionModel)
            .build();

    // ② 稠密检索（向量）
    ContentRetriever dense = EmbeddingStoreContentRetriever.builder()
            .embeddingStore(store)
            .embeddingModel(embeddingModel)
            .maxResults(10)
            .minScore(0.65)
            .build();

    // ③ + ④：RRF 融合后重排序
    ContentAggregator aggregator = ReRankingContentAggregator.builder()
            .scoringModel(scoringModel)      // bge-reranker-v2-m3
            .build();

    return DefaultRetrievalAugmentor.builder()
            .queryTransformer(transformer)
            .contentRetriever(dense)
            .contentAggregator(aggregator)
            .build();
}
```

声明式业务接口（`AiServices` 自动生成实现）：

```java
public interface StudyAdvisor {
    @SystemMessage("""
        你是 NeuShare 校园学习助手。只依据检索到的资料回答，
        资料中没有的内容必须明确说明"平台暂未收录"，不得编造资源标题或链接。
        回答末尾列出引用来源。
        """)
    String chat(@UserMessage String question);
}

@Bean
public StudyAdvisor studyAdvisor(ChatLanguageModel model,
                                  RetrievalAugmentor augmentor,
                                  ResourceTools tools) {
    return AiServices.builder(StudyAdvisor.class)
            .chatLanguageModel(model)
            .retrievalAugmentor(augmentor)
            .tools(tools)                                        // 复用同一套 @Tool
            .chatMemoryProvider(id -> MessageWindowChatMemory.withMaxMessages(20))
            .build();
}
```

> 工具类是共享的：Spring AI 用 `@Tool`（`org.springframework.ai.tool.annotation.Tool`），LangChain4j 用 `@Tool`（`dev.langchain4j.agent.tool.Tool`），两个注解同名不同包。建议在 `com.neushare.ai.tool` 下写**纯 Java 业务方法**，再由两个框架的薄包装类各自加注解，避免业务代码被框架绑死。

### 11.5 LangGraph4j：多智能体工作流编排

当任务不是"一问一答"而是多步决策时（比如"帮我找资料并整理成一周复习计划"），用状态图比堆 if-else 清晰得多。LangGraph4j 1.8.18（2026-06 稳定版，Java 17+）同时提供 LangChain4j 和 Spring AI 的集成模块。

资料求助工作流的图结构：

```
START → 意图分类 →┬─ 直接回答（寒暄/闲聊）──────────────┐
                  └─ 资料检索 → 相关性判定 →┬─ 足够 → 生成回答 ─┤
                                            └─ 不足 → 改写查询 ↺（回到检索，最多 2 次）
                                                              → END
```

```java
var workflow = new StateGraph<>(StudyState.SCHEMA, StudyState::new)
        .addNode("classify",  classifyNode)    // LLM 判断意图
        .addNode("retrieve",  retrieveNode)    // 调 LangChain4j 高级检索
        .addNode("grade",     gradeNode)       // 判定召回片段是否足够
        .addNode("rewrite",   rewriteNode)     // 改写查询后重检索
        .addNode("generate",  generateNode)    // 生成 + 引用校验
        .addEdge(START, "classify")
        .addConditionalEdges("classify", state ->
                "chat".equals(state.intent()) ? "generate" : "retrieve")
        .addConditionalEdges("grade", state ->
                state.enough() || state.retryCount() >= 2 ? "generate" : "rewrite")
        .addEdge("rewrite", "retrieve")
        .addEdge("retrieve", "grade")
        .addEdge("generate", END)
        .compile(CompileConfig.builder()
                .checkpointSaver(new MySqlSaver(dataSource))   // 断点续跑 / 时光回溯
                .build());
```

价值点：
- `langgraph4j-mysql-saver`：Checkpoint 落 MySQL，流程中断可恢复，调试能回看历史状态
- `studio` 模块：嵌入式 Web UI 实时看图执行，演示和调试都方便
- 条件边 + 循环边，天然支持"检索质量不够就重试"这类自纠正逻辑

### 11.6 Maven 依赖

```xml
<properties>
    <langchain4j.version>1.13.0</langchain4j.version>
    <langgraph4j.version>1.8.18</langgraph4j.version>
</properties>

<!-- LangChain4j BOM -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-bom</artifactId>
    <version>${langchain4j.version}</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>

<!-- 核心 + Spring Boot starter -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j</artifactId>
</dependency>
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-spring-boot-starter</artifactId>
</dependency>

<!-- Qdrant 向量库（独立于 Spring AI 的 collection） -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-qdrant</artifactId>
</dependency>

<!-- 高级 RAG：查询改写 / 重排序 -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-rag</artifactId>
</dependency>

<!-- 文档解析 + Easy RAG（静态语料一键入库） -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-document-parser-apache-tika</artifactId>
</dependency>
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-easy-rag</artifactId>
</dependency>

<!-- LangGraph4j 编排 -->
<dependency>
    <groupId>org.bsc.langgraph4j</groupId>
    <artifactId>langgraph4j-core</artifactId>
    <version>${langgraph4j.version}</version>
</dependency>
<dependency>
    <groupId>org.bsc.langgraph4j</groupId>
    <artifactId>langgraph4j-langchain4j</artifactId>
    <version>${langgraph4j.version}</version>
</dependency>
<dependency>
    <groupId>org.bsc.langgraph4j</groupId>
    <artifactId>langgraph4j-mysql-saver</artifactId>
    <version>${langgraph4j.version}</version>
</dependency>
```

### 11.7 引入顺序与风险

按顺序来，别一次性全上：

1. **先 Spring AI 跑通主链路**（第 1~4 步），有东西可用
2. **再引入 LangChain4j 只做检索增强**（查询改写 + 混合 + RRF + 重排），用评测集证明 Recall@5 确实涨了
3. **最后上 LangGraph4j 编排多步工作流**，只用在"学习路径规划"这类复杂任务上，别把所有对话都塞进图里（延迟会变高）

风险清单：

- `AgenticServices`（LangChain4j 的多智能体编排）**官方标注 experimental，API 会变**，别在简历里写成"生产使用"，写"预研"
- Easy RAG 默认切分对中文不友好，中文语料建议自定义 `DocumentSplitters.recursive(300, 50)`
- 重排序模型国内可选硅基流动 / 智谱的 rerank API，或本地起 HuggingFace TEI；本地部署要吃内存，考研期间建议直接用云 API
- LangGraph4j Studio 会额外占一个端口，别和 8080/5173 冲突

---

## 12. 简历话术（可直接使用）

> **NeuShare 智能助手模块**｜Spring AI 1.1 + LangChain4j + LangGraph4j + DeepSeek + Qdrant
> - 设计并实现校园资源共享智能体：RAG 语义检索（Chunk 级切分 + 元数据过滤）+ Tool Calling 工具编排（7 个业务工具）+ SSE 流式输出 + 多轮会话持久化
> - 构建四类知识源增量同步链路（资源 / 静态学业语料 / 上传文档 / 社区内容），基于同步队列表实现失败重试与幂等
> - 针对 Spring AI 1.x 缺少高级 RAG 能力的问题，引入 **LangChain4j** 实现查询改写（CompressingQueryTransformer）、向量+BM25 混合检索、RRF 多路召回融合与 Cross-Encoder 重排序，并通过 **自研门面接口 + 双引擎适配器**实现两套框架可切换、可 A/B 对比
> - 使用 **LangGraph4j** 编排多步智能体工作流（意图分类 → 检索 → 相关性判定 → 查询改写重检索 → 生成），Checkpoint 落 MySQL 支持中断恢复
> - 设计权限护栏与引用溯源机制，工具入参从 JWT 解析防越权，回答附来源卡片可跳转
> - 搭建 50 条评测集做五组对照实验，Recall@5 从关键词搜索 41% → 纯向量 78% → 混合+改写+重排 89%

---

## 附：核心代码骨架

### application.yml 新增

```yaml
spring:
  ai:
    openai:
      api-key: ${DEEPSEEK_API_KEY}
      base-url: https://api.deepseek.com
      chat:
        options:
          model: deepseek-chat
          temperature: 0.3
    vectorstore:
      qdrant:
        host: localhost
        port: 6334          # gRPC 端口，不是 6333
        collection-name: neushare_kb
        initialize-schema: true

neushare:
  ai:
    embedding:
      api-key: ${DASHSCOPE_API_KEY}
      model: text-embedding-v4
      dimensions: 1024
    rate-limit: 20          # 单用户每分钟
```

### RAG 检索 + 流式对话 Controller

```java
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiChatController {

    private final ChatClient chatClient;          // 已装配 advisor + tools + memory
    private final ChatMemory chatMemory;

    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> chat(@RequestBody ChatRequest req,
                                              HttpServletRequest http) {
        Long userId = (Long) http.getAttribute("userId");   // JwtInterceptor 已解析

        // 注入会话记忆 + 用户上下文
        MessageChatMemoryAdvisor memoryAdvisor = MessageChatMemoryAdvisor
                .builder(chatMemory)
                .conversationId(req.getSessionId())
                .build();

        return chatClient.prompt()
                .user(req.getQuestion())
                .advisors(a -> a
                        .param(ChatMemory.CONVERSATION_ID, req.getSessionId())
                        .param("userId", userId))
                .stream()
                .content()
                .map(chunk -> ServerSentEvent.<String>builder().data(chunk).build())
                .concatWith(Flux.just(ServerSentEvent.<String>builder()
                        .event("done").data("[DONE]").build()));
    }
}
```

### 工具定义

```java
@Component
@RequiredArgsConstructor
public class ResourceTools {

    private final VectorStore vectorStore;
    private final ResourceService resourceService;

    @Tool(description = "按自然语言语义搜索平台学习资料，返回最相关的资源列表")
    public List<ResourceBrief> searchResources(
            @ToolParam(description = "搜索意图描述") String query,
            @ToolParam(description = "分类ID，可选") Long categoryId,
            @ToolParam(description = "返回条数，默认5") Integer limit) {

        SearchRequest request = SearchRequest.builder()
                .query(query)
                .topK(limit == null ? 5 : limit)
                .similarityThreshold(0.6)
                .filterExpression("source_type == 'RESOURCE'")   // 只检索已发布资源
                .build();

        return vectorStore.similaritySearch(request).stream()
                .map(doc -> new ResourceBrief(
                        doc.getMetadata().get("ref_id"),
                        doc.getMetadata().get("title"),
                        doc.getText()))
                .toList();
    }

    @Tool(description = "返回一条跳转指令，让客户端跳转到指定页面")
    public NavigateAction navigate(
            @ToolParam(description = "目标页面：Home/ResourceDetail/Upload/Profile") String page,
            @ToolParam(description = "页面参数，如资源ID") Map<String, String> params) {
        return new NavigateAction(page, params);
    }
}
```

### 资源入库（K1）

```java
@Service
@RequiredArgsConstructor
public class KnowledgeIndexService {

    private final VectorStore vectorStore;
    private final EmbeddingModel embeddingModel;

    public void indexResource(Resource resource, String categoryName) {
        // 1. 先删旧向量，保证幂等
        vectorStore.delete(Filter.Expression.eq("ref_id", String.valueOf(resource.getId())));

        // 2. 拼接语义文本：标题 + 分类 + 标签 + 描述
        String text = String.join("\n",
                resource.getTitle(),
                "分类：" + categoryName,
                "标签：" + resource.getTags(),
                resource.getDescription() == null ? "" : resource.getDescription());

        // 3. 短文本不切块，整条入库
        Document doc = new Document(text, Map.of(
                "source_type", "RESOURCE",
                "ref_id", String.valueOf(resource.getId()),
                "title", resource.getTitle(),
                "category_id", String.valueOf(resource.getCategoryId())));

        vectorStore.add(List.of(doc));
    }
}
```
