# NEUShare

> 东北大学软件学院学习资源共享平台 · HarmonyOS NEXT App

## 简介

NEUShare 是一款面向东北大学软件学院的**学习资源聚合平台**，汇集网课、书籍、开发工具、AI 教程、面试题库、课程资料等多种学习资源，帮助学生高效获取和发现优质学习材料。

## 功能

| 功能 | 说明 |
|------|------|
| 🏠 **首页推荐** | Banner 轮播 + 热门资源 + 分类卡片 |
| 📂 **分类浏览** | 10 大分类，覆盖专业课到 AI 工具 |
| 🔍 **全文搜索** | 按标题、标签、描述、作者搜索 |
| ❤️ **收藏 & 历史** | 本地持久化收藏夹和浏览历史 |
| 🤖 **AI 模型对比** | 主流大模型 API 价格与性能横向对比 |
| 👤 **个人中心** | 收藏数、历史纪录统计 |

## 10 大资源分类

| 分类 | 内容 |
|------|------|
| 🎬 专业课网课资源 | MOOC、B 站课程 |
| 📖 专业课推荐书籍 | 豆瓣高分编程书 |
| 💻 先进编程软件 | IDE、Docker、Git 等工具 |
| 🤖 AI 与 Git 教程 | DeepSeek/Claude API、GitHub |
| 📐 数学题库与算法 | LeetCode、ACM 竞赛 |
| 📚 课上教材资源 | 课件 PPT、期末真题 |
| 🖥️ 应用教学软件 | 希沃白板、雨课堂 |
| 🧠 DeepSeek API | API 文档与实战 |
| 🔧 GitHub 教程 | Git → PR → CI/CD |
| ☕ JAVA 教程 | 基础 → 微服务全栈 |

## 技术栈

- **平台**: HarmonyOS NEXT (API 9+)
- **语言**: ArkTS
- **UI 框架**: ArkUI 声明式
- **架构**: 三层 HAR 模块化 (`common` → `features` → `entry`)
- **设备**: Phone + Tablet

## 项目结构

```
NEUShare/
├── common/              # 公共能力层：UI 组件库、主题、工具类
│   └── src/main/ets/
│       ├── components/  # Skeleton、EmptyState 等通用组件
│       ├── theme/       # ColorTokens、AppTheme
│       └── utils/       # Breakpoint、Debounce、LazyDataSource
├── features/            # 业务特性层：浏览、搜索、用户、对比
│   └── src/main/ets/
│       ├── browse/      # BrowseModule
│       ├── search/      # SearchModule
│       ├── user/        # UserModule
│       └── compare/     # CompareModule
├── entry/               # 应用入口层
│   └── src/main/ets/
│       ├── pages/       # 6 个页面
│       ├── components/  # 5 个业务组件
│       ├── models/      # 数据模型
│       ├── services/    # 数据服务、收藏服务
│       └── data/        # JSON 数据源
└── AppScope/            # 应用配置
```

## 构建 & 运行

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)
2. 克隆项目并导入
3. 配置签名（File → Project Structure → Signing Configs）
4. 连接 HarmonyOS 设备或启动模拟器
5. Run

## 贡献

欢迎 PR 和 Issue！请遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

## License

MIT © NEU Software College
