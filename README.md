# NeuShare — 东北大学校园学习资料分享平台

> 全栈项目：Vue 3 Web 端 + Spring Boot 3 后端 + HarmonyOS 移动端 + Docker 部署

![tech](https://img.shields.io/badge/Vue-3.4-brightgreen) ![tech](https://img.shields.io/badge/Spring%20Boot-3.3-blue) ![tech](https://img.shields.io/badge/HarmonyOS-NEXT-orange) ![tech](https://img.shields.io/badge/Docker-ready-2496ED) ![tech](https://img.shields.io/badge/license-MIT-green)

---

## 项目简介

东北大学软件学院学习资料分享平台。学生和教师可以上传、搜索、浏览、评论、点赞、收藏课程资料，管理员负责审核资源和用户管理。

### 三端架构

```
        ┌──────────────────────────────────────────┐
        │           NeuShare Platform              │
        ├──────────────┬────────────┬──────────────┤
        │  🌐 Web      │  ☕ API    │  📱 App      │
        │  Vue 3       │  Spring   │  HarmonyOS   │
        │  :80         │  :8080    │  NEXT        │
        └──────────────┴────────────┴──────────────┘
                        │
                    🗄️ MySQL 8
```

| 端 | 技术栈 | 说明 |
|----|--------|------|
| **Web 前端** | Vue 3 + Vite + Element Plus + Pinia + ECharts | SPA 应用，含用户端 + 管理后台 |
| **后端 API** | Spring Boot 3.3.7 + MyBatis-Plus 3.5.13 + JWT | RESTful API，角色权限 + 通知系统 |
| **移动端** | HarmonyOS NEXT + ArkUI + ArkTS | 鸿蒙原生应用，3 层 HAR 架构，5 级断点适配 |
| **数据库** | MySQL 8 | 10 张表，预置种子数据 |
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
npm run dev          # → localhost:5173，API 代理到 :8080

# 后端 (需要 JDK 17+)
cd neushare-backend
mvn spring-boot:run  # → localhost:8080

# 鸿蒙 App
# 用 DevEco Studio 打开项目根目录，Sync → Run
```

---

## 功能矩阵

| 功能 | Web | 鸿蒙 App | 说明 |
|------|:---:|:--------:|------|
| 资源浏览/搜索 | ✅ | ✅ | 分类浏览 · 关键词搜索 · 热门推荐 · 排序 |
| 资源上传 | ✅ | — | FormData 文件上传 |
| 用户注册/登录 | ✅ | ✅ | JWT 认证 · BCrypt 加密 |
| 评论系统 | ✅ | — | 树形评论 · 回复 |
| 点赞系统 | ✅ | ✅ | 防重复 · 定时校准计数 |
| 收藏系统 | ✅ | ✅ | 收藏/取消 · 本地持久化 |
| 关注系统 | ✅ | — | 用户关注/取关 |
| 通知系统 | ✅ | — | 评论回复 · 审核结果 · 点赞 · 收藏 · 关注 |
| 浏览历史 | — | ✅ | 自动记录最近 20 条 |
| 个人中心 | ✅ | ✅ | 个人信息 · 我的资源 · 修改密码 |
| 管理后台 | ✅ | — | 仪表板 · 审核 · 用户管理 · 轮播图 · 服务卡片 |
| AI 模型对比 | — | ✅ | DeepSeek/Claude/GPT 等 10 款模型价格+评分 |
| 学习社区 | — | ✅ | 发帖 · 评论 · 点赞 · 收藏 |
| 考研指南 | — | ✅ | 报名流程 · 科目攻略 |
| 多设备适配 | ✅ | ✅ | Phone · Tablet · Desktop 5 级断点 |
| 意图框架 | — | ✅ | 小艺助手语音搜索 |

---

## 项目结构

```
NeuShare/
├── neushare-frontend/          # Vue 3 Web 前端
│   └── src/
│       ├── api/                # Axios 请求模块 (auth, resource, comment, favorite, admin, banner)
│       ├── components/         # Header, Footer, ResourceCard, Sidebar
│       ├── views/              # Home, ResourceDetail, Upload, Login, Register, NotFound
│       │   ├── profile/        # 个人中心 (ProfileInfo, MyResources, MyFavorites)
│       │   └── admin/          # 管理后台 (Dashboard, Audit, UserManage, BannerManage)
│       ├── router/             # Vue Router + beforeEach 导航守卫
│       ├── store/              # Pinia 状态管理 (user)
│       └── utils/              # 常量 · 格式化 · 课程数据
│
├── neushare-backend/           # Spring Boot 后端
│   └── src/main/java/com/neushare/
│       ├── controller/         # 8 个 REST 控制器
│       ├── service/            # 业务逻辑层 (含 NotificationService)
│       ├── mapper/             # MyBatis-Plus BaseMapper + 自定义 XML
│       ├── entity/             # 10 个实体类
│       ├── dto/                # 数据传输对象
│       ├── vo/                 # 视图对象
│       ├── config/             # CORS · 分页插件 · WebMvcConfig
│       ├── interceptor/        # JWT 校验 + 管理员权限
│       ├── task/               # 定时任务 (计数器校准)
│       └── util/               # JWT · BCrypt · 文件上传
│
├── common/                     # 鸿蒙公共 HAR
│   └── src/main/ets/
│       ├── theme/              # ColorTokens · AppTheme (深色模式)
│       ├── components/         # EmptyState · Skeleton
│       ├── network/            # HttpClient · AuthStore
│       ├── services/           # PreferencesStore
│       └── utils/              # BreakpointSystem (5 级断点) · ResourceTypeUtils
│
├── entry/                      # 鸿蒙应用入口
│   └── src/main/ets/
│       ├── pages/              # 14 个页面 + 4 个 Tab
│       │   └── tabs/           # HomeTab · CategoryTab · SearchTab · ProfileTab
│       ├── components/         # ResourceCard · BannerSwiper · CategoryCard 等
│       ├── services/           # ResourceService · FavoriteService · CommunityService
│       ├── models/             # 数据模型 + ArrayDataSource
│       ├── data/               # 119 条真实链接资源 (B站/中国大学MOOC/GitHub/豆瓣/Coursera)
│       ├── api/                # API 调用层
│       └── entryability/       # EntryAbility (意图处理 + 断点注册)
│
└── neushare-backend/src/main/resources/db/
    └── init.sql                # 数据库初始化脚本
```

---

## API 概览

### 公开接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/login` | 登录 |
| POST | `/api/auth/register` | 注册 |
| GET | `/api/resource/list` | 资源分页 |
| GET | `/api/resource/detail/{id}` | 资源详情 |
| GET | `/api/resource/hot` | 热门资源 |
| GET | `/api/resource/search` | 搜索（支持 `sortBy=hot\|new`） |
| GET | `/api/comment/list/{resourceId}` | 评论树 |
| GET | `/api/banner/list` | 轮播图 |
| GET | `/api/category/list` | 分类列表 |

### 需登录
资源 CRUD · 评论 · 收藏 · 点赞 · 个人信息 · 修改密码 · 通知 · 关注

### 管理员
统计面板 · 资源审核（含驳回理由）· 用户管理 · 轮播图管理 · 服务卡片管理 · 评论管理

> 详细清单见 [CLAUDE.md](./CLAUDE.md)

---

## 数据库

- 库名：`neushare`
- 10 张表：`user` · `resource` · `category` · `comment` · `favorite` · `banner` · `form_card` · `resource_like` · `notification` · `follow`
- 预置：8 个用户 · 12 个分类 · 14 个资源 · 17 条评论 · 12 条收藏 · 3 张轮播图
- 支持：父子分类 · 通知推送 · 计数器校准 · 级联删除
- 初始化：`docker-compose up` 自动执行 `init.sql`

---

## 鸿蒙 App 特色

- 🎨 **Warm Academia 设计** — 暖纸白底色 + 深海蓝主色 + 琥珀点缀
- 🫧 **Glassmorphism 卡片** — 微边框玻璃态 + 多层阴影
- 📐 **5 级断点适配** — XS / SM / MD / LG / XL，手机/平板/PC 自适应
- 🧭 **侧边栏导航** — 平板/PC 端左侧 Sidebar，手机端底部 Tab
- 🎯 **Spring 弹性动效** — 按下缩放反馈 + 弹簧动画
- 🔍 **即时搜索** — 标签云 · 排序 · 分类筛选
- 🔗 **119 条真实链接** — B站 · 中国大学MOOC · GitHub · 豆瓣 · Coursera
- 🤖 **AI 模型价格对比** — 10 款主流大模型价格 + 四维评分雷达图
- 🎓 **考研指南** — 大三/大四专属，报名流程 · 科目攻略
- 💬 **学习社区** — 发帖 · 点赞 · 收藏 · 热门推荐
- 🔐 **自动登录** — 记住密码 + Token 有效免开屏

---

## 安全特性

- JWT 鉴权 + 角色权限（user / admin）
- BCrypt 密码加密
- 资源归属校验（非上传者/管理员不可操作）
- CORS 限制 localhost 来源
- 敏感配置环境变量注入（`DB_PASSWORD`、`JWT_SECRET`）
- 防重复点赞/关注（唯一约束）

---

## License

MIT © NEU Software College
