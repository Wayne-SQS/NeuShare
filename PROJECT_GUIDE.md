# NeuShare — 东北大学学习资料共享平台

> **SpringBoot + Vue3 全栈项目** · Web开发技术课程实验

## 项目简介

NeuShare 是一个面向东北大学师生的学习资料共享社区。学生和教师可以上传、浏览、搜索课程资料，进行评论、点赞和收藏互动；管理员拥有审核、用户管理和数据统计等后台功能。

系统覆盖大一至大四 **8 个年级学期**，内置 **12 门核心课程**分类，支持按年级学期快速定位课程资料，内置丰富的演示数据可直接用于课堂展示。

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 后端框架 | Spring Boot | 2.7.18 |
| ORM | MyBatis-Plus | 3.5.5 |
| 数据库 | MySQL | 8.0 |
| 认证 | JWT (jjwt) | 0.9.1 |
| 密码加密 | BCrypt (Spring Security Crypto) | 5.7.3 |
| 工具库 | Hutool | 5.8.25 |
| 前端框架 | Vue 3 | 3.4.21 |
| 构建工具 | Vite | 5.1.6 |
| UI 组件库 | Element Plus | 2.6.1 |
| 状态管理 | Pinia | 2.1.7 |
| 路由 | Vue Router | 4.3.0 |
| 图表 | ECharts | 5.5.0 |
| HTTP 客户端 | Axios | 1.6.8 |

## 快速开始

### 环境要求

- JDK 1.8+ & Maven 3.6+
- Node.js 18+ & npm
- MySQL 8.0+

### 1. 初始化数据库

推荐使用后端自带的完整初始化脚本（含 category 表和演示数据）：

```bash
mysql -u root -p < neushare-backend/src/main/resources/db/init.sql
```

> ⚠️ `sql/neushare.sql` 为旧版脚本，缺少 category 表且数据较少，**请优先使用上述 init.sql**。

### 2. 配置数据库连接

编辑 `neushare-backend/src/main/resources/application.yml`：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/neushare?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: root
    password: 你的MySQL密码
```

### 3. 启动后端

```bash
cd neushare-backend
mvn spring-boot:run
# 后端运行在 http://localhost:8080
```

### 4. 启动前端

```bash
cd neushare-frontend
npm install
npm run dev
# 前端运行在 http://localhost:3000
# Vite 自动将 /api 请求代理到 http://localhost:8080
```

## 演示账号

所有账号密码均为 **`123456`**，可直接用于课堂展示：

| 角色 | 用户名 | 昵称 | 学院 | 年级 | 能演示的功能 |
|------|--------|------|------|------|-------------|
| 管理员 | `admin` | 管理员小明 | 软件学院 | — | 数据看板、资料审核、用户管理、轮播图管理 |
| 学生 | `20240001` | 张三 | 软件学院 | 大二 | 浏览资料、上传、评论、点赞、收藏、个人中心 |
| 学生 | `20240002` | 李四 | 计算机学院 | 大三 | 浏览资料、上传资料（有上传记录） |
| 学生 | `20240003` | 王五 | 软件学院 | 大一 | 浏览资料、发起提问评论 |
| 学生 | `20230001` | 赵六 | 信息学院 | 大三 | 浏览资料（有收藏记录） |
| 教师 | `T20240001` | 王老师 | 软件学院 | — | 上传课件、回复学生评论 |
| 教师 | `T20240002` | 李老师 | 计算机学院 | — | 上传教程、回复评论 |
| 学生(禁用) | `20240004` | 孙七 | 软件学院 | 大二 | 已被禁用，用于管理员"禁用用户"功能演示 |

## 首页年级学期筛选

首页提供 **8 个年级学期按钮**，点击即可查看对应学期的课程列表，再点击课程可跳转到资源广场搜索相关资料：

| 按钮 | 包含课程 |
|------|---------|
| 大一上 | 高等数学、线性代数、程序设计基础、大学英语、思想道德与法治 |
| 大一下 | 面向对象程序设计（JAVA）、高等数学（下）、大学物理、中国近现代史纲要 |
| 大二上 | 数据结构与算法（C语言）、计算机组成原理、概率论与数理统计、Python编程与数据分析 |
| 大二下 | 操作系统、计算机网络、数据库原理、离散数学 |
| 大三上 | 软件工程、编译原理、人工智能导论 |
| 大三下 | Web开发技术、机器学习、信息安全 |
| 大四上 | 毕业设计、软件项目管理 |
| 大四下 | 毕业实习、毕业论文 |

> 学院和年级信息存储在用户账户属性中，注册时选择。部分课程（如大学英语、大学物理等）在数据库中暂无对应分类，点击后跳转资源广场但不做分类筛选。

## 预置数据一览

init.sql 执行后自动生成以下数据，确保系统启动即有丰富内容可展示：

### 数据统计

| 数据项 | 数量 |
|--------|------|
| 用户 | 8 |
| 课程分类 | 12 |
| 资源 | 14 |
| 评论 | 17 |
| 收藏 | 12 |
| 轮播图 | 3 |

### 分类（12 个课程）

`高等数学` · `线性代数` · `程序设计基础(C语言)` · `面向对象程序设计(JAVA)` · `数据结构与算法` · `计算机组成原理` · `操作系统` · `计算机网络` · `数据库原理` · `软件工程` · `Python程序设计` · `Web开发技术`

### 资源（14 条）

| # | 标题 | 状态 | 上传者 | 浏览量 | 点赞 | 收藏 |
|---|------|------|--------|--------|------|------|
| 1 | 高等数学(上)期末复习笔记 | 已发布 | 王老师 | 856 | 128 | 45 |
| 2 | 数据结构与算法课件合集 | 已发布 | 王老师 | 1203 | 256 | 89 |
| 3 | Java实验报告模板 | 已发布 | 张三 | 432 | 67 | 23 |
| 4 | 操作系统-进程调度算法详解 | 已发布 | 李四 | 678 | 98 | 34 |
| 5 | 计算机网络-期末重点整理 | 已发布 | 王五 | 945 | 156 | 67 |
| 6 | 数据库原理-SQL练习题50道 | 已发布 | 赵六 | 567 | 89 | 28 |
| 7 | 线性代数-矩阵运算笔记 | 已发布 | 张三 | 341 | 45 | 12 |
| 8 | C语言课程设计-学生管理系统源码 | 已发布 | 李四 | 2340 | 389 | 156 |
| 9 | Python数据分析入门教程 | 已发布 | 李老师 | 892 | 134 | 42 |
| 10 | 软件工程-需求分析文档范例 | 已发布 | 李老师 | 412 | 56 | 19 |
| 11 | 计算机组成原理-实验报告合集 | 已发布 | 赵六 | 523 | 78 | 31 |
| 12 | Web开发技术-Vue3项目实战 | **待审核** | 王五 | 0 | 0 | 0 |
| 13 | 高等数学(下)多元微积分笔记 | **待审核** | 张三 | 0 | 0 | 0 |
| 14 | 不知名广告资料 | **已拒绝** | 孙七 | 45 | 5 | 0 |

### 互动数据

- **评论**：17 条，分布在 7 个资源下。其中高等数学笔记和 C 语言源码下各有嵌套回复链，可用于展示**评论嵌套**功能。
- **收藏**：12 条，学生张三、李四、王五、赵六各有收藏记录，可用于展示**我的收藏**页面。
- **待审核资料**：2 条（Vue3 项目实战、高等数学下册笔记），供管理员演示**审核通过/驳回**。
- **已拒绝资料**：1 条（广告），演示审核驳回后的状态。

## 三端功能对照

### 学生端

| 功能 | 操作入口 | 说明 |
|------|---------|------|
| 年级学期筛选 | 首页 | 8 个按钮快速定位课程，点击跳转资源广场 |
| 浏览资源广场 | 首页 / 资源广场 | 支持分页、按课程分类筛选、关键词搜索 |
| 查看资源详情 | 点击资源卡片 | 展示资料信息、上传者、评论互动区 |
| 上传资料 | 上传页面 | 选择课程分类，填写标题描述，上传文件 |
| 发表评论 | 资源详情页 | 支持一级评论和回复他人（嵌套展示） |
| 点赞 | 资源详情页 | 点赞数实时更新 |
| 收藏/取消收藏 | 资源详情页 / 我的收藏 | 可在收藏列表快速找到标记的资料 |
| 编辑个人资料 | 个人中心 | 修改昵称、头像、学院、年级 |
| 修改密码 | 个人中心 | 需验证旧密码 |
| 我的资料 | 个人中心 | 查看自己上传的资料列表 |
| 我的收藏 | 个人中心 | 查看收藏的资料列表 |

### 教师端

与学生端功能一致，额外可以通过上传优质课件展示教师身份（在资源中显示"教师"标识）。

### 管理员端

| 功能 | 操作入口 | 说明 |
|------|---------|------|
| 数据看板 | `/admin/dashboard` | ECharts 图表展示用户数、资源数、评论数、待审核数 |
| 资料审核 | `/admin/audit` | 审核待处理资源，通过 → 发布，驳回 → 拒绝 |
| 用户管理 | `/admin/users` | 查看用户列表，启用/禁用账号，删除用户 |
| 轮播图管理 | `/admin/banners` | 新增/编辑/删除首页轮播图，控制启用状态 |

## 页面路由

| 路由 | 页面 | 权限 |
|------|------|------|
| `/login` | 登录（左右分栏布局） | 公开 |
| `/register` | 注册（左右分栏布局，含学院年级选择） | 公开 |
| `/` | 首页（年级学期筛选 + 热门资源 + 最新资源） | 公开 |
| `/resource` | 资源广场（分页 + 筛选 + 搜索） | 公开 |
| `/resource/:id` | 资料详情（评论 + 点赞 + 收藏） | 公开 |
| `/upload` | 上传资料 | 需登录 |
| `/profile/info` | 个人资料 | 需登录 |
| `/profile/resources` | 我的资料 | 需登录 |
| `/profile/favorites` | 我的收藏 | 需登录 |
| `/admin/dashboard` | 数据统计（ECharts） | 管理员 |
| `/admin/audit` | 资料审核 | 管理员 |
| `/admin/users` | 用户管理 | 管理员 |
| `/admin/banners` | 轮播图管理 | 管理员 |
| `/:pathMatch(.*)*` | 404 页面 | 公开 |

## 路由守卫

| 规则 | 说明 |
|------|------|
| 未登录访问需认证页面 | 自动跳转 `/login?redirect=原路径`，登录后返回原页面 |
| 已登录访问登录/注册页 | 自动跳转首页 |
| 非管理员访问管理后台 | 拒绝访问，跳转首页 |
| 页面切换 | 自动滚动到顶部 |
| 页面标题 | 动态设置为 `页面名 - NeuShare` |

## 项目结构

```
web/
├── neushare-backend/                  # SpringBoot 后端
│   └── src/main/
│       ├── java/com/neushare/
│       │   ├── controller/            # 控制器（Auth/Resource/Comment/Favorite/Admin/Category/Banner）
│       │   ├── service/               # 服务接口 + impl
│       │   ├── mapper/                # MyBatis Mapper
│       │   ├── entity/                # 实体类（User/Resource/Comment/Favorite/Banner/Category）
│       │   ├── dto/                   # 请求对象（LoginDTO/RegisterDTO/ResourceDTO/UpdateUserDTO）
│       │   ├── vo/                    # 响应对象（UserVO/ResourceVO/CommentVO）
│       │   ├── config/                # 配置（CORS/MyBatis-Plus/WebMVC）
│       │   ├── interceptor/           # JWT 认证 + 角色鉴权拦截器
│       │   ├── util/                  # 工具类（JwtUtil/Md5Util(BCrypt)/FileUploadUtil）
│       │   ├── common/                # 通用类（Result/PageResult）
│       │   └── exception/             # 全局异常处理
│       └── resources/
│           ├── application.yml        # 应用配置
│           ├── db/init.sql            # 数据库初始化脚本（推荐使用）
│           └── mapper/                # MyBatis XML（Resource/Comment/Favorite）
│
├── neushare-frontend/                 # Vue3 前端
│   └── src/
│       ├── views/                     # 页面
│       │   ├── Login.vue              # 登录（左右分栏）
│       │   ├── Register.vue           # 注册（含学院年级选择）
│       │   ├── Home.vue               # 首页（年级学期筛选）
│       │   ├── ResourceList.vue       # 资源广场
│       │   ├── ResourceDetail.vue     # 资料详情
│       │   ├── Upload.vue             # 上传资料
│       │   ├── NotFound.vue           # 404页面
│       │   ├── admin/                 # 管理后台（Dashboard/Audit/UserManage/BannerManage/Layout）
│       │   └── profile/               # 个人中心（Info/Resources/Favorites/Layout）
│       ├── components/                # 公共组件（Header/Footer/ResourceCard/Sidebar）
│       ├── api/                       # 接口封装（request/auth/resource/comment/favorite/admin/banner）
│       ├── router/                    # 路由配置 + 守卫
│       ├── store/                     # Pinia 状态管理（modules/user）
│       ├── utils/                     # 工具函数（courseData课程数据）
│       └── styles/                    # 全局样式（CSS变量设计系统）
│
└── sql/                               # SQL 脚本目录
    ├── neushare.sql                   # 旧版数据库脚本（缺少category表，不推荐）
    ├── fix_password.sql               # 密码修复脚本
    └── update_password.sql            # 密码更新脚本
```

## API 接口

### 认证

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | `/api/auth/login` | 登录（参数：username, password） | 公开 |
| POST | `/api/auth/register` | 注册（参数：username, password, nickname, college, grade） | 公开 |
| GET | `/api/auth/info` | 获取当前用户信息 | 需登录 |
| PUT | `/api/auth/info` | 更新个人资料（nickname, avatarUrl, college, grade） | 需登录 |
| PUT | `/api/auth/password` | 修改密码（参数：oldPassword, newPassword） | 需登录 |

### 资源

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/resource/list` | 分页查询（支持 categoryId/keyword/status 筛选） | 公开 |
| GET | `/api/resource/detail/{id}` | 详情 + 增加浏览数 | 公开 |
| GET | `/api/resource/hot` | 热门资源（参数：limit） | 公开 |
| GET | `/api/resource/search` | 关键词搜索 | 公开 |
| POST | `/api/resource/create` | 上传（支持 MultipartFile） | 需登录 |
| PUT | `/api/resource/update` | 编辑资源 | 需登录 |
| DELETE | `/api/resource/delete/{id}` | 删除资源 | 需登录 |
| GET | `/api/resource/user` | 我的资源（分页） | 需登录 |
| POST | `/api/resource/like/{id}` | 点赞 | 需登录 |
| DELETE | `/api/resource/like/{id}` | 取消点赞 | 需登录 |

### 评论

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/comment/list/{resourceId}` | 评论列表（嵌套结构） | 公开 |
| POST | `/api/comment/add` | 发表评论/回复（参数：resourceId, content, parentId） | 需登录 |
| DELETE | `/api/comment/delete/{id}` | 删除评论 | 需登录 |
| GET | `/api/comment/user` | 我的评论（分页） | 需登录 |

### 收藏

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/favorite/list` | 我的收藏（分页） | 需登录 |
| POST | `/api/favorite/add` | 添加收藏（参数：resourceId） | 需登录 |
| DELETE | `/api/favorite/remove` | 取消收藏（参数：resourceId） | 需登录 |
| GET | `/api/favorite/check` | 检查是否已收藏（参数：resourceId） | 需登录 |

### 分类 & 轮播图

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/category/list` | 分类列表（按 sort 排序） | 公开 |
| GET | `/api/banner/list` | 启用的轮播图 | 公开 |

### 管理员

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/api/admin/statistics` | 统计数据（userCount, resourceCount, commentCount, pendingResourceCount） | 管理员 |
| GET | `/api/admin/user/list` | 用户列表（分页，支持 keyword 搜索） | 管理员 |
| PUT | `/api/admin/user/status` | 启用/禁用用户（参数：id, status） | 管理员 |
| DELETE | `/api/admin/user/delete/{id}` | 删除用户 | 管理员 |
| GET | `/api/admin/resource/pending` | 待审核资源 | 管理员 |
| PUT | `/api/admin/resource/audit` | 审核资源（参数：id, status） | 管理员 |
| DELETE | `/api/admin/resource/delete/{id}` | 删除资源 | 管理员 |
| GET | `/api/admin/comment/list` | 评论列表（分页） | 管理员 |
| DELETE | `/api/admin/comment/delete/{id}` | 删除评论 | 管理员 |
| GET | `/api/admin/banner/list` | 轮播图列表（全部，含禁用） | 管理员 |
| POST | `/api/admin/banner/add` | 新增轮播图 | 管理员 |
| PUT | `/api/admin/banner/update` | 编辑轮播图 | 管理员 |
| DELETE | `/api/admin/banner/delete/{id}` | 删除轮播图 | 管理员 |
| PUT | `/api/admin/banner/status` | 启用/禁用轮播图（参数：id, status） | 管理员 |

## 数据库设计

6 张表：`user` · `resource` · `comment` · `favorite` · `banner` · `category`

```
user ──1:N──> resource    (用户上传资源)
user ──1:N──> comment     (用户发表评论)
user ──1:N──> favorite    (用户收藏资源)
resource ──1:N──> comment (资源下的评论)
resource ──1:N──> favorite(资源被收藏)
category ──1:N──> resource(分类下的资源)
comment ──1:N──> comment  (嵌套回复，通过parent_id自关联)
```

### user 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| username | varchar(50) | 学号/工号（唯一） |
| password | varchar(255) | BCrypt加密密码 |
| role | varchar(20) | 角色：admin/student/teacher（注：注册默认为 user） |
| nickname | varchar(50) | 昵称 |
| avatar_url | varchar(255) | 头像链接 |
| college | varchar(50) | 学院 |
| grade | int | 年级（1-4） |
| status | int | 状态：0禁用 1启用 |
| create_time | datetime | 注册时间 |
| update_time | datetime | 更新时间 |

### resource 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| title | varchar(200) | 资料标题 |
| category_id | bigint | 所属分类ID |
| type | varchar(20) | 类型：document/video/image/other |
| content_url | varchar(500) | 资源地址 |
| description | text | 描述 |
| cover_url | varchar(255) | 封面图链接 |
| upload_user_id | bigint | 上传者ID |
| status | int | 状态：0待审核 1已发布 2已拒绝 |
| view_count | int | 浏览数 |
| like_count | int | 点赞数 |
| favorite_count | int | 收藏数 |
| create_time | datetime | 上传时间 |
| update_time | datetime | 更新时间 |

### comment 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| resource_id | bigint | 资料ID |
| user_id | bigint | 评论人ID |
| content | text | 评论内容 |
| parent_id | bigint | 回复上级评论ID（0为顶级评论） |
| create_time | datetime | 评论时间 |

### favorite 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| user_id | bigint | 用户ID |
| resource_id | bigint | 资料ID |
| create_time | datetime | 收藏时间 |

### banner 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| title | varchar(100) | 轮播图标题 |
| image_url | varchar(255) | 图片链接 |
| link_url | varchar(255) | 跳转链接 |
| sort | int | 排序（越小越靠前） |
| status | int | 状态：0禁用 1启用 |
| create_time | datetime | 创建时间 |

### category 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键自增 |
| name | varchar(50) | 分类名称 |
| sort | int | 排序 |
| create_time | datetime | 创建时间 |

## 安全设计

| 措施 | 实现 |
|------|------|
| 密码加密 | BCrypt 自适应哈希（Spring Security Crypto 5.7.3，封装在 Md5Util 工具类中） |
| 认证 | JWT Token，24h 过期（86400000ms），Authorization Bearer 头传递 |
| 授权 | 后端拦截器校验 JWT + 角色；`/api/admin/**` 仅 admin 可访问 |
| 防用户枚举 | 登录统一返回"用户名或密码错误" |
| 防越权更新 | 个人资料更新使用专用 DTO，不接受 role/status/id 字段 |
| SQL 注入防护 | MyBatis-Plus 参数化查询 |
| CORS | 配置 CorsConfig，允许跨域 |
| 文件上传 | 限制最大 100MB，存储在 uploads 目录 |

## 前端设计规范

### 配色体系

| 用途 | 颜色 | CSS变量 |
|------|------|---------|
| 主色（按钮、链接） | 蓝色 `#2563eb` | `--primary-color` |
| 主色浅 | 亮蓝 `#3b82f6` | `--primary-light` |
| 主色深 | 深蓝 `#1d4ed8` | `--primary-dark` |
| 辅助色 | 灰蓝 `#64748b` | `--secondary-color` |
| 强调色 | 青色 `#06b6d4` | `--accent-color` |
| 成功 | 绿色 `#10b981` | `--success-color` |
| 警告 | 橙色 `#f59e0b` | `--warning-color` |
| 危险 | 红色 `#ef4444` | `--danger-color` |
| 主文字 | 灰蓝黑 `#334155` | `--text-primary` |
| 辅助文字 | 中灰 `#64748b` | `--text-secondary` |
| 浅色文字 | 浅灰 `#94a3b8` | `--text-light` |
| 页面背景 | 淡灰白 `#f8fafc` | `--bg-secondary` |
| 卡片背景 | 白色 `#ffffff` | `--bg-primary` |
| 三级背景 | 浅灰 `#f1f5f9` | `--bg-tertiary` |
| 边框 | 浅灰 `#e2e8f0` | `--border-color` |

### 设计关键词

年轻 · 现代 · 专业 · 简洁好用

### 字体

`'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif`

## 实验要求对照

| 课程要求 | 完成情况 | 说明 |
|---------|---------|------|
| 添加数据 | ✅ | 学生/教师上传资料，管理员添加轮播图 |
| 修改数据 | ✅ | 编辑资料、修改个人资料、修改密码、审核资料 |
| 删除数据 | ✅ | 删除资料、取消收藏、删除评论、删除用户 |
| 全查询 | ✅ | 资源广场分页展示全部已发布资源 |
| 条件模糊查询 | ✅ | 按标题关键词模糊搜索，按课程分类筛选 |
| 至少 1 张表 6 字段 | ✅ | user(11 字段)、resource(14 字段) 等 6 张表 |
| 不少于 10 个界面 | ✅ | 14 个页面（含 4 个管理页 + 3 个个人中心 + 404） |
| SpringBoot + MyBatis-Plus | ✅ | SpringBoot 2.7.18 + MyBatis-Plus 3.5.5 |
| Vue3 + Element-Plus | ✅ | Vue 3.4.21 + Element Plus 2.6.1 |
| 进阶：3 表关联 | ✅ | resource JOIN user JOIN category（三表联查） |
| 进阶：ECharts 可视化 | ✅ | 管理端数据看板柱状图/饼图 |
| 进阶：评论嵌套 | ✅ | parent_id 自关联，服务端构建树形结构返回 |
| 进阶：多角色权限 | ✅ | admin/student/teacher 三角色，JWT + 角色鉴权 |
| 进阶：BCrypt 加密 | ✅ | Spring Security BCryptPasswordEncoder（封装为 Md5Util） |
| 进阶：演示数据 | ✅ | 8 用户 + 12 分类 + 14 资源 + 17 评论 + 12 收藏 + 3 轮播图 |

## 课堂演示建议流程

### 未登录体验（3 分钟）

1. 打开首页，展示深色 Hero 区域和统计数据
2. 点击年级学期按钮（如"大二上"），展示对应课程列表
3. 点击课程卡片跳转资源广场，展示分页和条件筛选
4. 点击资源详情，展示资料信息、评论（含嵌套回复）和统计数据
5. 尝试上传/点赞/收藏 → 触发登录提示

### 学生端（5 分钟）

6. 用 `20240001 / 123456` 登录
7. 上传一个学习资料（演示文件上传）→ 提示"等待审核"
8. 浏览资源，点赞、收藏、发表评论和回复
9. 进入个人中心 → 查看"我的资料""我的收藏""个人资料"

### 管理员端（5 分钟）

10. 用 `admin / 123456` 登录 → 自动跳转管理后台
11. 数据看板 → ECharts 图表展示
12. 资料审核 → 将学生刚上传的资料"通过"
13. 用户管理 → 禁用/启用账号（演示 `20240004` 孙七）
14. 轮播图管理 → 新增一张轮播图
15. 回到首页验证轮播图生效、资料已出现在广场

### 权限验证（2 分钟）

16. 学生账号访问 `/admin/dashboard` → 跳转首页，无权限
17. 未登录访问 `/upload` → 重定向到登录页，登录后自动返回

## 已知问题与注意事项

| 问题 | 说明 |
|------|------|
| Md5Util 命名误导 | `Md5Util` 类实际使用 BCrypt 加密，非 MD5。历史命名遗留，功能正确 |
| 注册默认角色 | 注册接口默认设置 role 为 `"user"`，预置数据中使用 `student`/`teacher` |
| 旧版 SQL 脚本 | `sql/neushare.sql` 缺少 category 表，请使用 `init.sql` |
| 逻辑删除配置 | application.yml 配置了 `logic-delete-field: deleted`，但数据库表未添加 deleted 字段，当前未生效 |
| 密码修改 | 修改密码接口使用 MD5 验证旧密码，与登录的 BCrypt 验证不一致（需注意） |

## 许可证

MIT License
