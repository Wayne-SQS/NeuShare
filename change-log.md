# NeuShare 修改记录

---

# 阶段一：数据桥接

> 日期：2026-06-07
> 目标：鸿蒙 App 数据源从本地 JSON 切换到后端 API，保留本地 JSON 作为离线 fallback

---

## 修改总览

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `common/src/main/ets/network/HttpClient.ets` | 添加查询参数支持方法 | ✅ |
| 2 | `entry/src/main/ets/models/ResourceModel.ets` | 新增后端 VO 模型和适配函数 | ✅ |
| 3 | `entry/src/main/ets/api/ResourceApi.ets` | 修正 pageNum，添加分类/搜索 API | ✅ |
| 4 | `entry/src/main/ets/api/CommentApi.ets` | add() 改为 URL 参数，username→nickname | ✅ |
| 5 | `entry/src/main/ets/api/FavoriteApi.ets` | add() 改为 URL 参数，getList 添加分页，check 返回 isFavorite | ✅ |
| 6 | `entry/src/main/ets/api/AuthApi.ets` | changePassword() 改为 URL 参数 | ✅ |
| 7 | `entry/src/main/ets/services/ResourceService.ets` | 改为异步 API 调用 + 本地 fallback | ✅ |
| 8 | `entry/src/main/ets/services/FavoriteService.ets` | 改为 API 调用 + 本地缓存 | ✅ |
| 9 | `entry/src/main/ets/pages/Index.ets` | 异步加载分类/轮播图/资源 | ✅ |
| 10 | `entry/src/main/ets/pages/CategoryPage.ets` | 改为后端分页加载 | ✅ |
| 11 | `entry/src/main/ets/pages/SearchPage.ets` | 改为后端搜索 API | ✅ |
| 12 | `entry/src/main/ets/pages/DetailPage.ets` | 资源详情和收藏改为后端 API | ✅ |
| 13 | `entry/src/main/ets/pages/ProfilePage.ets` | 收藏列表改为后端 API | ✅ |
| 14 | `entry/src/main/ets/components/ResourceCard.ets` | 适配后端模型，tags 空值保护，显示 likeCount | ✅ |
| 15 | `entry/src/main/ets/pages/tabs/HomeTab.ets` | getAllResources→getLocalResources，tags 空值保护 | ✅ |

> 注：BannerSwiper.ets 和 CategoryCard.ets 无需修改，因为适配函数已在 ResourceModel.ets 中处理了字段映射。

---

## 详细修改记录

### 1. HttpClient.ets

**改动**：
- 新增 `buildQueryString()` 私有方法，将 params 对象拼接为 URL 查询字符串
- `get()` 方法新增可选 `params` 参数，支持 `Record<string, string | number | boolean>`
- 新增 `postWithParams()` 方法：POST 请求参数通过 URL 查询字符串传递（后端 `@RequestParam`）
- 新增 `putWithParams()` 方法：PUT 请求参数通过 URL 查询字符串传递（后端 `@RequestParam`）

**原因**：后端大量使用 `@RequestParam`，前端必须用 URL 参数而非 JSON body。

### 2. ResourceModel.ets

**改动**：
- `ResourceItem` 新增 `likeCount`, `viewCount`, `uploadAvatar` 字段
- `ResourceItem.type` 从联合类型改为 `string`（后端类型不固定）
- 新增 `ResourceVO` 接口（后端资源返回格式）
- 新增 `CategoryVO` 接口（后端分类返回格式，`name` 而非 `title`）
- 新增 `BannerVO` 接口（后端轮播图返回格式，`linkUrl` 而非 `linkValue`）
- 新增 `adaptResource()` 函数：ResourceVO → ResourceItem，处理字段名映射和 tags 字符串→数组转换
- 新增 `adaptCategory()` 函数：CategoryVO → CategoryItem，`name→title`，自动生成 `color/icon`
- 新增 `adaptBanner()` 函数：BannerVO → BannerItem，`linkUrl→linkValue`，自动生成 `emoji/gradient`

### 3. ResourceApi.ets

**改动**：
- `ResourceListParams.page` → `pageNum`（匹配后端参数名）
- `ResourceListParams` 新增 `status` 可选参数
- `getList()` 改用 `HttpClient.get(path, params)` 传参
- `getDetail()` 返回类型改为 `ResourceVO`
- `getHot()` 返回类型改为 `ResourceVO[]`
- `search()` 简化为只传 `keyword`（后端搜索 API 不支持分页）
- 新增 `getCategories()` 方法调用 `/api/category/list`
- `getUserResources()` 返回类型改为 `ResourceVO[]`
- `ResourceListResult.records` 类型改为 `ResourceVO[]`

### 4. CommentApi.ets

**改动**：
- `add()` 改用 `postWithParams()` 传 URL 参数（后端 `@RequestParam`）
- `CommentItem.username` → `nickname`（匹配后端 CommentVO 字段名）
- 移除重复的 `CommentBody` 接口

### 5. FavoriteApi.ets

**改动**：
- `add()` 改用 `postWithParams()` 传 URL 参数（后端 `@RequestParam`）
- `check()` 返回类型改为 `{ isFavorite: boolean }`（匹配后端返回字段名）
- `getList()` 新增 `pageNum` 和 `pageSize` 参数，返回分页结果 `FavoriteListResult`
- 新增 `FavoriteItem` 接口包含 `resource: ResourceVO` 字段
- 新增 `FavoriteListResult` 分页接口

### 6. AuthApi.ets

**改动**：
- `changePassword()` 改用 `putWithParams()` 传 URL 参数（后端 `@RequestParam`）
- 移除 `PasswordBody` 接口

### 7. ResourceService.ets（核心改造）

**改动**：
- 原有同步方法重命名为 `getLocal*`（如 `getCategories` → `getLocalCategories`）
- 新增 `fetchCategories()`：API 优先，失败 fallback 本地，带缓存
- 新增 `fetchBanners()`：API 优先，失败 fallback 本地，带缓存
- 新增 `fetchResourcesByCategory()`：API 优先，失败 fallback 本地
- 新增 `fetchResourceDetail()`：API 优先，失败 fallback 本地
- 新增 `searchResources()`：API 优先，失败 fallback 本地
- 新增 `checkFavorite()`：调用 FavoriteApi.check()
- `fetchHotResources()` 改为返回 `ResourceItem[]`（通过 adaptResource 转换）
- 引入 `BannerApi` 依赖

### 8. FavoriteService.ets

**改动**：
- 新增 `FavoriteApi` 和 `AuthStore` 依赖
- `getFavoriteIds()`：登录时从 API 获取，未登录/失败用本地
- `toggleFavorite()`：登录时调 API，成功后同步本地缓存；未登录/失败用本地
- `isFavorite()`：登录时调 API check，未登录/失败用本地
- 新增 `getFavoriteResources()`：从 API 分页获取收藏列表（含资源详情）
- 新增 `saveLocalFavoriteIds()` 私有方法同步本地缓存

### 9. Index.ets

**改动**：
- `aboutToAppear()` 先加载本地数据，再调 `refreshFromApi()` 异步更新
- 新增 `refreshFromApi()` 方法：并行获取分类和轮播图，更新 UI
- `onPageShow()` 也调 `refreshFromApi()` 确保数据最新

### 10. CategoryPage.ets

**改动**：
- `aboutToAppear()` 先加载本地数据，再调 `loadFromApi()` 异步更新
- 新增 `isLoading` 和 `totalCount` 状态
- 新增 `loadFromApi()` 方法：从后端分页获取分类资源
- `checkFilters()` 和 `getFilteredResources()` 添加 `tags` 空值保护

### 11. SearchPage.ets

**改动**：
- `aboutToAppear()` 使用 `getLocalAllTags()` 加载热门标签
- `searchByTag()` 和 `onSearch()` 改为 async
- 新增 `doSearch()` 方法：调用 `resourceService.searchResources()`（API 优先）
- 新增 `isSearching` 状态

### 12. DetailPage.ets

**改动**：
- `aboutToAppear()` 先从本地加载，再调 `loadDetailFromApi()` 异步更新
- 新增 `loadDetailFromApi()` 方法
- `toggleFavorite()` 简化为只调 `favoriteService.toggleFavorite()`（已内置 API 同步）
- `tags.length > 0` 添加空值保护 `tags && tags.length > 0`

### 13. ProfilePage.ets

**改动**：
- `loadData()` 改用 `favoriteService.getFavoriteResources()` 从 API 获取收藏
- 如果 API 未返回资源详情，用本地数据补充
- `tags.some()` 添加空值保护
- `getAllResources()` → `getLocalResources()`
- `getResourceById()` → `getLocalResourceById()`

### 14. ResourceCard.ets

**改动**：
- `tags.slice(0, 3)` 添加空值保护 `tags && tags.length > 0`
- 新增 `likeCount` 显示（👍 + 数字）
- 评分和点赞数并排显示

### 15. HomeTab.ets

**改动**：
- `getAllResources()` → `getLocalResources()`
- `tags.some()` 添加空值保护

---

## 数据流变化

### 改前
```
页面 → ResourceService.getLocal*() → 本地 JSON 文件
页面 → FavoriteService (PreferencesStore) → 本地存储
```

### 改后
```
页面 → ResourceService.fetch*() → 后端 API → 成功返回
                                    ↓ 失败
                                  本地 JSON fallback

页面 → FavoriteService → 已登录 → 后端 API → 成功返回 + 同步本地缓存
                        ↓ 未登录/失败
                        本地 PreferencesStore
```

---

## 未修改的文件（后端无 API / 纯本地功能）

- `CurriculumService.ets` / `curriculum.json` — 课程推荐
- `CommunityService.ets` / `CommunityPage.ets` / `CreatePostPage.ets` — 社区帖子
- `PostgradGuidePage.ets` / `postgrad.json` — 考研指南
- `ModelComparePage.ets` / `ModelCompare.ets` / `modelPrices.json` — AI 模型对比
- `IdentityCardPage.ets` — 引导页
- `SplashPage.ets` — 启动页
- `LoginPage.ets` / `RegisterPage.ets` — 已对接 API
- `EditProfilePage.ets` — 已对接 API
- `FollowApi.ets` / `UserProfilePage.ets` — 后端无关注 API
- `BannerSwiper.ets` / `CategoryCard.ets` — 通过适配函数间接兼容

---

# 阶段二：统一认证 + 收藏同步

> 日期：2026-06-07
> 目标：Token 过期自动处理、登录后本地收藏合并到云端、401 自动跳转登录页

---

## 修改总览

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `common/src/main/ets/network/AuthStore.ets` | 添加 validateToken() 方法 | ✅ |
| 2 | `entry/src/main/ets/pages/SplashPage.ets` | 启动时验证 Token 有效性 | ✅ |
| 3 | `common/src/main/ets/network/HttpClient.ets` | 401 响应自动跳转登录页 | ✅ |
| 4 | `entry/src/main/ets/services/FavoriteService.ets` | 登录后本地收藏合并到云端 | ✅ |
| 5 | `entry/src/main/ets/pages/LoginPage.ets` | 登录成功后触发收藏合并 | ✅ |

---

## 详细修改记录

### 1. AuthStore.ets

**改动**：
- 新增 `validateToken()` 方法：调用 `/api/auth/info` 验证 Token 是否有效
  - Token 有效：更新本地用户信息，返回 `true`
  - Token 无效（code !== 200）：清除 token 和用户信息，返回 `false`
  - 网络错误：保留 token（可能离线），返回 `true`
- 引入 `http` 模块直接请求（不依赖 HttpClient，避免循环依赖）
- 硬编码 `BASE_URL = 'http://10.0.2.2:8080'`

**原因**：之前只检查 token 是否存在，不验证是否过期。用户 token 过期后仍显示"已登录"状态但所有 API 调用失败。

### 2. SplashPage.ets

**改动**：
- `goNext()` 中，检测到已登录后调用 `authStore.validateToken()` 验证
- Token 有效 → 跳转 Index（主页）
- Token 无效 → 跳转 LoginPage（重新登录）

**原因**：启动时验证 Token，避免用户进入主页后才发现 token 过期。

### 3. HttpClient.ets

**改动**：
- 引入 `router` 模块（`@ohos.router`）
- 新增 `isHandling401` 标志防止重复跳转
- 新增 `handleUnauthorized()` 私有方法：清除 token + 跳转登录页
- 新增 `checkAuth<T>()` 私有方法：检查响应 code 是否为 401
- 所有请求方法（get/post/postWithParams/putWithParams/put/del）返回前统一调用 `checkAuth()`

**原因**：任何 API 返回 401 时自动处理，无需每个调用点手动判断。

### 4. FavoriteService.ets

**改动**：
- 新增 `mergeLocalFavoritesToCloud()` 方法：
  1. 获取本地离线收藏 ID 集合
  2. 获取云端已有收藏 ID 集合
  3. 计算差集（本地有但云端没有的）
  4. 逐个调用 `FavoriteApi.add()` 合并到云端
  5. 更新本地缓存为合并后的完整集合

**原因**：用户离线时收藏的资源，登录后应同步到云端，避免数据丢失。

### 5. LoginPage.ets

**改动**：
- 引入 `FavoriteService` 依赖
- 登录成功后（`saveLogin` 之后）：
  1. 初始化 `favoriteService`
  2. 调用 `mergeLocalFavoritesToCloud()`（异步，不阻塞跳转）

**原因**：登录是触发收藏合并的最佳时机，此时 token 刚获取，API 可用。

---

# 阶段三：评论 + 上传

> 日期：2026-06-07
> 目标：鸿蒙 App 可以评论资源、上传新资源、管理自己的资源

---

## 修改总览

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/src/main/ets/pages/UploadPage.ets` | 新建上传页面 | ✅ |
| 2 | `entry/src/main/ets/pages/MyResourcesPage.ets` | 新建我的资源页面 | ✅ |
| 3 | `entry/src/main/ets/pages/Index.ets` | 添加浮动上传按钮 | ✅ |
| 4 | `entry/src/main/ets/pages/ProfilePage.ets` | 添加我的资源入口 | ✅ |
| 5 | `entry/src/main/ets/pages/DetailPage.ets` | 评论 username→nickname 修复 | ✅ |

---

## 详细修改记录

### 1. UploadPage.ets（新建）

**功能**：
- 表单字段：标题、分类（从本地分类列表选择）、类型（教程/书籍/视频/软件）、资源链接、封面图链接、描述
- 调用 `ResourceApi.create()` 提交上传
- 上传成功后提示"等待审核"并自动返回
- 表单验证：标题、分类、资源链接为必填

**调用的 API**：`POST /api/resource/create`

### 2. MyResourcesPage.ets（新建）

**功能**：
- 调用 `ResourceApi.getUserResources()` 获取用户上传的资源列表
- 显示资源标题、描述、日期、点赞数
- 支持删除自己的资源（`ResourceApi.deleteResource()`）
- 空状态提示"还没有上传过资源"
- 右上角上传入口跳转 UploadPage

**调用的 API**：
- `GET /api/resource/user` — 我的资源列表
- `DELETE /api/resource/delete/{id}` — 删除资源

### 3. Index.ets

**改动**：
- 引入 `router` 模块
- `build()` 方法从 `Tabs` 改为 `Stack` 包裹 `Tabs` + 浮动按钮
- 新增右下角浮动"+"按钮，点击跳转 UploadPage
- 按钮样式：52x52 圆形、主题色背景、阴影

### 4. ProfilePage.ets

**改动**：
- Stats cards 从 2 列改为 3 列（48% → 31%）
- 新增"我的资源"卡片（📄 图标），点击跳转 MyResourcesPage

### 5. DetailPage.ets

**改动**：
- `CommentItem` 乐观更新中 `username` → `nickname`（匹配阶段一 CommentApi 改动）
- 评论列表显示中 `item.username` → `item.nickname`

---

# 阶段四：增值特性

> 日期：2026-06-07
> 目标：端侧推荐引擎、AI 语音朗读、系统分享、意图框架·小艺

---

## 修改总览

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/src/main/ets/services/RecommendService.ets` | 新建端侧推荐引擎 | ✅ |
| 2 | `entry/src/main/ets/pages/tabs/HomeTab.ets` | 添加"猜你喜欢"推荐区域 | ✅ |
| 3 | `entry/src/main/ets/pages/DetailPage.ets` | 添加相似推荐 + TTS 朗读 + 分享按钮 | ✅ |
| 4 | `entry/src/main/ets/services/TtsService.ets` | 新建 TTS 语音朗读服务 | ✅ |
| 5 | `entry/src/main/ets/services/ShareHelper.ets` | 新建系统分享服务 | ✅ |
| 6 | `entry/src/main/ets/entryability/EntryAbility.ets` | 意图框架处理小艺搜索 | ✅ |
| 7 | `entry/src/main/module.json5` | 注册搜索意图 + deeplink | ✅ |

---

## 详细修改记录

### 1. RecommendService.ets（新建）

**功能**：
- `getRecommendations(count)` — 基于收藏和浏览历史的标签/分类偏好计算推荐分数
- `getGuessYouLike(count)` — 首页"猜你喜欢"推荐
- `getSimilarResources(resourceId, count)` — 详情页相似资源推荐
- 无行为数据时降级为热门资源（按 likeCount 排序）
- 收藏行为权重 3.0，浏览历史权重按时间衰减 0.5~1.0
- 分类匹配权重 ×2.0，标签匹配权重 ×1.5，热度加分，随机扰动避免固定

**特点**：零网络依赖，完全本地计算

### 2. HomeTab.ets

**改动**：
- 引入 `RecommendService` 和 `FavoriteService`
- 新增 `@State guessYouLike: ResourceItem[]`
- `aboutToAppear()` 中初始化推荐服务并加载推荐数据
- 新增"✨ 猜你喜欢"区域，显示 6 个推荐资源卡片
- "换一批"按钮重新生成推荐

### 3. DetailPage.ets

**改动**：
- 引入 `RecommendService`、`TtsService`、`ShareHelper`
- 新增 `@State similarResources` 和 `@State isSpeaking`
- `loadDetailFromApi()` 中加载 4 个相似推荐
- Header bar 新增 🔈/🔊 TTS 朗读按钮 + ↗ 分享按钮
- 新增 `toggleTts()` 方法：切换朗读/停止
- 新增"📋 相似推荐"区域，点击跳转详情

### 4. TtsService.ets（新建）

**功能**：
- 使用 HarmonyOS Core Speech Kit (`@kit.CoreSpeechKit`)
- `init()` — 初始化 TTS 引擎，离线模式，中文语音
- `speak(text)` — 朗读文本
- `stop()` — 停止朗读
- `speakResource(title, description)` — 朗读资源详情
- `shutdown()` — 销毁引擎

### 5. ShareHelper.ets（新建）

**功能**：
- 使用 HarmonyOS ShareKit (`@kit.ShareKit`)
- `shareText(title, url)` — 系统分享文本链接
- `shareResource(resourceId, title)` — 分享资源链接
- 降级方案：任何设备都可用系统分享面板

### 6. EntryAbility.ets

**改动**：
- 新增 `searchKeyword` 状态和 `handleIntent()` 方法
- `onCreate()` 和 `onNewWant()` 中处理意图
- 支持从意图参数提取关键词（`keyword`/`query`/`search`）
- 支持 deeplink：`neushare://search?keyword=xxx`
- 有搜索意图时直接加载 SearchPage，否则加载 SplashPage

### 7. module.json5

**改动**：
- skills 中新增搜索意图：`ohos.want.action.search`
- uris 中注册 deeplink：`neushare://search`
- 效果：小艺助手可以说"在NEUShare搜索高数"直接打开 App 搜索

---

# Bug 修复

> 日期：2026-06-07

## 修复内容

| 文件 | 问题 | 修复 |
|------|------|------|
| `entry/.../TtsService.ets` | `TtsExtraParams` 接口无索引签名，无法赋值给 `Record<string, Object>` | 移除接口，改用 `Record<string, Object>` 直接声明 |
| `entry/.../TtsService.ets` | `SpeakParams.extraParams` 中 `1.0 as Object` 原始类型转型不合法 | 改为单独声明 `Record<string, Object>` 变量 |
| `common/.../HttpClient.ets` | `router.replaceUrl()` 抛异常未捕获 | 包裹 try-catch |
| `entry/.../SplashPage.ets` | `router.replaceUrl()` 抛异常未捕获（3 处） | 包裹 try-catch |
| `entry/.../IdentityCardPage.ets` | `router.replaceUrl()` 抛异常未捕获（2 处） | 包裹 try-catch |
| `entry/.../SplashPage.ets.bak` | 备份文件残留 | 删除 |

## EntryAbility → SearchPage 意图传参修复

| 文件 | 问题 | 修复 |
|------|------|------|
| `entry/.../EntryAbility.ets` | `loadContent('pages/SearchPage')` 不走 router，参数丢失 | `onWindowStageCreate` / `onNewWant` 中将 keyword 写入 `AppStorage.setOrCreate('searchKeyword', keyword)` |
| `entry/.../SearchPage.ets` | `router.getParams()` 取不到意图传入的关键词 | `aboutToAppear` 中 fallback 读取 `AppStorage.get('searchKeyword')`，读后清除 |

---

# 评论系统改造

> 日期：2026-06-07
> 目标：评论删除权限扩展 + 软删除（父评论删除后子评论保留）

---

## 改动总览

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `neushare-backend/.../db/init.sql` | comment 表新增 `deleted` 字段 | ✅ |
| 2 | `neushare-backend/.../entity/Comment.java` | 新增 `deleted` 属性 | ✅ |
| 3 | `neushare-backend/.../vo/CommentVO.java` | 新增 `deleted` 属性 | ✅ |
| 4 | `neushare-backend/.../mapper/CommentMapper.xml` | resultMap 新增 `deleted` 映射 | ✅ |
| 5 | `neushare-backend/.../service/impl/CommentServiceImpl.java` | 软删除 + 权限扩展 | ✅ |
| 6 | `entry/.../api/CommentApi.ets` | CommentItem 新增 `deleted` 字段 | ✅ |
| 7 | `entry/.../pages/DetailPage.ets` | 已删除评论灰色显示 + 子评论保留 | ✅ |
| 8 | `neushare-frontend/.../ResourceDetail.vue` | 已删除评论灰色显示 + 子评论保留 | ✅ |

---

## 详细修改记录

### 1. 数据库

**init.sql**：`comment` 表新增 `deleted TINYINT DEFAULT 0 COMMENT '0-正常 1-已删除'`

**已有数据库需执行**：
```sql
ALTER TABLE comment ADD COLUMN deleted TINYINT DEFAULT 0 COMMENT '0-正常 1-已删除';
```

### 2. 后端实体/VO

- `Comment.java`：新增 `private Integer deleted;` + `@TableField("deleted")`
- `CommentVO.java`：新增 `private Integer deleted;`
- `CommentMapper.xml`：resultMap 新增 `<result column="deleted" property="deleted"/>`

### 3. CommentServiceImpl（核心改动）

**删除权限扩展**：
- 原逻辑：仅评论者本人可删（`comment.getUserId().equals(userId)`）
- 新逻辑：评论者本人 **或** 资源所有者均可删
  - 注入 `ResourceService`，查询评论所属资源的 `uploadUserId`
  - `isCommentOwner || isResourceOwner` 二选一即可

**软删除**：
- 原逻辑：`removeById(id)` 物理删除，子评论成为孤儿
- 新逻辑：`setDeleted(1)` + `setContent("该评论已被删除")` + `updateById(comment)`
- 父评论标记为已删除但保留记录，子评论的 `parentId` 仍指向有效记录
- 前端根据 `deleted` 字段决定显示样式

### 4. 鸿蒙端

- `CommentItem` 接口新增 `deleted: number`
- `DetailPage` 评论区域：
  - `deleted === 1` 时显示灰色 "该评论已被删除"，隐藏头像和昵称
  - 子评论同样适配 `deleted` 状态
  - 已删除评论不显示"回复"按钮

### 5. Web 前端

- `ResourceDetail.vue` 评论区域：
  - `comment.deleted` 时显示 `.comment-deleted` 灰色斜体样式
  - `reply.deleted` 时显示 `.reply-deleted` 灰色斜体样式
  - 已删除评论隐藏头像、不显示"回复"按钮

---

# 鸿蒙端代码质量改进（P1+P2）

> 日期：2026-06-12
> 目标：对比 QuickStart 最佳实践，修复鸿蒙端核心体验问题

---

## P1：WebView 应用内浏览器

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/.../pages/WebViewPage.ets` | 新建应用内 WebView 浏览器页面 | ✅ |
| 2 | `entry/.../pages/DetailPage.ets` | openUrl 改为应用内打开 + 新增 openInBrowser 备选 | ✅ |
| 3 | `entry/.../resources/base/profile/main_pages.json` | 注册 WebViewPage 路由 | ✅ |

### WebViewPage.ets（新建）

**功能**：
- ArkWeb `Web` 组件 + `WebviewController` 实现应用内浏览器
- 顶部导航栏：返回/前进/浏览器打开
- 加载进度条（`onProgressChange` 回调）
- WebView 内返回导航（`backward()` / `forward()`）
- 错误页 + 重试 + 在浏览器中打开
- 支持 `domStorageAccess`、`javaScriptAccess`、`mixedMode`、`mediaPlayGestureAccess`

### DetailPage.ets 改动

- `openUrl()` 改为 `router.pushUrl({ url: 'pages/WebViewPage', params: { url, title } })`
- 新增 `openInBrowser()` 方法（原 openUrl 逻辑，用系统浏览器打开）
- "在线资源"区域改为双按钮："应用内打开" + "浏览器打开"

---

## P2-1：Toast 改用系统 promptAction

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/.../pages/DetailPage.ets` | 移除 toastMsg 状态和红色 Text 条，改用 promptAction.showToast() | ✅ |
| 2 | `entry/.../pages/UploadPage.ets` | 移除 toastMsg 状态和红/绿 Text 条，改用 promptAction.showToast() | ✅ |
| 3 | `entry/.../pages/MyResourcesPage.ets` | 移除 toastMsg 状态和红/绿 Text 条，改用 promptAction.showToast() | ✅ |

### 改动说明

- 移除 `@State toastMsg: string` 状态变量
- 移除 build() 中的 `if (this.toastMsg) { Text(...) }` 自定义提示条
- 所有 `this.toastMsg = 'xxx'` 替换为 `promptAction.showToast({ message: 'xxx' })`
- 新增 `import promptAction from '@ohos.promptAction'`

---

## P2-2：LazyForEach 替换关键列表

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/.../models/ArrayDataSource.ets` | 新建通用 IDataSource 实现 | ✅ |
| 2 | `entry/.../pages/SearchPage.ets` | 搜索结果列表 ForEach → LazyForEach | ✅ |

### ArrayDataSource.ets（新建）

**功能**：
- 实现 `IDataSource` 接口，供 `LazyForEach` 使用
- `replaceAll(data)` 全量替换数据并通知刷新
- `totalCount()` / `getData(index)` / `registerDataChangeListener` / `unregisterDataChangeListener`

### SearchPage.ets 改动

- 新增 `resultsDataSource: ArrayDataSource<ResourceItemModel>` 实例
- `doSearch()` 完成后调用 `resultsDataSource.replaceAll()`
- 新增 `applySort()` 方法：排序后刷新 DataSource
- 排序 chips 回调改为调用 `applySort()`
- 搜索结果 `List` 中 `ForEach` → `LazyForEach(this.resultsDataSource, ...)`

---

## P2-3：分享接入 ShareKit 系统面板

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/.../services/ShareHelper.ets` | 优先用 ShareKit 系统分享面板，降级剪贴板 | ✅ |
| 2 | `entry/.../entryability/EntryAbility.ets` | onCreate 中将 context 存入 AppStorage | ✅ |

### ShareHelper.ets 改动

- 新增 `import { share } from '@kit.ShareKit'`
- `shareText()` 优先使用 `share.ShareController` + `share()` 弹出系统分享面板
- ShareKit 不可用时降级为 `copyToClipboard()`（原逻辑）
- 降级时显示 `promptAction.showToast({ message: '链接已复制到剪贴板' })`

### EntryAbility.ets 改动

- `onCreate()` 中新增 `AppStorage.setOrCreate('context', this.context)`
- 供 ShareHelper 等服务获取 UIAbilityContext

---

## 断点消费：响应式布局

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `entry/.../pages/tabs/CategoryTab.ets` | Flex→Grid，SM 2列/MD 3列/LG 4列 | ✅ |
| 2 | `entry/.../components/CategoryCard.ets` | width('46%')→width('100%') 适配 Grid | ✅ |
| 3 | `entry/.../pages/CategoryPage.ets` | List→Grid，SM 1列/MD 2列/LG 3列 | ✅ |
| 4 | `entry/.../pages/SearchPage.ets` | List→Grid，SM 1列/MD 2列/LG 3列 | ✅ |
| 5 | `entry/.../pages/DetailPage.ets` | 大屏主从双栏（内容2:推荐1），小屏全屏滚动 | ✅ |

### 改动说明

- 所有改动页面新增 `@StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointType.SM`
- CategoryTab：`Flex` → `Grid` + `columnsTemplate()` 根据断点返回不同列数
- CategoryPage/SearchPage：`List + ForEach` → `Grid + ForEach/LazyForEach`，`columnsTemplate` 自适应
- DetailPage：大屏(MD/LG)用 `Row` 包裹主内容(layoutWeight=2) + 侧边推荐栏(layoutWeight=1)，小屏保持原样
- DetailPage 将 build() 中的内联 UI 拆分为 `@Builder` 方法（HeaderBar/TitleCard/DescriptionSection 等），大屏小屏复用

---

## 深色模式

| 序号 | 文件 | 改动内容 | 状态 |
|------|------|----------|------|
| 1 | `common/.../theme/ColorTokens.ets` | 新增深色色板 + 便捷解析方法 | ✅ |
| 2 | `common/.../theme/AppTheme.ets` | 监听系统暗色模式 + AppStorage 同步 | ✅ |
| 3 | `entry/.../entryability/EntryAbility.ets` | 初始化 AppTheme + onConfigurationUpdate | ✅ |

### ColorTokens.ets 改动

- 新增深色色板：`TEXT_PRIMARY_DARK`(#E8E8E8)、`BG_PAGE_DARK`(#121212)、`BG_CARD_DARK`(#1E1E1E) 等
- 新增 `resolve(token, darkToken, isDark)` 通用解析方法
- 新增便捷方法：`textPrimary(isDark)`、`bgPage(isDark)`、`bgCard(isDark)` 等
- 所有原有浅色常量保持不变，向后兼容

### AppTheme.ets 改动

- 新增 `initFromContext(context)` — 从系统配置读取当前颜色模式
- 新增 `onConfigurationUpdate(colorMode)` — 系统暗色模式切换时更新 `AppStorage.setOrCreate('isDarkMode', isDark)`
- `setThemeMode()` 现在会同步更新 AppStorage
- 组件可通过 `@StorageLink('isDarkMode')` 响应式获取暗色模式状态

### EntryAbility.ets 改动

- `onWindowStageCreate()` 中新增 `AppTheme.getInstance().initFromContext(this.context)`
- 新增 `onConfigurationUpdate()` 回调，系统颜色模式变化时通知 AppTheme
