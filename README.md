# NeuShare — 校园资料分享平台

东北大学软件学院 · Web开发技术大作业 · SpringBoot + Vue3 前后端分离项目

## 项目概述

面向东北大学师生的学习资料共享平台。支持按年级学期快速查找课程资料，提供资料上传、浏览、搜索、评论、点赞、收藏等功能，同时具备管理员审核、用户管理和数据统计后台。

## 技术架构

```
┌─────────────────────────────────────┐
│         前端 (Vue3 + Vite)          │
│  Element-Plus · Pinia · Vue Router  │
│  Axios · ECharts · localhost:3000   │
└──────────────┬──────────────────────┘
               │ REST API (JWT)
┌──────────────▼──────────────────────┐
│        后端 (SpringBoot 2.7)        │
│  MyBatis-Plus · BCrypt · JWT        │
│  localhost:8080                     │
└──────────────┬──────────────────────┘
               │ JDBC
┌──────────────▼──────────────────────┐
│          MySQL 8.0                  │
│  6张表 · 多表关联查询               │
└─────────────────────────────────────┘
```

| 层级 | 技术 |
|------|------|
| 前端 | Vue3 + Vite + Element-Plus + Pinia + ECharts + Vue Router |
| 后端 | SpringBoot 2.7 + MyBatis-Plus + JWT + BCrypt |
| 数据库 | MySQL 8.0 |
| 设计 | 极简白底 · 蓝色主题(#2563eb) · 玻璃拟态导航 |

## 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| JDK | 8+ | Java 运行时 |
| Maven | 3.6+ | 后端构建工具 — 管理依赖(MyBatis-Plus、JWT、BCrypt等)、编译打包、启动 SpringBoot |
| MySQL | 8.0 | 数据库 |
| Node.js | 16+ | 前端运行时 |
| npm | 8+ | 前端包管理器 |

> Maven 是 Java 项目的构建工具（类似前端的 npm），`pom.xml` 相当于 `package.json`。项目中所有 `.jar` 依赖由 Maven 自动下载，无需手动管理。启动后端时用 `mvn spring-boot:run`，打包部署用 `mvn package -DskipTests`。

### Maven 配置（Windows）

```bash
# 解压 Maven 到纯英文路径（中文路径会导致 Git Bash 中 PATH 失效）
# 编辑 ~/.bashrc，添加：
export MAVEN_HOME="E:/apache-maven-3.6.1"
export PATH="$MAVEN_HOME/bin:$PATH"
```

## 快速启动

```bash
# 0. 确认 Maven 可用
mvn --version

# 1. 初始化数据库
mysql -u root -p < neushare-backend/src/main/resources/db/init.sql

# 2. 配置数据库密码（修改 application.yml）
# 3. 启动后端
cd neushare-backend
mvn spring-boot:run

# 4. 启动前端
cd neushare-frontend
npm install
npm run dev
```

访问 http://localhost:3000

## 测试账号

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 管理员 | admin | 123456 |
| 学生 | 20240001 | 123456 |
| 教师 | T20240001 | 123456 |

## 功能模块

| 模块 | 功能 |
|------|------|
| 首页 | 年级/学期筛选、热门资料、推荐课程 |
| 资源列表 | 分类筛选、关键词搜索、分页浏览 |
| 资源详情 | 文件下载、浏览量统计、点赞 |
| 评论互动 | 树形评论、父子回复 |
| 收藏系统 | 收藏/取消收藏、收藏列表 |
| 上传管理 | 文件上传、资料编辑删除 |
| 个人中心 | 信息维护、密码修改、我的资源/收藏/评论 |
| 管理后台 | 数据统计(ECHarts)、资料审核、用户管理、轮播图管理 |

## 项目结构

```
web/
├── neushare-backend/                        # SpringBoot后端
│   └── src/main/
│       ├── java/com/neushare/
│       │   ├── controller/                  # 7个控制器
│       │   ├── service/impl/                # 服务层
│       │   ├── mapper/                      # MyBatis-Plus映射器
│       │   ├── entity/                      # 数据库实体
│       │   ├── dto/ / vo/                  # 数据传输/视图对象
│       │   ├── config/                      # CORS、分页、拦截器配置
│       │   ├── interceptor/                 # JWT鉴权拦截器
│       │   └── util/                        # JWT、BCrypt、文件上传工具
│       └── resources/db/init.sql            # 数据库初始化脚本
├── neushare-frontend/                       # Vue3前端
│   └── src/
│       ├── api/                             # 8个Axios请求模块
│       ├── views/                           # 17个页面组件
│       │   └── admin/                       # 管理后台4页面
│       ├── components/                      # 4个通用组件
│       ├── router/ / store/                # 路由 + Pinia状态
│       ├── styles/global.css               # CSS变量 + 全局样式
│       └── utils/                           # 常量、格式化、课程数据
└── README.md
```

## 实验要求对照

### 基本要求（30分）

| 要求 | 说明 |
|------|------|
| 添加数据 | 资源上传、评论发表、收藏添加、轮播图/用户管理 |
| 修改数据 | 资源编辑、个人信息修改、密码修改、状态切换 |
| 删除数据 | 资源/评论/轮播图/用户删除（含确认提示） |
| 全查询 | 资源列表、用户列表、评论列表、轮播图管理 |
| 模糊查询 | 资源关键词搜索、用户搜索、分类筛选 |
| 数据库 | 6张表，每表6+字段，主键/外键/唯一约束完整 |
| 界面设计 | 17个独立页面，极简白底设计风格 |
| 技术栈 | SpringBoot + MyBatis-Plus + Vue3 + Element-Plus |

### 进阶要求（创新加分）

| 要求 | 说明 |
|------|------|
| 额外功能模块 | 评论(树形)、收藏、点赞 — 模块间互相关联 |
| 多表关联(3张+) | user、resource、comment、favorite 等多表连接查询 |
| ECharts可视化 | Dashboard 柱状图(上传趋势) + 饼图(分类分布) |

### 拓展要求

| 要求 | 完成情况 |
|------|----------|
| 软硬结合 | 未实现 |
| 微服务架构 | 未实现 |
| 容器化部署 | 未实现 |

## 许可证

MIT License
