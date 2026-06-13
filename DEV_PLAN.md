# NeuShare 开发计划

> 最后更新：2026-06-13

---

## 已完成 ✓

### P0 — 响应式布局
- [x] 断点检测三通道架构（windowSizeChange + mediaQuery + display 兜底）
- [x] HomeTab 响应式网格（SM=1 / MD=2 / LG=3 / XL=4 列）
- [x] Index 侧边栏导航（手机底部Tab / 平板PC左侧栏 + maxWidth 1400）
- [x] BannerSwiper 桌面端大尺寸（LG=320 / XL=360）
- [x] ResourceCard 双形态（手机横卡 / 桌面方卡）

### P1 — 配色系统重构
- [x] ColorTokens 全量重写（亮色靛蓝毛玻璃 / 深色极简黑白）
- [x] 21 个文件 100+ 处硬编码颜色替换为 ColorTokens
- [x] 向后兼容别名（PRIMARY / TEXT_PRIMARY / BG_PAGE 等）
- [x] 资源类型色系（视频粉 / 书籍蓝 / 软件青 / 教程绿 / 默认灰）

### P2 — 视觉观感 + 动画
- [x] ResourceCard TransitionEffect（淡入 + 弹性缩放）
- [x] PC 端 hoverEffect（侧边栏 Highlight + 卡片 Scale）
- [x] 按钮按压动画（120ms FastOutSlowIn scale 反馈）
- [x] 共享元素转场（ResourceCard → DetailPage 封面动画）
- [x] 半模态评论面板（bindSheet 75% 高度 + 拖拽条）
- [x] 沉浸式状态栏（透明背景）
- [x] 点击热区 ≥ 40vp

### P3 — 数据桥接
- [x] 资源/评论/收藏/点赞全部对接后端 API
- [x] 离线 fallback（本地 JSON 兜底）
- [x] 搜索支持 sortBy=hot|new
- [x] 关注/通知/审核系统到位
- [x] 119 条真实课程链接种子数据

### P4 — 跳转修复
- [x] Web 端 /upload/:id 路由补全
- [x] 鸿蒙端 Banner 跳转区分 categoryId / 外部 URL
- [x] 社区帖子跳转传递 highlightPostId
- [x] SearchBar 搜索关键词传递
- [x] 已删除资源的收藏列表过滤

---

## 待开发

### 阶段五：社区动画微交互

| # | 功能 | 说明 |
|---|------|------|
| 1 | 点赞弹跳动画 | 点赞时 emoji 弹簧放大回弹（curves.springMotion） |
| 2 | 帖子列表交错入场 | 卡片依次淡入 + slide-up，间隔 60ms |
| 3 | 标签筛选脉冲 | 选中标签时 springMotion 回弹反馈 |
| 4 | 空状态呼吸动画 | 空列表 emoji 缓慢缩放 1→1.08，EaseInOut 2s 循环 |
| 5 | 文件附加弹出 | 选完文件后附件卡片 scale(0.5→1) + opacity 过渡 |

### 阶段六：功能补全

| # | 功能 | 端 | 说明 |
|---|------|------|------|
| 6 | `/api/resource/list` 加 sortBy | 后端 | ORDER BY like_count / create_time |
| 7 | 社区功能对接后端 | 全栈 | PostController + post 表 + 鸿蒙 API 调用 |
| 8 | UserProfilePage 调 API | 鸿蒙 | GET /api/user/{id} 获取完整资料 |
| 9 | ProfileTab 加粉丝/关注数 | 鸿蒙 | FollowApi 统计数据 |
| 10 | 新建关注/粉丝列表页 | 鸿蒙 | Tab 切换"我关注的"/"关注我的" |
| 11 | UserProfileVO 加 totalLikesReceived | 后端 | 用户主页显示总获赞数 |
| 12 | Web 端点赞状态持久化 | Web | mounted() 调 checkLiked API |
| 13 | 帖子详情页 | 鸿蒙 | 帖子全文 + 评论树 + 点赞收藏 |
| 14 | 通知列表加触发者信息 | 后端 | LEFT JOIN user 查昵称头像 |

### 阶段七：优化打磨

| # | 功能 | 说明 |
|---|------|------|
| 15 | 通知单条删除 + 按类型筛选 | DELETE /api/notification/{id} + type 参数 |
| 16 | 收藏列表返回收藏时间 | FavoriteMapper.xml 加 f.create_time |
| 17 | 帖子编辑/删除 | 自己的帖子可编辑删除 |
| 18 | 用户统计性能优化 | 冗余字段 + 定时同步校准 |
| 19 | 毛玻璃性能分级 | 滚动时关闭 blur / 低端设备降级为纯色 |
| 20 | 深色模式组件适配 | TypeTag 字母缩写 / 小圆点星空 / 全页面 dark 验证 |

---

## 文档清单

| 文件 | 用途 |
|------|------|
| `README.md` | 项目总览 + 快速开始 + 技术栈 |
| `CLAUDE.md` | 开发规范 + API 清单 + 前后端约定 |
| `DEV_PLAN.md` | 当前文件：开发计划 + 进度跟踪 |
| `docs/配色美化方案.md` | 设计系统规范：亮色/深色双主题全部色值 |
| `docs/HarmonyOS-一次开发多端部署-UI设计教程.md` | 鸿蒙一多开发教程参考 |
| `docs/HarmonyOS-功能开发教程.md` | 鸿蒙功能开发教程参考 |
