# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# NeuShare — 校园资料分享平台

> ⚠️ **2026-11-18 架构变更**：Spring Boot 后端已退役并从仓库移除，主后端改为
> `neushare-backend-py`（FastAPI，仍占 :8080，API 契约与旧后端 100% 兼容）。
> 本文档中凡涉及 `neushare-backend/` 路径、`mvn` 命令的段落均为历史记录，
> 实际以 `neushare-backend-py/` 与 `neushare-ai/` 为准。

## 项目概览

东北大学（NEU）学习资料分享平台。学生/教师可上传、搜索、浏览、评论、点赞、收藏课程资料。管理员审核资料、管理用户和轮播图。

架构：**Vue 3 Web 前端** + **FastAPI 主后端 (:8080)** + **FastAPI AI 服务 (:8000)** + **HarmonyOS NEXT 移动端**

---

## 技术栈

| 层 | 技术 |
|---|------|
| Web 前端 | Vue 3 (Composition API `<script setup>`), Vite 5, Element Plus 2.6, Pinia, Vue Router 4, Axios, ECharts 5 |
| 主后端 | FastAPI, SQLAlchemy 2.0 (asyncmy), MySQL 8, PyJWT, bcrypt, Redis(可选) |
| AI 服务 | FastAPI, LangGraph 0.2.x, LangChain 0.3.x, FAISS, Tavily 联网检索, SSE |
| 移动端 | HarmonyOS NEXT API 22, ArkUI + ArkTS, 双模块 HAR 架构 |
| 构建 | pip/uvicorn (backend), npm/vite (frontend), DevEco Studio (HarmonyOS), docker compose |

---

## 常用命令

```bash
# Web 前端
cd neushare-frontend
npm install && npm run dev      # → localhost:3000，/api 代理到 8080、/ai 代理到 8000
npm run build                   # 生产构建 → dist/
npm run preview                 # 预览生产构建

# 主后端（FastAPI, :8080）
cd neushare-backend-py
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
python -m pytest tests/contract -q     # 契约回归（需种子态数据库）

# AI 服务（FastAPI, :8000）
cd neushare-ai
pip install -r requirements.txt
uvicorn app.main:app --port 8000
python -m pytest tests -q              # 护栏测试，无需 API key

# 数据库初始化
# 1. 确保 MySQL 8 运行中
# 2. 执行 sql/init.sql 建库+建表+种子数据
# 3. 执行 sql/migration_V5V6V7_for_python_backend.sql（V5/V6/V7 增量，幂等）

# 鸿蒙 App
# DevEco Studio 打开项目根目录 → Sync → Run
```

---

## 目录结构

```
NeuShare/
├── neushare-frontend/          # Vue 3 Web 前端
│   └── src/
│       ├── api/                # Axios 请求模块: auth, resource, comment, favorite, follow, notification, user, admin, banner, ai, aiConfig, post, request
│       ├── components/         # Header, Footer, ResourceCard, Sidebar, AiFloatingWindow, CommentItem, EmptyState, SkeletonCard
│       ├── router/index.js     # Vue Router + beforeEach 守卫
│       ├── store/modules/      # Pinia 用户状态（token, userInfo）+ AI 会话
│       ├── styles/global.css   # CSS 变量、重置、动画
│       ├── utils/              # constants, format, courseData, url
│       └── views/              # Home, ResourceDetail, Upload, Login/Register, UserProfile, Community, PostDetail, CreatePost, PostgradGuide, AiAssistant + profile/ + admin/
│
├── neushare-backend-py/        # Python 主后端（FastAPI, :8080）
│   └── app/
│       ├── api/v1/             # 16 个路由模块，89 个端点（见下方 API 清单）
│       ├── services/           # 业务逻辑（含 search_service：V5/V6 结构化检索）
│       ├── models/ · schemas/  # SQLAlchemy 模型 · Pydantic 模型
│       ├── db/                 # 异步会话 · Redis
│       ├── core/               # 配置, 响应信封 {code,message,data}, 异常处理器, 鉴权
│       ├── middleware/         # JWT 中间件
│       └── utils/              # 分页窗口 · 时间格式化
│
├── neushare-ai/                # AI 智能体服务（FastAPI + LangGraph, :8000）
│   └── app/
│       ├── agent/              # LangGraph 图 · 工具 · 护栏(guardrails) · SSE 流
│       ├── auth/               # JWT 与主后端互通（同一 JWT_SECRET）
│       ├── db/                 # 会话/消息持久化
│       ├── ingestion/          # 资源 → 切分 → FAISS 向量入库
│       └── middleware/         # 限流
│
├── sql/                        # init.sql 建表 + 各版本迁移
│
├── common/                     # 鸿蒙公共 HAR 模块（被 entry 依赖）
│   └── src/main/ets/
│       ├── theme/              # ColorTokens（亮靛蓝/暗黑白双主题）+ AppTheme
│       ├── components/         # GlassCard, ColorDot, EmptyState, GlassNavBar, TypeTag
│       ├── network/            # HttpClient + AuthStore
│       ├── utils/              # BreakpointSystem (5级), BlurPerformance, InteractionUtils, ResourceTypeUtils
│       ├── services/           # PreferencesStore
│       └── types/              # PageData<T> 分页接口
│
├── entry/                      # 鸿蒙应用入口模块
│   └── src/main/ets/
│       ├── pages/              # 22 个页面（含 SplashPage, Index, 4 个 Tab 等）
│       ├── components/         # BannerSwiper, ResourceCard, CategoryCard, SearchBar 等 7 组件
│       ├── services/           # ResourceService, FavoriteService, CommunityService 等 8 服务
│       ├── api/                # AuthApi, ResourceApi, PostApi, FollowApi 等 10 个 API 模块
│       ├── models/             # PostModel, ResourceModel
│       ├── data/               # banners.json 本地种子数据
│       └── entryability/       # EntryAbility（意图框架 + 断点 + 沉浸式状态栏）
│
├── docs/                       # 设计文档（配色方案、HarmonyOS 开发教程）
└── CLAUDE.md / README.md / DEV_PLAN.md
```

---

## 鸿蒙端架构（重要）

### common HAR 模块导出清单

`common/Index.ets` 统一导出以下公共能力：

```typescript
// Theme
export { ColorTokens }          // 双主题色板（LIGHT/DARK 两套完全独立的色彩系统）
export { AppTheme, ThemeMode }  // 主题管理器（LIGHT/DARK/SYSTEM）
export { DesignTokens, Spacing, Radii, FontScale, ControlSize, Elevation, ZIndex, GridLayout }  // 间距/圆角/字号/控件高/阴影/层级/栅格列数

// Utils
export { BreakpointSystem, BreakpointType, BreakpointTypeEnum, BreakpointTypeValue }  // 5 级断点: XS/SM/MD/LG/XL
export { BlurPerformance, BlurLevel }                            // 毛玻璃性能分级（HIGH/LOW/NONE）
export { PressableScale }       // 按钮按压缩放动画工具
export { ResourceTypeUtils }    // 资源类型图标/颜色映射

// Services
export { PreferencesStore }     // 本地键值持久化

// Network
export { HttpClient, ApiResponse }  // HTTP 客户端（401 竞态修复、postWithParams、deleteWithParams）
export { AuthStore }                // JWT Token + 用户信息持久化

// Types
export { PageData<T> }          // 统一分页响应接口 { records, total, pageNum, pageSize }
export { ViewState }            // 加载/空/失败三态枚举

// Components
export { EmptyState }           // 空状态占位组件（支持操作按钮）
export { PageScaffold }         // 页面骨架：安全区 + 标题区 + 内容区
export { PageHeader }           // 页面标题栏（返回/标题/操作）
export { SectionHeader }        // 区块标题
export { StateView }            // 加载中 / 空数据 / 失败重试三态视图
export { AppButton }            // 统一 40 高主/次按钮

// 注意：GlassCard、GlassNavBar、ColorDot、TypeTag 是 common 内部组件，未从 Index.ets 导出
```

### 断点系统（BreakpointSystem）

三通道架构：`window.getWindowSize()`（初始值） + `mediaQuery`（响应式更新） + `display`（兜底）

```typescript
// 阈值定义（单位 vp）
// XS < 320 | SM 320-600 | MD 600-840 | LG 840-1440 | XL ≥ 1440

// 页面中订阅断点变化
@StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;

// 按断点取值（替代 if/else 阶梯判断）
new BreakpointType<number>({ sm: 1, md: 2, lg: 3, xl: 4 }).getValue(this.currentBreakpoint)
```

### 配色系统（ColorTokens）

两种主题使用**完全不同的视觉语言**——不是简单的颜色反转：

- **亮色（Light）**：靛蓝毛玻璃 `#4A6BFF`，多彩渐变背景（粉/紫/蓝/青），`backdropBlur(40)` 玻璃卡片
- **深色（Dark）**：极简黑白 `#0E0E10` 背景，唯一强调色 `#FFFFFF`，零彩色全靠强度/粗细/边框区分层级
- 所有页面通过 `@StorageLink('isDarkMode')` 订阅主题，使用 `ColorTokens.PRIMARY(isDark)` 等动态方法取值
- 60+ 处组件硬编码已全部替换为 ColorTokens 引用

### 毛玻璃性能分级（BlurPerformance）

避免低端设备/滚动场景下毛玻璃导致掉帧：

| 级别 | 值 | 触发条件 |
|------|-----|------|
| `HIGH` | 40 | 高端设备 + 静止状态 |
| `LOW` | 20 | 中端设备 |
| `NONE` | 0 | 低端设备 或 滚动中 |

- AppStorage 键：`isScrolling`、`blurLevel`
- `onScrollFrameBegin` 回调中更新滚动状态（静态缓存避免每帧查询 AppStorage）
- GlassCard 通过 `@StorageProp('blurLevel')` 订阅响应式降级

### HttpClient 关键约定

```typescript
const httpClient = HttpClient.getInstance();

// 标准 GET（自动拼接查询字符串）
httpClient.get<T>('/api/resource/list', { pageNum: 1, pageSize: 10 });

// POST/PUT 带 JSON body
httpClient.post<T>('/api/resource/create', data);
httpClient.put<T>('/api/resource/update', data);

// POST/DELETE 带 params（对应后端 @RequestParam）
httpClient.postWithParams<T>('/api/follow/add', { followedId: 123 });
httpClient.deleteWithParams<T>('/api/favorite/remove', { resourceId: 456 });

// DELETE 路径参数
httpClient.del<T>('/api/resource/delete/' + id);
```

401 竞态修复：`handleUnauthorized` 使用 Promise 锁而非 boolean 标志，防止并发 401 多次跳转登录页。错误信息在 401 跳转后保留不丢失。

### 鸿蒙 API 模块与后端控制器的对应

| 鸿蒙 API 类 | 对应后端控制器 | 说明 |
|------------|--------------|------|
| `AuthApi` | `AuthController` | 登录/注册/个人信息/密码 |
| `ResourceApi` | `ResourceController` | 资源 CRUD + 点赞 + 搜索 |
| `CommentApi` | `CommentController` | 资源评论 |
| `FavoriteApi` | `FavoriteController` | 收藏管理 |
| `FollowApi` | `FollowController` | 关注/取关 |
| `PostApi` | `PostController` + `PostCommentController` | 社区帖子 + 帖子评论 |
| `NotificationApi` | `NotificationController` | 通知列表/已读/删除 |
| `StatsApi` | `StatsController` | 平台统计 |
| `UserApi` | `UserController` | 用户主页 |
| `BannerApi` | `BannerController` | 轮播图 |

### 鸿蒙服务层

| 服务 | 职责 |
|------|------|
| `ResourceService` | 资源搜索/分类/轮播图，本地 JSON 兜底 + API 桥接 |
| `FavoriteService` | 收藏/历史记录，基于 PreferencesStore 持久化 |
| `CommunityService` | 社区帖子本地管理 + 后端 API 桥接 |
| `CurriculumService` | 课程推荐数据 |
| `RecommendService` | 推荐算法（基于年级/收藏/浏览） |
| `TtsService` | 文本朗读 |
| `GradeService` | 年级设置 |
| `ShareHelper` | 分享功能 |

---

## 关键约定（修改代码前必须看）

### 1. 后端参数传递

后端大量使用 `@RequestParam`（而非 `@RequestBody`），前端必须用 `params` 而非 `data`：

| 接口 | 方式 |
|------|------|
| `PUT /api/auth/password` | `params: { oldPassword, newPassword }` |
| `POST /api/comment/add` | `params: { resourceId, content, parentId }` |
| `POST /api/favorite/add` | `params: { resourceId }` |
| `DELETE /api/favorite/remove` | `params: { resourceId }` |
| `GET /api/favorite/check` | `params: { resourceId }` |
| `POST /api/follow/add` | `params: { followedId }` |
| `DELETE /api/follow/remove` | `params: { followedId }` |
| `POST /api/post/comment/add` | `params: { postId, content, parentId? }` |
| `PUT /api/admin/user/status` | `params: { id, status }` |
| `PUT /api/admin/resource/audit` | `params: { id, status }` |
| `PUT /api/admin/banner/status` | `params: { id, status }` |

**例外**（使用 `data` JSON body）：`login`, `register`, `updateUserInfo`, `createResource`（FormData）, `updateResource`, `addBanner`, `updateBanner`, `createPost`, `updatePost`

### 2. 分页参数

- 请求参数: `pageNum`, `pageSize`（非 `page`/`size`）
- 响应字段: `res.data.records`, `res.data.total`（非 `list`）
- 鸿蒙端 `PageData<T>` 接口: `{ records: T[], total: number, pageNum: number, pageSize: number }`

### 3. 状态值（整数，非字符串）

- **资源状态**: `0`=待审核, `1`=已发布, `2`=已驳回
- **用户状态**: `0`=禁用, `1`=启用

### 4. VO 字段名

- 资源作者: `uploadNickname`, `uploadUsername`, `uploadAvatar`（非 `authorName`）
- 用户头像: `avatarUrl`（非 `avatar`）
- 轮播图: `imageUrl`, `linkUrl`（非 `image`/`link`）
- 评论: `nickname`, `avatarUrl`, `children`（非 `userName`/`replies`）
- 收藏检查: `res.data.isFavorite`（非 `isFavorited`）
- 关注检查: `res.data.isFollowing`（返回 Map 对象，非裸 boolean）
- 帖子标签/图片/文件: JSON 字符串需前端 `JSON.parse()`（如 `"[\"AI\",\"课程\"]"`）
- 帖子作者: `authorNickname`, `authorAvatarUrl`, `authorCollege`

### 5. 鸿蒙端特殊约定

- **响应式必须用 `window` API**：`window.getWindowSize()` 取初始尺寸 + `mediaQuery` 监听变化。不能用 `display.isFoldable()` / `display.getDefaultDisplaySync()` ——它们在非折叠屏模拟器上不可靠
- **点击热区 ≥ 40vp**：所有可交互元素满足最小触控区域
- **沉浸式状态栏**：`EntryAbility` 中设置 `window.setWindowSystemBarProperties({ statusBarColor: 'transparent' })`
- **本地 JSON 兜底**：所有数据获取操作先用本地 JSON 数据渲染首屏，再异步刷新 API 数据

---

## API 清单

### 公开（无需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/login | 登录 → `{token, user}` |
| POST | /api/auth/register | 注册 |
| GET | /api/resource/list | 资源分页 `?pageNum&pageSize&status&categoryId&keyword&sortBy=hot\|new` |
| GET | /api/resource/detail/{id} | 资源详情（自动浏览量+1） |
| GET | /api/resource/hot | 热门资源 `?limit` |
| GET | /api/resource/search | 搜索 `?keyword&sortBy=hot\|new`（仅已发布） |
| GET | /api/comment/list/{resourceId} | 评论列表（树形） |
| GET | /api/banner/list | 启用中的轮播图 |
| GET | /api/category/list | 全部分类（含 parentId 父子层级） |
| GET | /api/form-card/current | 当前启用的推荐卡片 |
| GET | /api/post/list | 帖子分页 `?pageNum&pageSize&tag&keyword&sortBy`（非管理员强制 status=1） |
| GET | /api/post/detail/{id} | 帖子详情（自动浏览量+1） |
| GET | /api/post/hot | 热门帖子 `?limit` |
| GET | /api/post/comment/list/{postId} | 帖子评论树 |
| GET | /api/user/{id} | 用户主页（状态禁用返回 404） |
| GET | /api/user/{id}/resources | 用户发布的资源分页 |
| GET | /api/stats/overview | 平台统计概览（分类/类型/来源分布、热门排行、趋势） |

### 需登录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/auth/info | 获取当前用户信息 |
| PUT | /api/auth/info | 更新个人信息 `{nickname, avatarUrl, college, grade}` |
| PUT | /api/auth/password | 修改密码 `params: oldPassword, newPassword` |
| POST | /api/resource/create | 创建资源（FormData） |
| PUT | /api/resource/update | 更新资源（JSON body） |
| DELETE | /api/resource/delete/{id} | 删除自己的资源（非管理员需是上传者） |
| GET | /api/resource/user | 我的资源 |
| POST | /api/resource/like/{id} | 点赞资源 |
| DELETE | /api/resource/like/{id} | 取消点赞资源 |
| GET | /api/resource/like/check/{id} | 检查是否已点赞 → `boolean` |
| POST | /api/comment/add | 添加评论 `params: resourceId, content, parentId?` |
| DELETE | /api/comment/delete/{id} | 删除自己的评论 |
| GET | /api/comment/user | 我的评论 |
| POST | /api/favorite/add | 收藏资源 `params: resourceId` |
| DELETE | /api/favorite/remove | 取消收藏 `params: resourceId` |
| GET | /api/favorite/check | 检查是否已收藏 `params: resourceId` → `{isFavorite}` |
| GET | /api/favorite/list | 我的收藏分页（含收藏时间） |
| POST | /api/follow/add | 关注用户 `params: followedId` |
| DELETE | /api/follow/remove | 取消关注 `params: followedId` |
| GET | /api/follow/check | 检查是否已关注 `params: followedId` → `{isFollowing}` |
| GET | /api/follow/following | 我关注的人分页 |
| GET | /api/follow/followers | 关注我的人分页 |
| POST | /api/post/create | 发帖（JSON body: `{title, content, tags, imageUrls?, files?}`） |
| PUT | /api/post/update | 编辑帖子（JSON body，非作者且非管理员不可操作） |
| DELETE | /api/post/delete/{id} | 删除帖子（非作者且非管理员不可操作） |
| POST | /api/post/like/{id} | 点赞帖子 |
| DELETE | /api/post/like/{id} | 取消点赞帖子 |
| GET | /api/post/like/check/{id} | 检查是否已点赞帖子 → `boolean` |
| POST | /api/post/favorite/{id} | 收藏帖子 |
| DELETE | /api/post/favorite/{id} | 取消收藏帖子 |
| GET | /api/post/favorite/check/{id} | 检查是否已收藏帖子 → `boolean` |
| GET | /api/post/user | 我的帖子分页 |
| PUT | /api/post/recommend/{id} | 推荐帖子（仅管理员） |
| POST | /api/post/comment/add | 添加帖子评论 `params: postId, content, parentId?` |
| DELETE | /api/post/comment/delete/{id} | 删除帖子评论（评论者/管理员可删，级联删除子评论） |
| GET | /api/notification/list | 通知列表分页 `?pageNum&pageSize&type`（type 可选: comment/follow/like/favorite/audit） |
| GET | /api/notification/unread | 未读通知数量 |
| PUT | /api/notification/read/{id} | 标记单条已读 |
| PUT | /api/notification/read-all | 标记全部已读 |
| DELETE | /api/notification/delete/{id} | 删除单条通知 |

### 管理员（/api/admin/**，额外需要 role="admin"）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/admin/statistics | 统计数据 |
| GET | /api/admin/user/list | 用户列表 `?pageNum&pageSize&keyword` |
| PUT | /api/admin/user/status | 修改用户状态 `params: id, status` |
| DELETE | /api/admin/user/delete/{id} | 删除用户 |
| GET | /api/admin/resource/pending | 待审核资源 |
| PUT | /api/admin/resource/audit | 审核 `params: id, status` |
| DELETE | /api/admin/resource/delete/{id} | 删除任意资源 |
| GET | /api/admin/comment/list | 全部评论 |
| DELETE | /api/admin/comment/delete/{id} | 删除任意评论 |
| GET | /api/admin/banner/list | 全部轮播图 |
| POST | /api/admin/banner/add | 添加轮播图（JSON body） |
| PUT | /api/admin/banner/update | 更新轮播图（JSON body） |
| DELETE | /api/admin/banner/delete/{id} | 删除轮播图 |
| PUT | /api/admin/banner/status | 切换轮播图状态 `params: id, status` |
| GET | /api/admin/form-card/list | 全部服务卡片 |
| POST | /api/admin/form-card/add | 添加卡片（JSON body） |
| PUT | /api/admin/form-card/update | 更新卡片（JSON body） |
| DELETE | /api/admin/form-card/delete/{id} | 删除卡片 |
| PUT | /api/admin/form-card/status | 切换卡片状态 `params: id, status` |

---

## 数据库

- 库名: `neushare`
- 初始化脚本: `sql/init.sql`（原 `neushare-backend/src/main/resources/db/init.sql`，随 Java 退役搬迁）
- 表: user, resource, category, comment, favorite, banner, form_card, resource_like, notification, follow, post, post_comment, post_like, post_favorite
- 预置种子数据：8 个用户（密码 BCrypt 加密，原始值见 init.sql）、12 个分类、14 个资源、17 条评论、12 条收藏、3 张轮播图、119 条课程链接

### JWT 拦截器公开路径

拦截器分两层（`WebMvcConfig`）：

1. 完全公开、无需识别身份：`/api/auth/login`、`/api/auth/register`、`/api/banner/list`、`/api/category/list`、`/api/form-card/current`、`/api/stats/overview`、`/api/resource/hot`、`/api/post/hot`、`/files/**`、`/error`
2. 公开但需要识别身份（`OptionalJwtInterceptor`，带有效 Token 时写入 `userId/username/role`，不带也放行）：`/api/resource/list`、`/api/resource/detail/**`、`/api/resource/search`、`/api/post/list`、`/api/post/detail/**`、`/api/comment/list/**`、`/api/post/comment/list/**`、`/api/user/*`、`/api/user/*/resources`

其他所有 `/api/**` 需要登录。`/api/admin/**` 额外需要 `role="admin"`。

### 公开接口安全加固

- `GET /api/resource/list` 和 `GET /api/post/list` 允许传入 `status` 参数但非管理员强制覆盖为 `1`
- `GET /api/user/{id}` 禁用用户返回错误
- 资源/帖子详情只对已发布内容公开，未发布内容仅作者与管理员可见（依赖第 2 层拦截器写入的身份）
- 普通用户编辑已通过审核的资源会重置为待审核（`status=0`）并清空驳回原因

---

## 前端路由（Web）

| 路径 | 组件 | 权限 |
|------|------|------|
| `/login` | Login | 游客（已登录重定向到 /） |
| `/register` | Register | 游客 |
| `/` | Home | 公开 |
| `/resource` | ResourceList | 公开 |
| `/resource/:id` | ResourceDetail | 公开 |
| `/user/:id` | UserProfile | 公开 |
| `/upload` / `/upload/:id` | Upload | 需登录 |
| `/profile/info` | ProfileInfo | 需登录 |
| `/profile/resources` | MyResources | 需登录 |
| `/profile/favorites` | MyFavorites | 需登录 |
| `/admin/dashboard` | Dashboard | 管理员 |
| `/admin/audit` | Audit | 管理员 |
| `/admin/users` | UserManage | 管理员 |
| `/admin/banners` | BannerManage | 管理员 |
| `/admin/cards` | FormCardManage | 管理员 |

> Vite 配置了 `@` 别名指向 `src/`（`vite.config.js`）。

---

## 鸿蒙端页面清单

来自 `entry/src/main/resources/base/profile/main_pages.json`（22 个页面）：

| 页面 | 说明 |
|------|------|
| `SplashPage` | 开屏页（品牌展示 + 自动跳转） |
| `LoginPage` / `RegisterPage` | 登录/注册 |
| `IdentityCardPage` | 身份卡片（年级设置 + 课程推荐） |
| `Index` | 主框架（侧边栏/底部Tab + 4 Tab 子页） |
| `HomeTab` / `CategoryTab` / `SearchTab` / `ProfileTab` | 首页/分类/搜索/我的（Index 子组件，非独立页面） |
| `CategoryPage` | 分类结果页 |
| `DetailPage` | 资源详情（含半模态评论面板） |
| `SearchPage` | 搜索结果页 |
| `ProfilePage` | 个人主页（编辑入口 + 粉丝/关注数） |
| `EditProfilePage` | 编辑个人资料 |
| `UserProfilePage` | 查看他人主页 |
| `UploadPage` | 上传资源 |
| `MyResourcesPage` | 我的资源 |
| `CommunityPage` | 学习社区（帖子列表 + 标签筛选） |
| `CreatePostPage` | 发帖/编辑帖子 |
| `PostDetailPage` | 帖子详情（全文 + 评论树） |
| `FollowListPage` | 关注/粉丝列表（Tab 切换） |
| `ModelComparePage` | AI 模型对比 |
| `PostgradGuidePage` | 考研指南 |
| `SchoolGuidePage` | 学院指南 |
| `WebViewPage` | 外部链接 WebView |
| `StatsPage` | 平台统计数据 |

---

## 关键修复记录

- **资源删除/更新**：增加所有者校验，非上传者且非管理员不可操作
- **点赞**：`resource_like` 表防重复刷赞，帖子同理（`post_like`）
- **审核驳回**：`resource` 表增加 `reject_reason` 字段
- **删除级联**：删除资源→清理评论/收藏/点赞；删除用户→清理全部关联；删除帖子→级联删除评论
- **搜索排序**：`sortBy=hot`（按 like_count DESC）或 `sortBy=new`（按 create_time DESC）
- **通知系统**：审核结果、评论回复、关注、收藏、点赞均推送通知；通知表含 `triggerUserId` LEFT JOIN 查昵称头像
- **关注**：`follow` 表唯一约束防重复关注
- **密码/JWT**：环境变量注入 `${DB_PASSWORD}`、`${JWT_SECRET}`
- **CORS**：限制为 `localhost` 来源，不使用通配符 `*`
- **定时校准**：每日凌晨 3 点校准 `like_count`、`favorite_count`、`comment_count`；冗余字段 `resource_count`/`follower_count`/`following_count`/`total_likes_received` 定时校准 + 实时原子更新
- **分类层级**：`category` 表增加 `parent_id` 支持父子分类
- **HttpClient 401**：Promise 锁替代 boolean 标志，防止并发 401 多次跳转；错误信息在跳转后保留
- **帖子评论计数**：删除评论时原子递减 `comment_count`（PostCommentServiceImpl）

---

## 已知问题 / 注意事项

- Dashboard 图表在无真实数据时显示"暂无数据"提示（已移除早先的演示数据）
- 文件上传目录在 `uploads/`，通过 `file.upload.path` 配置；上传扩展名走白名单（禁止 html/js/svg）
- 鸿蒙端基于 `window` API 做响应式（`mediaQuery`），不能用 `display` API（模拟器不可靠）
- 鸿蒙端离线缓存仍可改进（资源详情未缓存到本地 SQLite）
- `banner.js` 是公开轮播图 API 模块，Web 端首页 `Home.vue` 已接入（拉取失败回退本地 6 张图）；管理端在 admin.js 中

---

## 待处理问题清单（2026-11-14 联调反馈，已实测复核）

> 来自用户实际使用反馈，根因在本地运行环境验证过，修复前不要再仅凭口头描述改动。

### P0-1 资源无法下载 / 网页无法直接打开
证据：
- 后端无下载接口，只靠 `WebMvcConfig` 把 `uploads/` 映射为 `/files/**` 静态访问，无 `Content-Disposition`，浏览器默认内联而非下载。
- 前端 [ResourceDetail.vue](file:///d:/temp_20261114_01/_audit/NeuShare/neushare-frontend/src/views/ResourceDetail.vue) 只把 `contentUrl` 当纯文本展示，**没有下载按钮、没有预览链接**，actions 区只有点赞/收藏。
- `vite.config.js` 代理只配了 `/api`，**未代理 `/files`** → 经 3000 端口访问 `/files/xxx` 命中 Vite SPA 回退，返回 `index.html`（实测：`/files/probe.txt` 经 3000 返回 449 字节 = index.html；经 8080 直连返回 15 字节正确内容）。
- 种子数据 `content_url` 是 `test-math-notes.pdf` 等裸文件名，物理文件不在 `uploads/`（该目录原本不存在），链路通了也是 404。
修复方向（参考历史经验 506552 / 487672）：后端加鉴权下载接口（返回 `Content-Disposition: attachment`）；前端收敛成单一 `downloadFile` 封装（axios blob + `createObjectURL` + `a[download]`，响应拦截器对 blob/arraybuffer 分流保留完整 response）；`vite.config.js` 把 `/files` 纳入代理；统一 `buildFullUrl(path)` 工具，页面内禁止硬编码 host/port。

✅ 已修复（gh-fix / fix/phase2-audit）：
- 后端新增 `GET /api/resource/download/{id}`：本地文件以 `Content-Disposition: attachment; filename*=UTF-8''<标题+扩展名>` 流式输出；外链 302 跳转不占带宽；未发布仅本人/管理员可下（`WebMvcConfig` 已将该路径加入可选鉴权 `OPTIONAL_AUTH_PATHS`）。
- `ResourceVO` 增加瞬态 `fileExists`，`ResourceServiceImpl` 在分页/详情/搜索/热门/用户资源接口统一回填（外链视为存在，本地查 `uploads/` 物理文件，含路径穿越防御）。
- 前端 `request.js` 响应拦截器对 `blob`/`arraybuffer` 保留完整 response；新增 `src/utils/url.js`（`buildFullUrl`/`isPreviewable` 等）与 `src/api/resource.js` 的 `downloadResource`（按 `content-type` 区分 JSON 错误与真实文件，错误时提示而非下载 JSON blob）。
- `vite.config.js` 增加 `/files` 代理（修掉经 3000 命中 SPA 回退返回 index.html 的 bug）。
- `ResourceDetail.vue` 增加「在线预览 / 下载资料」按钮、外链「访问原链接」、`fileExists===false` 时渲染「文件已丢失」空态。
- 启动时 `com.neushare.bootstrap.ResourceFileSeeder` 自动为种子资源补齐 `uploads/` 占位文件，开箱即可下载/预览（幂等，不覆盖已存在文件）。
- 验证：后端 `mvn test` 通过；`detail/1` 返回 `fileExists=true`；`download/1` 返回 attachment 中文文件名 477 字节；上传→下载 e2e 内容一致；经 3000 代理 `/api`、`/files`、`/download` 均通。

### P0-2 空资源 / 垃圾资源
证据：
- 种子数据 115 条资源**全部 `cover_url` 为空**；3 条 `status!=1`；`content_url` 指向不存在的演示文件名 → 列表里点进去是空壳。
- [ResourceController.createResource](file:///d:/temp_20261114_01/_audit/NeuShare/neushare-backend/src/main/java/com/neushare/controller/ResourceController.java#L71) 未携带文件时不拦截，`ResourceDTO` 未校验 `contentUrl`/`title` 非空 → 可产生无文件资源。
- 无"文件是否真实存在"校验；删除资源不删物理文件，可能留孤儿文件。
修复方向：DTO 加 `@NotBlank`（创建时）/ 上传必填校验；审核态拒绝空文件；列表/详情对缺失文件给出明确"文件已丢失"态而非空壳；删除资源级联删物理文件；清理种子数据里指向不存在文件的记录或补齐真实文件。

✅ 已修复：`ResourceServiceImpl.createResource` 拒绝 `contentUrl` 为空（无文件且无外链 → 400「请上传资源文件或填写资源链接」）；`auditResource` 通过审核前校验物理文件存在，缺失则拒绝；`deleteResource` 级联删除本地物理文件（外链跳过，失败不阻断 DB 删除）；`fileExists` 回填 + 前端「文件已丢失」空态；`ResourceFileSeeder` 补齐种子占位文件。验证：无文件创建返回 400；仅外链创建成功（验证"或链接"分支）；删除测试资源级联成功。

### P1-3 Web 与鸿蒙端数据不互通
证据：
- 鸿蒙端后端地址**硬编码** `http://10.0.2.2:8080`：`common/.../network/HttpClient.ets:5`、`AuthStore.ets:7`、`DetailPage.ets:18`（`FILE_BASE_URL`）、`PostDetailPage.ets:13`。
- `10.0.2.2` 是模拟器访问宿主机的别名，**真机 / DevEco PC 预览连不上** → 表现为"数据不互通"。这不是数据模型分裂（两端 API 路径一致，地址通了就能共享），是地址不可配置。
- Web 端写死 `localhost`，鸿蒙写死 `10.0.2.2`，两套都不可在运行时切换。
修复方向：后端地址改为运行时可配置（`BuildProfile` 环境变量 / 设置页 / `common` 常量集中管理 + 一处切换）；DevEco 预览与真机分别指向宿主机局域网 IP；明确文档说明三种运行场景（模拟器 / 真机 / 本地 Web）的地址配置。

✅ 已修复：新增 `common/src/main/ets/config/AppConfig.ets` 集中导出 `BASE_URL` / `FILE_BASE_URL`（含模拟器 `10.0.2.2` / 真机局域网 IP / 线上域名三种场景的切换说明），并从 `common/Index.ets` 导出；`HttpClient.ets`、`AuthStore.ets`、`DetailPage.ets`、`PostDetailPage.ets` 改为引用该常量，删除各自硬编码；`ResourceService` 离线兜底 banner 图地址归一化为当前 `BASE_URL`；`LoginPage` 错误提示去掉硬编码地址。全仓库 `10.0.2.2` 仅剩 `AppConfig.ets` 中作为文档化默认值。注：本地无 DevEco，未构建 HAP，改动为静态源码级。

### P2-4 不够便捷（需与用户进一步确认具体痛点）
已关联：无下载/预览入口（并入 P0-1）。其余如搜索直达、批量操作、上传后即时可见等，待用户补充具体场景后再拆。

---

## 资源数据核实与对版修复（2026-11-14 第二轮）

> 背景：用户反馈「资源质量低、大多数不对版、后端没有前端展示的这些资源信息」。本轮在 gh-fix 已修复下载/互通链路的基础上，逐一对**数据本身**核实并修复。演示库在独立 MySQL 实例（端口 3307，datadir `D:\temp_20261114_01\_mysql_demo`，root 密码 `<从 .env 读取>`）。

### 核实出的问题（均附证据）
1. **死链**：`id9` 指向 `example.com/files/python-data.mp4`（保留域名，必 404）。全量探测 94 条外链仅此 1 条真死链；`id24` 的 429 是批量探测触发的限频（hello-algo.com 真实存在）。
2. **同 BV 号多标题不对版**：`BV1aW411Q7x1`（实为宋浩线代）被 `id53` 标成「惊叹号系列」；`BV15b4y1a7yG`（实为黑马 SpringBoot2）被 `id12` 标成「Vue3 项目实战」。用 B 站官方 API `api.bilibili.com/x/web-interface/view?bvid=` 核实真实标题确认。
3. **全量无封面**：113 条资源 `cover_url` 全 NULL → 列表/详情无封面。
4. **banner 图缺失**：DB 引用 `校园学习.png` 等 4 张图，`uploads/` 不存在 → 轮播裂图。
5. **后端端口不对版**：`application.yml` 写 3306，实际演示库在 3307 → 后端连不上库。
6. **Web 轮播不走后端**：`Home.vue` 用本地 6 张 `localImages`，不调 `/api/banner/list`。
7. **鸿蒙本地兜底两套**：`resources.json`/`categories.json`/`banners.json` 与后端完全不一致（鸿蒙本地是 5 个分类「网课/书籍/开源/软件/考研」，后端是 12 个课程分类；资源 id/标题/分类全对不上）。

### 已修复
- **R1 链接对版**：`id9`→`BV1DtRvBpE5R`（Python 数据分析，API 验证 code=0 存在）；`id12`→`BV1CvhWzvE6j`（黑马 Vue3 实战，验证存在，同时从待审核 status=0 发布为 1）；`id53`→`BV19a8DztE1M`（北航李尚志线代，标题改为「《线性代数》启蒙-北航李尚志」）。
- **R2 封面**：43 条 B 站视频用官方 API 抓真实缩略图存 `uploads/cover-{id}.jpg`；其余 70 条（含 6 条 API 受限视频 + 4 条非 B 站视频 + 59 条文档/教程）按 `category_id` 分配 12 张分类封面。113 条 `cover_url` 全部回填，0 空封面。
- **R3 banner 图**：生成 `校园学习.png`/`网课学习.png`/`计算机专业学习.png`/`AI大模型.png` 放入 `uploads/`，文件名与 DB `image_url` 完全一致。
- **R5 端口**：`application.yml` `jdbc:mysql://localhost:3306` → `3307`。
- **R4 Web 轮播接后端**：`Home.vue` 改为 onMounted 调 `getBannerList()`，拉取失败回退本地 6 张；后端返回的绝对图地址归一化为相对路径走 Vite 代理。
- **R6 鸿蒙兜底对齐**：用 MySQL `JSON_ARRAYAGG` 从 DB 导出真实数据，覆盖 `entry/src/main/ets/data/{resources,categories,banners}.json`，schema 匹配前端展示模型（`ResourceItem`/`CategoryItem`/`BannerItem`）。113 条资源 / 12 分类 / 4 banner 全部对齐。

### 验证结果（端到端实测）
- 后端 `mvn clean package -DskipTests`（IntelliJ 自带 Maven 3.9.9 + JDK 17）构建成功；`java -jar` 启动连 3307 正常。
- `/api/banner/list` 返回 4 条；`/files/cover-cat-1.jpg` 200 image/jpeg；`/api/resource/list` 返回带 `coverUrl` 且 `fileExists=true` 的记录。
- Playwright 打开 `http://localhost:3000`：首页轮播 `slideCount===4`（确认走后端而非本地 6 张兜底），热门/最新资料卡片封面正常渲染，控制台仅 Vite 连接日志、无报错。
- 下载：`/api/resource/download/1`（本地文件）返回 200 + `Content-Disposition` 正确 UTF-8 中文文件名；`/api/resource/download/9`（外链）返回 302 → 修复后的 B 站链接。
- 全量 55 张封面图 + 4 张 banner 图经 HTTP 探测全部 200，无裂图。
- `ResourceFileSeeder` 启动后未再生 `test-*` 占位垃圾文件（20 个真实文件已存在，幂等不覆盖）。

### 失败尝试与实验证据（保留记录）
1. **`text_to_image` HTTP 接口不可直接用**：`GET https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?...` 立即返回的是占位图（"The image is generating..."，固定 176626 字节），重复刷新同一 URL 仍为占位图——真实生成由 MCP `GenerateImage` 异步封装，裸 HTTP 拿不到成品。**改用 .NET `System.Drawing` 本地绘制**（渐变底 + 粗体中文标题 + 装饰圆点/圆环），100% 可靠、无外部依赖。
2. **6 条 B 站视频抓不到缩略图**：`id 35/60/63/74/80/83` 的 `view` API 返回 `62002`/`62012`/`-404`（需登录 / 区域限制，元数据不公开），但视频页面本身可达。**这 6 条直接用分类封面兜底**，未硬啃 B 站 wbi 签名。
3. **MySQL `JSON_ARRAYAGG(... ORDER BY id)` 语法不支持**：本机 MySQL 8.0 报 1064。**改用有序子查询 + `LIMIT 1000000` 强制排序**后聚合。另脚本里 `2>$null` 曾吞掉报错导致静默失败，后改为显式捕获输出判空。
4. **PowerShell 5 中文脚本编码**：无 BOM 的 `.ps1` 用 `-File` 运行时按 ANSI 解码，中文字符串变乱码（导致 2 张中文文件名 banner 创建失败）。**给脚本加 UTF-8 BOM** 后正常。
5. **Playwright 浏览器版本不匹配**：MCP 期望 `chromium_headless_shell-1200`，`npx playwright install` 装的是 `1243`。**创建目录联接（junction）`1200 → 1243`** 后浏览器正常启动。

---

## 资源数据深度对版核查与修复（2026-11-14 第三轮，R7）

### 背景
第二轮 R1 只修了 `id9/id12/id53` 三条明显错链。用户反馈「大多数资源不对版」，故对全部 B 站外链做**逐条 API 取真实标题比对**的深度核查，发现仍有 7 条 `content_url` 指向与标题完全无关的视频（数据层错配，前端下载/跳转都会带用户到错误内容）。

### 发现的问题（R7）
对 50 条 `content_url LIKE '%bilibili.com%'` 的资源，逐条调 `https://api.bilibili.com/x/web-interface/view?bvid=` 取真实 `data.title`，与 DB 标题比对。结果：
- 44 条对版（Y）
- 6 条 API 受限（`id 35/60/63/74/80/83`，返回 `62002/62012/-404`，需登录/区域限制，但页面可达，沿用第二轮分类封面兜底）
- **7 条完全错配**（真实标题与 DB 标题无关，如 `id25`「计算机组成原理-王道考研」的 BV 实际是《九转大肠》纪录片）—— 用 Playwright 浏览器加载 `BV1ps4y1x7Hx` 实证 `document.title` 确为「大型记录片《九转大肠》传奇持续为你播出」，排除了 API 限频返回脏数据的可能。

错配清单：`id23 / id25 / id36 / id45 / id56 / id58 / id84`。

### 已修复（R7）
用 B 站搜索 API（`search/all?keyword=...&order=click`，**无需 wbi 签名即可返回候选**）按播放量排序找对版视频，再用 `view` API 二次验证 `code=0` + 标题对版 + 取真实缩略图，最终映射：

| id | DB 标题 | 旧 BV（错） | 新 BV（对） | 新封面 |
|----|---------|------------|------------|--------|
| 23 | LeetCode热题100 Java版 | BV1wM4y1U7bK | BV1rU4y187jp | cover-23.jpg |
| 25 | 计算机组成原理微课堂-湖科大教书匠 | BV1ps4y1x7Hx | BV1qG41197E4 | cover-25.png |
| 36 | 前端三件套-HTML/CSS/JS入门 | BV1vY4y1W7cN | BV1BT4y1W7Aw | cover-36.png |
| 45 | 考研408计算机专业基础综合 | BV1Fp4y1W7tK | BV1LM41177Pz | cover-45.png |
| 56 | C语言程序设计-浙大翁恺 | BV1s4411U7sN | BV1dr4y1n7vA | cover-56.jpg |
| 58 | 小甲鱼《带你学C带你飞》C语言入门教程 | BV11s41167h6 | BV17s411N78s | cover-58.jpg |
| 84 | 黑马程序员pink老师前端入门(HTML5+CSS3) | BV1p84y1P7cW | BV14J4114768 | cover-84.jpg |

- `id25` 改选湖科大微课堂（避开与已存在的 `id66` 王道计组 `BV1ps4y1d73V` 重复），并同步改了标题与描述。
- `id58/id84` 标题改为与真实视频一致；`id23/25/36/45/56/84` 的 DB `description` 同步更新为与真实内容对版（Web 端详情页读 DB 描述，原先仍写「王道」等旧描述）。
- 7 张真实封面下载到 `uploads/`（其中 3 张为 `.png`，按真实扩展名命名，`cover_url` 对应写对，避免 404）；删除孤儿旧封面 `cover-25.jpg`、`cover-36.jpg`。
- 鸿蒙 `entry/src/main/ets/data/resources.json` 同步更新这 7 条的 `url/title/cover/description/source`（仅改 7 条，保留其余 curated 字段；总数仍 113）。

### 验证结果
- 重跑全量 BV 对版核查：**44 对版 / 6 受限 / 0 错配 / 0 错误**（`bv-check-result.tsv` 的 CHECK 区为空）。
- API：`/api/resource/detail/25` 返回新标题+新链接+新描述；`/api/resource/list` 7 条 `coverUrl` 正确且 `fileExists=true`。
- 下载：`download/25`→302 `BV1qG41197E4`、`download/56`→302 `BV1dr4y1n7vA`、`download/84`→302 `BV14J4114768`，全部跳转正确。
- 封面 HTTP：7 张新封面（含 3 张 png）全部 200；全库 113 条 `cover_url` 与 `uploads/` 物理文件一致性扫描 **0 缺失**（无裂图）。
- 浏览器：首页轮播 `slideCount=4`（走后端）、资源广场「共 112 份资料」卡片渲染、`/resource/25` 详情页标题/链接/描述均为修复后内容，控制台无报错。
- 注意：Web 前端目前**不渲染资源封面图**（`coverUrl` 仅鸿蒙端与管理端使用；grep 前端 `coverUrl` 仅 `Home.vue` 用于 banner），故封面修复的数据正确性通过 HTTP/文件层验证，鸿蒙端因无 DevEco 环境仅做静态源码级对齐。

### 新增失败尝试与实验证据
1. **`mysql -e` 不带库名报 1046**：`UPDATE resource SET ...` 未指定库也未传 `neushare` 位置参数 → `ERROR 1046 (3D000) No database selected`，且 `2>$null` 吞掉了报错导致静默失败（行未变）。**解决**：命令末尾加 `neushare` 位置参数（或表名加 `neushare.` 前缀），并去掉 `2>$null` 先看真实报错。
2. **`curl` 抓 B 站视频页被风控**：直接 `curl` `https://www.bilibili.com/video/BVxxx` 只返回 394 字节风控页，拿不到 `<title>`。**解决**：用 `view` API 取标题更可靠（对公开视频 `code=0` 返回真实 `data.title`），或用 Playwright 真实浏览器加载读 `document.title` 做铁证。
3. **B 站搜索 API 无需 wbi**：`https://api.bilibili.com/x/web-interface/search/all?keyword=...&order=click` 带普通 UA + Referer 即可返回 `code=0` 的候选列表（含 `bvid/title/play/author`），可直接用于找对版视频，不必硬啃 wbi 签名。

---

## 新增 2 条 C 语言优质课程（2026-11-14，接续 R7）

### 背景
R7 修完 7 条错配后，用户提供 B 站截图，要求新增两门 C 语言优质课程入库。先经 `view` API 核实两条 BV 真实存在、且标题/播放量/UP 主与截图完全吻合（`code=0`），再出计划、经用户确认后执行。

### 核实到的两条（均 API `code=0` 验证）
| id（新） | 课程 | BV 号 | UP 主 | 播放量 | 封面 pic |
|----|------|-------|-------|--------|------|
| 118 | C语言程序设计从入门到进阶【鹏哥C语言2026最新官方完整版】 | `BV17a7K64ELH` | 鹏哥C语言 | 370万 | `1dd33cd52a9f694ee06caa8d931cc94ee346a65f.jpg` |
| 119 | 黑马程序员C语言零基础入门到精通全套视频教程 | `BV1Xa4y1k7LU` | 黑马程序员 | 722万 | `3499ed831caec14e273ac16ef96bc969b62c5da9.jpg` |

### 执行
- 插库 `neushare.resource`：两条均 `category_id=3`（程序设计基础(C语言)）、`type='video'`、`upload_user_id=6`（王老师/T20240001，与现有视频资源一致）、`status=1`、`source`=UP 主名、`content_url`=对应 BV 链接、`description` 用 API 真实简介精简、`tags` 分别为 `["C语言","零基础","考研"]` / `["C语言","零基础","嵌入式"]`。
- 实际新 id = **118、119**（表自增值高于 `MAX(id)=115`，以实际 `LAST_INSERT_ID()` 为准，非预期的 116/117）。
- 下载 2 张真实封面到 `uploads/cover-118.jpg`（243066 B）、`uploads/cover-119.jpg`（68352 B），回填 `cover_url`。
- **格式对齐修正**：现有 113 条 `cover_url` 在 DB 中存的是**带 `/files/` 前缀**（如 `/files/cover-cat-1.jpg`），首次回填误存为裸名 `cover-118.jpg`，已修正为 `/files/cover-118.jpg` / `/files/cover-119.jpg`，与全库一致。
- 鸿蒙 `entry/src/main/ets/data/resources.json`：数组末尾追加 2 条，按现有 schema 填全字段（`url`=BV 链接、`cover`=`/files/cover-{id}.jpg`、`author`="王老师"、`rating`=0、`publishDate`="2026-06"、`uploadAvatar`=""），总数 113→115。

### 验证结果（端到端实测）
- JSON：`resources.json` 合法，`count=115`，118/119 字段正确。
- API：`/api/resource/list?sortBy=new` 中 118/119 排在最前，`coverUrl` 带 `/files/` 前缀、`fileExists=true`；`/api/resource/detail/118`、`/detail/119` 标题/链接/描述正确；列表 `total=114`（115 条中 1 条预存未发布，两条新资源均已发布）。
- 封面 HTTP：`/files/cover-118.jpg`、`/files/cover-119.jpg` 均 200 image/jpeg，尺寸与下载文件一致。
- 下载：`/api/resource/download/118`→302 `BV17a7K64ELH`、`download/119`→302 `BV1Xa4y1k7LU`，跳转正确。
- 全库一致性：115 条 `cover_url` 与 `uploads/` 物理文件扫描 **0 缺失**。
- 浏览器：Playwright 打开 `/resource/118`、`/resource/119`，标题/分类（程序设计基础(C语言)）/描述/外部链接「访问原链接」均渲染正确，无业务报错。

### 新增失败尝试与实验证据
1. **新资源 id 非预期 116/117**：`MAX(id)=115` 但表自增值已跑到 118，实际插入得到 118、119。**结论**：新增资源必须以 `LAST_INSERT_ID()`/`SELECT MAX(id)` 的实际值回填封面文件名，不能靠猜测，否则 `cover-{id}` 会与物理文件错位。
2. **`cover_url` 前缀不一致**：首次全扫描报 113 条 "missing"，根因是扫描脚本未剥 `/files/` 前缀就拼物理路径（`uploads//files/...` 不存在），并非真缺失；同时暴露首次给 118/119 存的是裸名、与全库 `/files/` 前缀不一致。**解决**：统一存 `/files/cover-{id}.jpg`，扫描时去前缀再 `Test-Path`，最终 0 缺失。
