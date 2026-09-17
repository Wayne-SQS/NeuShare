# NeuShare 开发计划

> 最后更新：2026-06-14

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

### 阶段五：社区动画微交互 ✓
- [x] 点赞弹跳动画（curves.springMotion）
- [x] 帖子列表交错入场（淡入 + slide-up，间隔 60ms）
- [x] 标签筛选脉冲（springMotion 回弹反馈）
- [x] 空状态呼吸动画（缓慢缩放 1→1.08，2s 循环）
- [x] 文件附加弹出（scale 0.5→1 + opacity 过渡）

### 阶段六：功能补全 ✓
- [x] `/api/resource/list` 加 sortBy（ORDER BY like_count / create_time）
- [x] 社区功能对接后端（PostController + post 表 + 鸿蒙 API 调用）
- [x] UserProfilePage 调 API（GET /api/user/{id}）
- [x] ProfileTab 加粉丝/关注数（FollowApi 统计数据）
- [x] 新建关注/粉丝列表页（Tab 切换"我关注的"/"关注我的"）
- [x] UserProfileVO 加 totalLikesReceived
- [x] Web 端点赞状态持久化（mounted() 调 checkLiked API）
- [x] 帖子详情页（帖子全文 + 评论树 + 点赞收藏）
- [x] 通知列表加触发者信息（LEFT JOIN user 查昵称头像）

### 阶段七：优化打磨 ✓
- [x] 通知单条删除 + 按类型筛选（DELETE /api/notification/{id} + type 参数）
- [x] 收藏列表返回收藏时间（FavoriteMapper.xml 加 f.create_time）
- [x] 帖子编辑/删除（自己的帖子可编辑删除）
- [x] 用户统计性能优化（冗余字段 resource_count/follower_count/following_count/total_likes_received + 定时校准 + 实时原子更新）
- [x] 毛玻璃性能分级（BlurPerformance 工具类 + 滚动时关闭 blur + 降级纯色）
- [x] 深色模式组件适配（textOnPrimary 方法 + 60+ 处硬编码修复 + ColorDot 星空闪烁）

### 阶段八：审查修复 ✓
- [x] FollowApi 参数名修复（userId→followedId + postWithParams + deleteWithParams）
- [x] 删除帖子评论递减 comment_count（PostCommentServiceImpl 原子更新）
- [x] StatsPage 路由注册（main_pages.json）
- [x] WebMvcConfig /api/user/** → 精确路径（/api/user/* + /api/user/*/resources）
- [x] 公开接口 status 参数安全加固（非管理员强制 status=1）
- [x] HttpClient 401 竞态修复（Promise 锁替代 boolean 标志）+ 错误信息保留
- [x] CounterCalibrationTask 分页 + dirty flag + SQL SUM 优化
- [x] ResourceApi 返回类型修复（search/getUserResources 数组→分页 + 新增 checkLiked）
- [x] FollowApi.check 返回类型修复（boolean→{isFollowing}）
- [x] CommentApi 删除 getUserComments 死方法
- [x] NotificationApi 创建（5 个端点对齐 NotificationController）
- [x] HttpClient 新增 deleteWithParams 方法
- [x] PageData 接口统一到 common 模块
- [x] FollowListPage userId 死代码清理

---

## 待开发

（暂无新计划，根据需求迭代）
