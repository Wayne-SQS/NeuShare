# NeuShare — 校园资料分享平台

## 项目概览

东北大学（NEU）学习资料分享平台。学生/教师可以上传、搜索、浏览、评论、点赞、收藏课程资料。管理员审核资料、管理用户和轮播图。

---

## 技术栈

| 层 | 技术 |
|---|------|
| 前端 | Vue 3 (Composition API `<script setup>`), Vite 5, Element Plus 2.6, Pinia, Vue Router 4, Axios, ECharts 5 |
| 后端 | Spring Boot 2.7.18, MyBatis-Plus 3.5.5, MySQL 8, JWT (jjwt 0.9.1), BCrypt (spring-security-crypto) |
| 构建 | Maven (backend), npm/vite (frontend) |

---

## 目录结构

```
web/
├── neushare-frontend/          # Vue 3 前端
│   └── src/
│       ├── api/                # Axios 请求模块（request.js 封装实例）
│       │   ├── auth.js         # 登录/注册/个人信息/修改密码
│       │   ├── resource.js     # 资源 CRUD + 分类列表
│       │   ├── comment.js      # 评论列表/添加/删除
│       │   ├── favorite.js     # 收藏列表/添加/移除/检查
│       │   ├── admin.js        # 管理后台全部接口
│       │   └── banner.js       # 公开轮播图 API（前端未使用，功能在 admin.js 中）
│       ├── components/         # Header, Footer, ResourceCard, Sidebar
│       ├── router/index.js     # 路由 + beforeEach 守卫
│       ├── store/
│       │   └── modules/user.js # Pinia 用户状态（token, userInfo）
│       ├── styles/global.css   # CSS 变量、重置、动画
│       ├── utils/
│       │   ├── constants.js    # RESOURCE_STATUS, USER_STATUS, ROLE_MAP, GRADE_LABELS
│       │   ├── format.js       # formatTime（相对时间）, getInitial（头像首字母）
│       │   └── courseData.js   # 学院/年级/学期/课程数据
│       └── views/
│           ├── Home.vue        # 首页
│           ├── Login.vue / Register.vue
│           ├── ResourceList.vue / ResourceDetail.vue
│           ├── Upload.vue
│           ├── NotFound.vue
│           ├── profile/        # Layout, ProfileInfo, MyResources, MyFavorites
│           └── admin/          # Layout, Dashboard, Audit, UserManage, BannerManage
├── neushare-backend/           # Spring Boot 后端
│   └── src/main/java/com/neushare/
│       ├── common/             # Result<T>, PageResult<T>
│       ├── config/             # CORS, MyBatis-Plus 分页插件, WebMvcConfig（拦截器注册）
│       ├── controller/         # 7 个控制器（见下方 API 清单）
│       ├── dto/                # LoginDTO, RegisterDTO, ResourceDTO, UpdateUserDTO
│       ├── entity/             # User, Resource, Comment, Favorite, Banner, Category
│       ├── interceptor/        # JwtInterceptor（JWT 校验 + 管理员权限）
│       ├── mapper/             # MyBatis-Plus BaseMapper + 自定义 XML
│       ├── service/            # 服务接口 + impl 实现
│       ├── util/               # JwtUtil, Md5Util（实际是 BCrypt）, FileUploadUtil
│       └── vo/                 # UserVO, ResourceVO, CommentVO
└── sql/                        # 旧版 SQL 脚本（已废弃，新版在 backend/resources/db/）
```

---

## 常用命令

```bash
# 前端
cd neushare-frontend
npm run dev      # 开发服务器 → localhost:3000，API 代理到 localhost:8080
npm run build    # 生产构建 → dist/

# 后端
cd neushare-backend
mvn spring-boot:run   # 启动 → localhost:8080
```

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
| `PUT /api/admin/user/status` | `params: { id, status }` |
| `PUT /api/admin/resource/audit` | `params: { id, status }` |
| `PUT /api/admin/banner/status` | `params: { id, status }` |

**例外**（使用 `data` JSON body）：`login`, `register`, `updateUserInfo`, `createResource`（FormData）, `updateResource`, `addBanner`, `updateBanner`

### 2. 分页参数

- 请求参数: `pageNum`, `pageSize`（非 `page`/`size`）
- 响应字段: `res.data.records`, `res.data.total`（非 `list`）

### 3. 状态值（整数，非字符串）

- **资源状态**: `0`=待审核, `1`=已发布, `2`=已驳回 → 使用 `RESOURCE_STATUS` 常量
- **用户状态**: `0`=禁用, `1`=启用 → 使用 `USER_STATUS` 常量

### 4. VO 字段名

- 资源作者: `uploadNickname`, `uploadUsername`, `uploadAvatar`（非 `authorName`）
- 用户头像: `avatarUrl`（非 `avatar`）
- 轮播图: `imageUrl`, `linkUrl`（非 `image`/`link`）
- 评论: `nickname`, `avatarUrl`, `children`（非 `userName`/`replies`）
- 收藏检查: `res.data.isFavorite`（非 `isFavorited`）

### 5. 用户信息

`UserVO` 字段: `id`, `username`, `role`, `nickname`, `avatarUrl`, `college`, `grade`, `status`
没有 `studentId`, `email` 字段。

---

## API 清单

### 公开（无需登录）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/login | 登录 → `{token, user}` |
| POST | /api/auth/register | 注册 |
| GET | /api/resource/list | 资源分页 `?pageNum&pageSize&status&categoryId&keyword` |
| GET | /api/resource/detail/{id} | 资源详情（自动浏览量+1） |
| GET | /api/resource/hot | 热门资源 `?limit` |
| GET | /api/resource/search | 搜索 `?keyword`（仅已发布） |
| GET | /api/comment/list/{resourceId} | 评论列表（树形） |
| GET | /api/banner/list | 启用中的轮播图 |
| GET | /api/category/list | 全部分类 |

### 需登录
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/auth/info | 获取当前用户信息 |
| PUT | /api/auth/info | 更新个人信息 `{nickname, avatarUrl, college, grade}` |
| PUT | /api/auth/password | 修改密码 `params: oldPassword, newPassword` |
| POST | /api/resource/create | 创建资源（FormData） |
| PUT | /api/resource/update | 更新资源（JSON body） |
| DELETE | /api/resource/delete/{id} | 删除自己的资源 |
| GET | /api/resource/user | 我的资源 |
| POST | /api/resource/like/{id} | 点赞 |
| DELETE | /api/resource/like/{id} | 取消点赞 |
| POST | /api/comment/add | 添加评论 `params: resourceId, content, parentId?` |
| DELETE | /api/comment/delete/{id} | 删除自己的评论 |
| GET | /api/comment/user | 我的评论 |
| POST | /api/favorite/add | 收藏 `params: resourceId` |
| DELETE | /api/favorite/remove | 取消收藏 `params: resourceId` |
| GET | /api/favorite/check | 检查是否已收藏 `params: resourceId` → `{isFavorite}` |
| GET | /api/favorite/list | 我的收藏分页 |

### 管理员
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/admin/statistics | 统计数据 `{userCount, resourceCount, commentCount, pendingResourceCount}` |
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

---

## 数据库

- 库名: `neushare`
- 初始化脚本: `neushare-backend/src/main/resources/db/init.sql`
- 6 张表: user, resource, category, comment, favorite, banner
- 预置 8 个用户（密码 BCrypt 加密，原始值见 init.sql）、12 个分类、14 个资源、17 条评论、12 条收藏、3 张轮播图

### JWT 拦截器公开路径

```
/api/auth/login, /api/auth/register, /api/resource/list, /api/resource/hot,
/api/resource/detail/**, /api/resource/search, /api/banner/list,
/api/comment/list/**, /api/category/list
```

其他所有 `/api/**` 需要登录。`/api/admin/**` 额外需要 `role="admin"`。

---

## 前端路由

| 路径 | 组件 | 权限 |
|------|------|------|
| `/login` | Login | 游客（已登录重定向到 /） |
| `/register` | Register | 游客 |
| `/` | Home | 公开 |
| `/resource` | ResourceList | 公开 |
| `/resource/:id` | ResourceDetail | 公开 |
| `/upload` / `/upload/:id` | Upload | 需登录 |
| `/profile/info` | ProfileInfo | 需登录 |
| `/profile/resources` | MyResources | 需登录 |
| `/profile/favorites` | MyFavorites | 需登录 |
| `/admin/dashboard` | Dashboard | 管理员 |
| `/admin/audit` | Audit | 管理员 |
| `/admin/users` | UserManage | 管理员 |
| `/admin/banners` | BannerManage | 管理员 |

---

## 已知问题 / 注意事项

- `Md5Util` 类名有误导性，实际使用 BCrypt（非 MD5）
- `banner.js` 是公开 API 模块，但当前无组件使用它（Home.vue 也未使用轮播图）
- Dashboard 的图表在无真实数据时使用硬编码演示数据
- 点赞状态前端未持久化，刷新页面后 `isLiked` 重置为 false
- 前端排序下拉框已移除（后端不支持排序参数）
- 文件上传目录在 `uploads/`，通过 `file.upload.path` 配置
- 数据库密码明文写在 `application.yml` 中
