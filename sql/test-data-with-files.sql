-- ============================================================
-- NeuShare 测试数据补充脚本（含真实可下载文件）
-- 用途：测试关注、点赞、评论、收藏、文件下载功能
-- 执行方式：mysql -u root -p neushare < test-data-with-files.sql
-- ============================================================

USE neushare;

-- ==================== 带真实文件的可下载资源 ====================
-- 文件存储在 uploads/ 目录，通过 /files/{filename} 访问下载
-- 注意：ID 从 87 开始，避免与现有数据冲突（init.sql 资源 ID 1-86）

INSERT INTO `resource` (`title`, `category_id`, `type`, `content_url`, `description`, `source`, `upload_user_id`, `status`, `view_count`, `like_count`, `favorite_count`, `create_time`) VALUES
-- 资源87: 高数笔记 PDF（真实文件）
('高等数学期末复习笔记(手写版)', 1, 'document', 'test-math-notes.pdf',
 '手写扫描版高数期末复习笔记，涵盖函数极限、导数与微分、中值定理等核心知识点。PDF格式可直接下载打印。',
 'NeuShare测试', 2, 1, 0, 0, 0, NOW()),

-- 资源88: 高数复习 TXT（真实文件）
('高等数学(上)复习要点整理', 1, 'document', 'test-math-review.txt',
 '纯文本版高数复习笔记，包含五章核心知识点的详细整理和备考建议。适合手机随时查看。',
 'NeuShare测试', 3, 1, 0, 0, 0, NOW()),

-- 资源89: 数据结构笔记 TXT（真实文件）
('数据结构与算法复习提纲', 5, 'document', 'test-dsa-notes.txt',
 '数据结构全章节复习提纲：线性表、栈队列、树、图、查找、排序。含时间复杂度对比表。',
 'NeuShare测试', 4, 1, 0, 0, 0, NOW()),

-- 资源90: Java源码（真实文件）
('C语言课程设计-学生管理系统源码', 3, 'other', 'test-student-manager.java',
 '控制台版本学生成绩管理系统源码，含增删改查功能。注释详细，适合初学者学习和二次开发。',
 'NeuShare测试', 2, 1, 0, 0, 0, NOW()),

-- 资源91: Python脚本（真实文件）
('Python数据分析入门示例代码', 11, 'other', 'test-data-analysis.py',
 'Pandas + Matplotlib 数据分析完整示例代码。包含成绩单数据处理和柱状图绘制。',
 'NeuShare测试', 4, 1, 0, 0, 0, NOW()),

-- 资源92: SQL练习（真实文件）
('MySQL练习题精选50道', 9, 'document', 'test-sql-exercise.sql',
 '从基础SELECT到复杂子查询、JOIN、窗口函数的SQL练习题，附参考答案。',
 'NeuShare测试', 5, 1, 0, 0, 0, NOW());


-- ==================== 社区帖子（带附件信息）====================

INSERT INTO `post` (`user_id`, `title`, `content`, `tags`, `image_urls`, `files`, `is_recommended`, `view_count`, `like_count`, `favorite_count`, `comment_count`, `status`, `create_time`) VALUES

-- 帖子6: 分享学习资料（带文件附件）
(2, '分享我的高数复习资料包', '大家期末复习加油！我把这学期整理的高数笔记打包上传了，包含PDF和TXT两种格式，PDF适合打印，TXT适合手机看。有问题评论区问我！',
 '["分享","期末","高数"]', NULL,
 '[{"name":"高等数学期末复习笔记(手写版).pdf","url":"/files/test-math-notes.pdf","size":451},{"name":"高数复习要点整理.txt","url":"/files/test-math-review.txt","size":977}]',
 0, 0, 0, 0, 0, 1, NOW()),

-- 帖子7: 数据结构经验帖（带文件）
(3, '数据结构考前救命指南', '数据结构是软工专业的硬课！我整理了一份超详细的复习提纲，覆盖全部考点。排序算法的时间复杂度对比表一定要背下来！',
 '["数据结构","考试","笔记"]', NULL,
 '[{"name":"数据结构与算法复习提纲.txt","url":"/files/test-dsa-notes.txt","size":1474}]',
 0, 0, 0, 0, 0, 1, NOW()),

-- 帖子8: 编程资源分享帖（带多个文件）
(4, '编程入门资料大放送', '学弟学妹们看过来！整理了一些入门级的编程资料：Java学生管理系统源码、Python数据分析示例、SQL练习题。都是可以直接跑的代码！',
 '["编程","分享","入门"]', NULL,
 '[{"name":"学生管理系统源码.java","url":"/files/test-student-manager.java","size":1758},{"name":"Python数据分析示例.py","url":"/files/test-data-analysis.py","size":738},{"name":"SQL练习题.sql","url":"/files/test-sql-exercise.sql","size":1341}]',
 1, 0, 0, 0, 0, 1, NOW()),

-- 帖子9: 纯文字讨论帖（无文件，测评论互动）
(5, '大家觉得这学期哪门课最难？', '我个人感觉数据结构和操作系统最难了...数据结构的红黑树真的看了好几遍才懂。你们呢？欢迎评论区讨论！',
 '["讨论","课程"]', NULL, NULL,
 0, 0, 0, 0, 0, 1, NOW()),

-- 帖子10: 求助帖（测关注互动）
(2, '求推荐好的Java学习路线', '大二了想系统学一下Java后端开发，Spring Boot + Vue这种技术栈。有没有学长学姐能分享一下学习路线或者推荐一些资源？先谢过了！',
 '["求助","Java","学习"]', NULL, NULL,
 0, 0, 0, 0, 0, 1, NOW());


-- ==================== 预置点赞数据（让页面有初始交互状态）====================
-- 用户2给资源87-92点赞
INSERT INTO `resource_like` (`user_id`, `resource_id`, `create_time`) VALUES
(2, 87, NOW()),
(2, 88, NOW()),
(2, 89, NOW());
-- 用户3给部分资源点赞
INSERT INTO `resource_like` (`user_id`, `resource_id`, `create_time`) VALUES
(3, 88, NOW()),
(3, 89, NOW()),
(3, 91, NOW());
-- 用户4点赞
INSERT INTO `resource_like` (`user_id`, `resource_id`, `create_time`) VALUES
(4, 87, NOW()),
(4, 90, NOW()),
(4, 92, NOW());


-- ==================== 预置收藏数据 ====================
INSERT INTO `favorite` (`user_id`, `resource_id`, `create_time`) VALUES
(2, 87, NOW()),
(2, 89, NOW()),
(3, 88, NOW()),
(3, 90, NOW()),
(4, 91, NOW()),
(4, 92, NOW());


-- ==================== 预置评论数据（含嵌套回复）====================
INSERT INTO `comment` (`resource_id`, `user_id`, `content`, `parent_id`, `create_time`) VALUES
-- 资源87 高数笔记评论
(87, 3, '感谢分享！这个笔记太及时了，下周就考高数。', 0, NOW()),
(87, 4, '请问有下册的吗？', 0, NOW()),
(87, 2, '下册还在整理中，整理好了第一时间发出来。', 2, NOW()),
-- 资源89 数据结构评论
(89, 2, '红黑树那块讲得特别清楚，终于搞懂左旋右旋了！', 0, NOW()),
(89, 5, '排序复杂度表建议截图保存，面试经常问。', 0, NOW()),
(89, 3, '已收藏，谢谢学长分享！', 0, NOW()),
-- 资源90 Java源码评论
(90, 5, '这个代码结构很清晰，适合课程设计参考。', 0, NOW()),
(90, 3, '能加一个文件持久化功能吗？每次重启数据就没了。', 0, NOW()),
(90, 4, '好建议，我后续加上去。可以用ObjectOutputStream序列化。', 7, NOW());


-- ==================== 帖子点赞/收藏数据 ====================
INSERT INTO `post_like` (`user_id`, `post_id`, `create_time`) VALUES
(3, 6, NOW()),
(4, 6, NOW()),
(5, 6, NOW()),
(2, 7, NOW()),
(4, 7, NOW()),
(2, 8, NOW()),
(3, 8, NOW()),
(5, 8, NOW()),
(4, 9, NOW());

INSERT INTO `post_favorite` (`user_id`, `post_id`, `create_time`) VALUES
(3, 6, NOW()),
(2, 7, NOW()),
(4, 8, NOW()),
(5, 9, NOW());


-- ==================== 帖子评论数据 ====================
INSERT INTO `post_comment` (`post_id`, `user_id`, `content`, `parent_id`, `create_time`) VALUES
-- 帖子6 评论
(6, 3, '太棒了！正好在找高数资料，下载看看。', 0, NOW()),
(6, 4, '学长yyds！', 0, NOW()),
(6, 5, 'PDF能直接打印吗？', 0, NOW()),
(6, 2, '可以的，A4纸打印效果不错。', 10, NOW()),
-- 帖子7 评论
(7, 2, '排序那张表我背下来了哈哈', 0, NOW()),
(7, 5, '红黑树有什么好的理解方法吗？', 0, NOW()),
(7, 3, '推荐看Hello Algo的动画演示，一看就懂。', 11, NOW()),
-- 帖子8 评论
(8, 5, '感谢分享！正好想学Python。', 0, NOW()),
(8, 3, '学生管理系统那个代码可以用来做课设吗？', 0, NOW()),
(8, 4, '可以的，但建议自己改一改功能和UI，避免查重。', 13, NOW()),
-- 帖子9 评论（纯讨论帖）
(9, 2, '操作系统！PV操作真的让人头秃...', 0, NOW()),
(9, 3, '同意！计网也难，协议太多了记不住。', 0, NOW()),
(9, 4, '我觉得还行吧，多刷题就好了。', 0, NOW()),
(9, 5, '你们都太强了，我觉得每门都难QAQ', 14, NOW()),
-- 帖子10 评论（求助帖）
(10, 3, '推荐先看韩顺平的Java基础视频，然后看黑马Spring Boot。', 0, NOW()),
(10, 4, '可以跟着做一个小项目练手，比如这个学生管理系统。', 0, NOW()),
(10, 5, 'B站搜"Java学习路线"，有很多up主整理过。', 0, NOW());


-- ==================== 关注数据（用于测试关注功能）====================
-- 关注关系：用户之间互相关注
INSERT INTO `follow` (`follower_id`, `followed_id`, `create_time`) VALUES
-- 张三(2) 关注别人
(2, 3, NOW()),
(2, 4, NOW()),
(2, 6, NOW()),
-- 李四(3) 关注别人
(3, 2, NOW()),
(3, 4, NOW()),
(3, 5, NOW()),
-- 王五(4) 关注别人
(4, 2, NOW()),
(4, 3, NOW()),
(4, 6, NOW()),
(4, 7, NOW()),
-- 赵六(5) 关注别人
(5, 2, NOW()),
(5, 4, NOW());


-- ==================== 更新统计计数器 ====================
-- 更新资源的 like_count / favorite_count
UPDATE `resource` r SET r.like_count = (
    SELECT COUNT(*) FROM `resource_like` rl WHERE rl.resource_id = r.id
);
UPDATE `resource` r SET r.favorite_count = (
    SELECT COUNT(*) FROM `favorite` f WHERE f.resource_id = r.id
);

-- 更新帖子的 like_count / favorite_count / comment_count
UPDATE `post` p SET p.like_count = (
    SELECT COUNT(*) FROM `post_like` pl WHERE pl.post_id = p.id
);
UPDATE `post` p SET p.favorite_count = (
    SELECT COUNT(*) FROM `post_favorite` pf WHERE pf.post_id = p.id
);
UPDATE `post` p SET p.comment_count = (
    SELECT COUNT(*) FROM `post_comment` pc WHERE pc.post_id = p.id AND pc.deleted = 0
);

-- 更新用户的 follower_count / following_count
UPDATE `user` u SET u.follower_count = (
    SELECT COUNT(*) FROM `follow` f WHERE f.followed_id = u.id
);
UPDATE `user` u SET u.following_count = (
    SELECT COUNT(*) FROM `follow` f WHERE f.follower_id = u.id
);
UPDATE `user` u SET u.total_likes_received = COALESCE((
    SELECT SUM(r.like_count) FROM `resource` r WHERE r.upload_user_id = u.id AND r.status = 1
), 0);


-- ============================================================
-- 执行完成！以下是测试账号和说明：
--
-- 测试账号（密码均为 123456）：
--   admin / 123456     - 管理员
--   20240001 / 123456  - 张三（学生）
--   20240002 / 123456  - 李四（学生）
--   20240003 / 123456  - 王五（学生）
--   20230001 / 123456  - 赵六（学生）
--   T20240001 / 123456 - 王老师（教师）
--
-- 新增资源（ID 87-92）：带真实可下载文件
--   访问地址：http://localhost:8080/files/test-math-notes.pdf 等
--
-- 新增帖子（ID 6-10）：社区帖子，部分带文件附件
--   可测试：点赞、取消点赞、收藏、取消收藏、评论/回复
--
-- 预置关注关系：用户间已有互相关注，可测试关注/取关
--
-- 预置互动数据：
--   点赞记录：用户2/3/4 对不同资源和帖子有点赞
--   收藏记录：用户2/3/4 有不同收藏
--   评论数据：各资源和帖子下有嵌套回复
-- ============================================================
