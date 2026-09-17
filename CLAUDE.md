# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# NeuShare — 校园资料分享平台

## 项目概览

东北大学（NEU）学习资料分享平台。学生/教师可上传、搜索、浏览、评论、点赞、收藏课程资料。管理员审核资料、管理用户和轮播图。

三端架构：**Vue 3 Web 前端** + **Spring Boot 3 后端** + **HarmonyOS NEXT 移动端**

---

## 技术栈

| 层 | 技术 |
|---|------|
| Web 前端 | Vue 3 (Composition API `<script setup>`), Vite 5, Element Plus 2.6, Pinia, Vue Router 4, Axios, ECharts 5 |
| 后端 | Spring Boot 3.3.7, MyBatis-Plus 3.5.13, MySQL 8, JWT (jjwt 0.13.0), BCrypt |
| 移动端 | HarmonyOS NEXT API 22, ArkUI + ArkTS, 双模块 HAR 架构 |
| 构建 | Maven (backend), npm/vite (frontend), DevEco Studio (HarmonyOS) |

---

## 常用命令

```bash
# Web 前端
cd neushare-frontend
npm install && npm run dev      # → localhost:3000，API 代理到 localhost:8080
npm run build                   # 生产构建 → dist/
npm run preview                 # 预览生产构建

# 后端 (JDK 17+)
cd neushare-backend
mvn spring-boot:run              # → localhost:8080
mvn test                         # 运行测试
mvn package                      # 打包 JAR → target/

# 数据库初始化
# 1. 确保 MySQL 8 运行中
# 2. 执行 neushare-backend/src/main/resources/db/init.sql 建库+建表+种子数据

# 鸿蒙 App
# DevEco Studio 打开项目根目录 → Sync → Run
```

---

## 目录结构

```
NeuShare/
├── neushare-frontend/          # Vue 3 Web 前端
│   └── src/
│       ├── api/                # Axios 请求模块: auth, resource, comment, favorite, follow, notification, user, admin, banner, request
│       ├── components/         # Header, Footer, ResourceCard, Sidebar
│       ├── router/index.js     # Vue Router + beforeEach 守卫
│       ├── store/modules/      # Pinia 用户状态（token, userInfo）
│       ├── styles/global.css   # CSS 变量、重置、动画
│       ├── utils/              # constants, format, courseData
│       └── views/              # Home, ResourceDetail, Upload, Login/Register, UserProfile + profile/ + admin/
│
├── neushare-backend/           # Spring Boot 后端
│   └── src/main/java/com/neushare/
│       ├── controller/         # 14 个 REST 控制器（见下方 API 清单）
│       ├── service/            # 业务接口 + impl 实现
│       ├── mapper/             # MyBatis-Plus BaseMapper + 自定义 XML
│       ├── entity/ dto/ vo/    # 数据对象
│       ├── config/             # CORS, 分页, WebMvcConfig（拦截器注册）
│       ├── interceptor/        # JwtInterceptor（JWT 校验 + 管理员权限）
│       ├── task/               # CounterCalibrationTask（计数器定时校准）
│       └── util/               # JwtUtil, BCryptUtil, FileUploadUtil
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

// Components
export { EmptyState }           // 空状态占位组件（呼吸动画）

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
- 初始化脚本: `neushare-backend/src/main/resources/db/init.sql`
- 表: user, resource, category, comment, favorite, banner, form_card, resource_like, notification, follow, post, post_comment, post_like, post_favorite
- 预置种子数据：8 个用户（密码 BCrypt 加密，原始值见 init.sql）、12 个分类、14 个资源、17 条评论、12 条收藏、3 张轮播图、119 条课程链接

### JWT 拦截器公开路径

```
/api/auth/login, /api/auth/register, /api/resource/list, /api/resource/hot,
/api/resource/detail/**, /api/resource/search, /api/banner/list,
/api/comment/list/**, /api/category/list, /api/form-card/current,
/api/post/list, /api/post/detail/**, /api/post/hot, /api/post/comment/list/**,
/api/stats/overview, /api/user/*, /api/user/*/resources
```

其他所有 `/api/**` 需要登录。`/api/admin/**` 额外需要 `role="admin"`。

### 公开接口安全加固

- `GET /api/resource/list` 和 `GET /api/post/list` 允许传入 `status` 参数但非管理员强制覆盖为 `1`
- `GET /api/user/{id}` 禁用用户返回错误

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

- Dashboard 的图表在无真实数据时使用硬编码演示数据
- 文件上传目录在 `uploads/`，通过 `file.upload.path` 配置
- 鸿蒙端基于 `window` API 做响应式（`mediaQuery`），不能用 `display` API（模拟器不可靠）
- 鸿蒙端离线缓存仍可改进（资源详情未缓存到本地 SQLite）
- `banner.js` 是公开轮播图 API 模块，但 Web 端目前无组件使用（功能在 admin.js 中）
