# NeuShare — 东北大学校园学习资料分享平台

> 全栈项目：Vue 3 Web 端 + Spring Boot 3 后端 + HarmonyOS 移动端

---

## 项目简介

东北大学软件学院学习资料分享平台。学生/教师可上传、搜索、浏览、评论、点赞、收藏课程资料，管理员审核资源和用户管理。

### 三端架构

```
        ┌──────────────────────────────────────────┐
        │           NeuShare Platform              │
        ├──────────────┬────────────┬──────────────┤
        │  🌐 Web      │  ☕ API    │  📱 App      │
        │  Vue 3       │  Spring   │  HarmonyOS   │
        │  :5173       │  :8080    │  NEXT        │
        └──────────────┴────────────┴──────────────┘
                        │
                    🗄️ MySQL 8
```

| 端 | 技术栈 | 说明 |
|----|--------|------|
| **Web 前端** | Vue 3 + Vite 5 + Element Plus + Pinia + ECharts | SPA 应用，用户端 + 管理后台 |
| **后端 API** | Spring Boot 3.3.7 + MyBatis-Plus 3.5.13 + JWT | RESTful，角色权限 + 通知系统 |
| **移动端** | HarmonyOS NEXT + ArkUI + ArkTS | 鸿蒙原生，3 层 HAR 架构，5 级断点 |
| **数据库** | MySQL 8 | 10 张表，预置种子数据 |

---

## 快速开始

```bash
# Web 前端
cd neushare-frontend
npm install && npm run dev        # → localhost:5173

# 后端 (JDK 17+)
cd neushare-backend
mvn spring-boot:run              # → localhost:8080

# 鸿蒙 App
# DevEco Studio 打开项目根目录 → Sync → Run
```

---

## 功能矩阵

| 功能 | Web | 鸿蒙 | 说明 |
|------|:---:|:----:|------|
| 资源浏览/搜索 | ✅ | ✅ | 分类 · 关键词 · 热门 · 排序 |
| 资源上传 | ✅ | ✅ | 链接分享 + 分类标签 |
| 用户注册/登录 | ✅ | ✅ | JWT + BCrypt |
| 评论系统 | ✅ | ✅ | 树形评论 + 回复 |
| 点赞/收藏 | ✅ | ✅ | 防重复 + 定时校准 |
| 关注系统 | ✅ | — | 用户关注/取关 |
| 通知系统 | ✅ | — | 审核结果 · 回复 · 点赞 · 关注 |
| 个人中心 | ✅ | ✅ | 资料 · 资源 · 收藏 · 历史 |
| 管理后台 | ✅ | — | 仪表板 · 审核 · 用户 · 轮播图 |
| 学习社区 | — | ✅ | 发帖 · 点赞 · 收藏 · 热门 |
| 考研指南 | — | ✅ | 报名流程 · 科目攻略 |
| AI 模型对比 | — | ✅ | 10 款大模型价格 + 评分 |
| 身份卡片 | — | ✅ | 年级设置 + 课程推荐 |
| 多设备适配 | ✅ | ✅ | Phone · Tablet · Desktop 5 级断点 |
| 意图框架 | — | ✅ | 小艺助手语音搜索 |

---

## 项目结构

```
NeuShare/
├── neushare-frontend/          # Vue 3 Web 前端
│   └── src/
│       ├── api/                # Axios 请求模块
│       ├── components/         # Header, Footer, ResourceCard, Sidebar
│       ├── views/              # Home, ResourceDetail, Upload, Login
│       │   ├── profile/        # ProfileInfo, MyResources, MyFavorites
│       │   └── admin/          # Dashboard, Audit, UserManage, BannerManage
│       ├── router/             # Vue Router + beforeEach 守卫
│       ├── store/              # Pinia 状态管理
│       └── utils/              # 常量 · 格式化 · 课程数据
│
├── neushare-backend/           # Spring Boot 后端
│   └── src/main/java/com/neushare/
│       ├── controller/         # 8 个 REST 控制器
│       ├── service/            # 业务逻辑层
│       ├── mapper/             # MyBatis-Plus + XML
│       ├── entity/ dto/ vo/    # 数据对象
│       ├── config/             # CORS · 分页 · WebMvc
│       ├── interceptor/        # JWT + 管理员权限
│       └── util/               # JWT · BCrypt · 文件上传
│
├── common/                     # 鸿蒙公共 HAR
│   └── src/main/ets/
│       ├── theme/              # ColorTokens · AppTheme (亮靛蓝/暗黑白双主题)
│       ├── components/         # GlassCard · ColorDot · TypeTag · EmptyState · Skeleton
│       ├── network/            # HttpClient · AuthStore
│       └── utils/              # BreakpointSystem (5级断点) · ResourceTypeUtils
│
├── entry/                      # 鸿蒙应用入口
│   └── src/main/ets/
│       ├── pages/              # 14 个页面 + 4 个 Tab
│       ├── components/         # ResourceCard · BannerSwiper · CategoryCard
│       ├── services/           # ResourceService · FavoriteService · CommunityService
│       ├── models/ api/ data/  # 数据模型 + API 层 + 本地数据
│       └── entryability/       # EntryAbility (意图 + 断点 + 沉浸式状态栏)
│
├── docs/                       # 设计文档
│   ├── 配色美化方案.md          # 亮色靛蓝毛玻璃 / 深色极简黑白
│   ├── HarmonyOS-一次开发多端部署-UI设计教程.md
│   └── HarmonyOS-功能开发教程.md
│
└── CLAUDE.md                   # 项目开发规范 + API 清单
```

---

## 设计系统（2026-06-13 重构）

### 亮色主题 — 靛蓝毛玻璃
- **主色** `#4A6BFF` 清爽靛蓝
- **辅色** 粉 `#FF8FB1` · 黄 `#FFD93D` · 绿 `#6BCB77` · 青 `#00C2CB`
- **背景** `#F4F7FF` 淡蓝白 · 卡片 `#FFFFFFB8` 毛玻璃
- **质感** 多彩渐变 + backdropBlur(40) + 小圆点装饰

### 深色主题 — 极简黑白
- **唯一强调色** `#FFFFFF` 纯白
- **背景** `#0E0E10` 极深灰 · 卡片 `#1C1C1F`
- **零彩色** 全靠白色强度/加粗/边框/小圆点区分层级

> 详细规范见 `docs/配色美化方案.md`

---

## 安全

- JWT 鉴权 + 角色权限（user / admin）
- BCrypt 密码加密
- 资源归属校验（非上传者/管理员不可操作）
- CORS 限制 localhost 来源
- 敏感配置环境变量注入
- 防重复点赞/关注（唯一约束）

---

## License

MIT © NEU Software College
