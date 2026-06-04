# NeuShare — 东北大学校园学习资料分享平台

> 全栈项目：Vue 3 Web 端 + Spring Boot 后端 + HarmonyOS 移动端 + Docker 部署

![tech](https://img.shields.io/badge/Vue-3.4-brightgreen) ![tech](https://img.shields.io/badge/Spring%20Boot-2.7-blue) ![tech](https://img.shields.io/badge/HarmonyOS-NEXT-orange) ![tech](https://img.shields.io/badge/Docker-ready-2496ED)

---

## 项目简介

东北大学（NEU）软件学院学习资料分享平台。学生和教师可以上传、搜索、浏览、评论、收藏课程资料，管理员负责审核资源和用户管理。

### 三端架构

```
        ┌──────────────────────────────────┐
        │         NeuShare Platform         │
        ├────────────┬──────────┬───────────┤
        │  🌐 Web    │  ☕ API  │  📱 App   │
        │  Vue 3     │  Spring  │ HarmonyOS │
        │  :80       │  :8080   │  NEXT     │
        └────────────┴──────────┴───────────┘
                      │
                  🗄️ MySQL 8
```

| 端 | 技术栈 | 说明 |
|----|--------|------|
| **Web 前端** | Vue 3 + Vite + Element Plus + Pinia | SPA 应用，含用户端 + 管理后台 |
| **后端 API** | Spring Boot 2.7 + MyBatis-Plus + JWT | RESTful API，角色权限控制 |
| **移动端** | HarmonyOS NEXT + ArkUI + ArkTS | 鸿蒙原生应用，三层HAR架构 |
| **数据库** | MySQL 8 | 6 张表，预置种子数据 |
| **部署** | Docker Compose | 一键启动全套服务 |

---

## 快速开始

### Docker 部署（推荐）

```bash
docker-compose up -d
```

- Web 前端：http://localhost
- 后端 API：http://localhost:8080

### 本地开发

```bash
# 前端
cd neushare-frontend
npm install
npm run dev          # → localhost:3000

# 后端
cd neushare-backend
mvn spring-boot:run  # → localhost:8080

# 鸿蒙 App
# 用 DevEco Studio 打开项目根目录，Sync → Run
```

---

## 功能矩阵

| 功能 | Web | 鸿蒙 App | 说明 |
|------|:---:|:--------:|------|
| 资源浏览/搜索 | ✅ | ✅ | 分类浏览 · 关键词搜索 · 热门推荐 |
| 资源上传 | ✅ | — | 支持文件上传 + FormData |
| 用户注册/登录 | ✅ | — | JWT 认证 · BCrypt 密码 |
| 评论系统 | ✅ | — | 树形评论 · 点赞 |
| 收藏夹 | ✅ | ✅ | 收藏/取消 · 本地持久化 |
| 浏览历史 | — | ✅ | 自动记录最近 20 条 |
| 个人中心 | ✅ | ✅ | 个人信息 · 我的资源 |
| 管理后台 | ✅ | — | 审核 · 用户管理 · 轮播图 · 统计 |
| AI 模型对比 | — | ✅ | DeepSeek/Claude/GPT 价格+性能 |
| Banner 轮播 | ✅ | ✅ | 东大校园实拍图 |
| 响应式适配 | ✅ | ✅ | Phone + Tablet + Desktop |

---

## 项目结构

```
NeuShare/
├── neushare-frontend/        # Vue 3 Web 前端
│   ├── src/
│   │   ├── api/              # 9 个 Axios API 模块
│   │   ├── components/       # Header, Footer, ResourceCard, Sidebar
│   │   ├── views/            # Home, ResourceDetail, Upload, Login...
│   │   │   ├── profile/      # 个人中心子页面
│   │   │   └── admin/        # 管理后台子页面
│   │   ├── router/           # Vue Router + 导航守卫
│   │   ├── store/            # Pinia 状态管理
│   │   └── utils/            # 工具函数 + 常量
│   └── public/images/banner/ # 东大校园实拍轮播图
│
├── neushare-backend/         # Spring Boot 后端
│   └── src/main/java/com/neushare/
│       ├── controller/       # 8 个 REST 控制器
│       ├── service/          # 业务逻辑层
│       ├── mapper/           # MyBatis-Plus 数据访问
│       ├── entity/           # 6 个 JPA 实体
│       ├── dto/              # 数据传输对象
│       ├── config/           # CORS · 分页 · 拦截器
│       ├── interceptor/      # JWT 校验 · 角色权限
│       └── util/             # JWT · BCrypt · 文件上传
│
├── common/                   # 🔹 鸿蒙公共层
│   └── src/main/ets/
│       ├── theme/            # ColorTokens · AppTheme
│       ├── components/       # Skeleton · EmptyState
│       └── utils/            # 断点系统 · 防抖 · 懒加载
│
├── features/                 # 🔹 鸿蒙业务层
│   └── src/main/ets/
│       ├── browse/           # 资源浏览模块
│       ├── search/           # 搜索检索模块
│       ├── user/             # 用户管理模块
│       └── compare/          # 模型对比模块
│
├── entry/                    # 🔹 鸿蒙入口
│   └── src/main/ets/
│       ├── pages/            # 6 个页面
│       ├── components/       # 6 个业务组件
│       ├── services/         # DataService · FavoriteService
│       ├── models/           # 数据模型
│       └── data/             # 119 条真实链接资源
│
└── sql/                      # 数据库脚本
```

---

## API 概览

### 公开接口
`POST /api/auth/login` · `POST /api/auth/register` · `GET /api/resource/list` · `GET /api/resource/detail/{id}` · `GET /api/resource/hot` · `GET /api/resource/search` · `GET /api/comment/list/{resourceId}` · `GET /api/banner/list` · `GET /api/category/list`

### 需登录
资源 CRUD · 评论 · 收藏 · 点赞 · 个人信息 · 修改密码

### 管理员
统计面板 · 资源审核 · 用户管理 · 轮播图管理 · 评论管理

> 详细清单见 [CLAUDE.md](./CLAUDE.md)

---

## 鸿蒙 App 特色

- 🎨 **Warm Academia 设计** — 暖纸白底色 + 深海蓝主色 + 琥珀点缀
- 🫧 **Glassmorphism 卡片** — 微边框玻璃态 + 多层阴影
- 🎯 **Spring 弹性动效** — 按下缩放反馈 + 弹簧动画
- 🔍 **即时搜索** — 零延迟，每敲一个字立刻出结果
- 🔗 **119 条真实链接** — B站 · 中国大学MOOC · GitHub · 豆瓣 · Coursera
- 🤖 **AI 模型价格对比** — 10 款主流大模型实时价格 + 四维评分

---

## 数据库

- 库名：`neushare`
- 6 张表：`user` · `resource` · `category` · `comment` · `favorite` · `banner`
- 预置 12 个分类 · 14 个资源 · 3 张轮播图
- 初始化：`docker-compose up` 自动执行 `init.sql`

---

## License

MIT © NEU Software College
