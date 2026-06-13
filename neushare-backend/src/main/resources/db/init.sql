-- ============================================================
-- NeuShare 数据库初始化脚本（含演示数据）
-- 东北大学学习资料共享平台
-- 所有测试账号密码均为: 123456 (BCrypt加密)
-- ============================================================

CREATE DATABASE IF NOT EXISTS neushare DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE neushare;

-- ==================== 建表 ====================

CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名/学号',
    `password` VARCHAR(255) NOT NULL COMMENT '密码(BCrypt)',
    `role` VARCHAR(20) DEFAULT 'student' COMMENT 'admin/student/teacher',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `avatar_url` VARCHAR(255) COMMENT '头像URL',
    `college` VARCHAR(50) COMMENT '学院',
    `grade` INT COMMENT '年级(1-4)',
    `status` INT DEFAULT 1 COMMENT '0-禁用 1-正常',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE IF NOT EXISTS `resource` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '资源ID',
    `title` VARCHAR(200) NOT NULL COMMENT '标题',
    `category_id` BIGINT COMMENT '分类ID',
    `type` VARCHAR(20) NOT NULL COMMENT 'document/video/image/other',
    `content_url` VARCHAR(500) COMMENT '资源URL',
    `description` TEXT COMMENT '描述',
    `cover_url` VARCHAR(255) COMMENT '封面URL',
    `source` VARCHAR(100) COMMENT '来源网站',
    `upload_user_id` BIGINT NOT NULL COMMENT '上传者ID',
    `status` INT DEFAULT 0 COMMENT '0-待审核 1-已发布 2-已拒绝',
    `reject_reason` VARCHAR(500) COMMENT '审核驳回原因',
    `view_count` INT DEFAULT 0 COMMENT '浏览数',
    `like_count` INT DEFAULT 0 COMMENT '点赞数',
    `favorite_count` INT DEFAULT 0 COMMENT '收藏数',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_upload_user_id` (`upload_user_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源表';

CREATE TABLE IF NOT EXISTS `comment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '评论ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `content` TEXT NOT NULL COMMENT '内容',
    `parent_id` BIGINT DEFAULT 0 COMMENT '父评论ID(0=一级)',
    `deleted` TINYINT DEFAULT 0 COMMENT '0-正常 1-已删除',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_resource_id` (`resource_id`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论表';

CREATE TABLE IF NOT EXISTS `favorite` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `user_id` BIGINT NOT NULL,
    `resource_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_resource` (`user_id`, `resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏表';

CREATE TABLE IF NOT EXISTS `banner` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(100) COMMENT '标题',
    `image_url` VARCHAR(255) NOT NULL,
    `link_url` VARCHAR(255) COMMENT '跳转链接',
    `sort` INT DEFAULT 0,
    `status` INT DEFAULT 1 COMMENT '0-禁用 1-启用',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='轮播图表';

CREATE TABLE IF NOT EXISTS `category` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `parent_id` BIGINT DEFAULT 0 COMMENT '父分类ID(0=一级分类)',
    `sort` INT DEFAULT 0,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类表';

CREATE TABLE IF NOT EXISTS `form_card` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '卡片ID',
    `title` VARCHAR(200) NOT NULL COMMENT '卡片展示标题',
    `resource_type` VARCHAR(20) DEFAULT 'book' COMMENT '资源类型 video/book/software/tutorial',
    `resource_id` BIGINT DEFAULT NULL COMMENT '关联资源ID',
    `content_url` VARCHAR(500) DEFAULT NULL COMMENT '资源内容URL',
    `sort_order` INT DEFAULT 0 COMMENT '排序(越小越靠前)',
    `status` INT DEFAULT 1 COMMENT '0-禁用 1-启用',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='服务卡片推荐表';

CREATE TABLE IF NOT EXISTS `resource_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '点赞记录ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_resource` (`user_id`, `resource_id`),
    KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='点赞记录表';

CREATE TABLE IF NOT EXISTS `notification` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '通知ID',
    `user_id` BIGINT NOT NULL COMMENT '接收用户ID',
    `type` VARCHAR(20) NOT NULL COMMENT 'audit/comment/follow/like/favorite',
    `resource_id` BIGINT COMMENT '关联资源ID',
    `from_user_id` BIGINT COMMENT '触发用户ID',
    `title` VARCHAR(200) COMMENT '通知标题',
    `content` VARCHAR(500) COMMENT '通知内容',
    `is_read` INT DEFAULT 0 COMMENT '0-未读 1-已读',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_is_read` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知表';

CREATE TABLE IF NOT EXISTS `follow` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关注ID',
    `follower_id` BIGINT NOT NULL COMMENT '关注者ID',
    `followed_id` BIGINT NOT NULL COMMENT '被关注者ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_follow` (`follower_id`, `followed_id`),
    KEY `idx_follower_id` (`follower_id`),
    KEY `idx_followed_id` (`followed_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='关注表';

-- ==================== 用户数据（密码均为 123456） ====================
INSERT INTO `user` (`id`, `username`, `password`, `role`, `nickname`, `college`, `grade`, `status`) VALUES
(1,  'admin',     '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'admin',   '管理员小明',   '软件学院',  NULL, 1),
(2,  '20240001',  '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'student', '张三',         '软件学院',  2,     1),
(3,  '20240002',  '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'student', '李四',         '计算机学院', 3,     1),
(4,  '20240003',  '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'student', '王五',         '软件学院',  1,     1),
(5,  '20230001',  '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'student', '赵六',         '信息学院',  3,     1),
(6,  'T20240001', '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'teacher', '王老师',       '软件学院',  NULL, 1),
(7,  'T20240002', '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'teacher', '李老师',       '计算机学院', NULL, 1),
(8,  '20240004',  '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS', 'student', '孙七',         '软件学院',  2,     0);

-- ==================== 分类数据 ====================
INSERT INTO `category` (`id`, `name`, `sort`) VALUES
(1,  '高等数学',               1),
(2,  '线性代数',               2),
(3,  '程序设计基础(C语言)',    3),
(4,  '面向对象程序设计(JAVA)', 4),
(5,  '数据结构与算法',         5),
(6,  '计算机组成原理',         6),
(7,  '操作系统',               7),
(8,  '计算机网络',             8),
(9,  '数据库原理',             9),
(10, '软件工程',               10),
(11, 'Python程序设计',         11),
(12, 'Web开发技术',            12);

-- ==================== 资源数据 ====================
INSERT INTO `resource` (`id`, `title`, `category_id`, `type`, `content_url`, `description`, `source`, `upload_user_id`, `status`, `view_count`, `like_count`, `favorite_count`, `create_time`) VALUES
-- 已发布资源（原有 11 条 + 新增 35 条）
(1,  '高等数学(上)期末复习笔记',       1,  'document', 'https://example.com/files/math-review.pdf',         '手写扫描版，涵盖函数极限、导数与微分、中值定理等核心知识点，期末复习必备。',                                                      '东北大学教务处',  6, 1, 856,  128, 45, '2025-09-15 10:30:00'),
(2,  '数据结构与算法课件合集',         5,  'document', 'https://example.com/files/dsa-slides.zip',          '王老师课堂全套PPT，包含线性表、栈队列、树、图、查找、排序等章节，配有动画演示。',                                              '东北大学教务处',  6, 1, 1203, 256, 89, '2025-09-20 14:00:00'),
(3,  'Java实验报告模板',               4,  'document', 'https://example.com/files/java-lab-template.docx',  '标准实验报告格式模板，含封面、实验目的、代码实现、运行截图、实验总结等板块。',                                                    '东北大学教务处',  2, 1, 432,  67,  23, '2025-10-05 09:15:00'),
(4,  '操作系统-进程调度算法详解',      7,  'document', 'https://example.com/files/os-process.pdf',          '详细讲解FCFS、SJF、优先级调度、时间片轮转、多级反馈队列等经典调度算法，附课后习题答案。',                                         '东北大学教务处',  3, 1, 678,  98,  34, '2025-10-12 16:45:00'),
(5,  '计算机网络-期末重点整理',        8,  'document', 'https://example.com/files/network-review.pdf',       'TCP/IP五层模型、HTTP协议、DNS解析、路由算法等核心考点整理，含历年真题。',                                                          '东北大学教务处',  4, 1, 945,  156, 67, '2025-10-18 11:30:00'),
(6,  '数据库原理-SQL练习题50道',       9,  'document', 'https://example.com/files/sql-exercise.pdf',        '涵盖SELECT子查询、JOIN、GROUP BY、HAVING、事务等知识点，难度递增，附参考答案。',                                                   '牛客网',          5, 1, 567,  89,  28, '2025-10-25 08:20:00'),
(7,  '线性代数-矩阵运算笔记',          2,  'document', 'https://example.com/files/linear-algebra.pdf',      '矩阵基本运算、行列式、特征值与特征向量、二次型等内容的手写笔记。',                                                                   '东北大学教务处',  2, 1, 341,  45,  12, '2025-11-01 13:00:00'),
(8,  'C语言课程设计-学生管理系统源码', 3,  'other',    'https://example.com/files/student-mgmt-c.zip',       '控制台版本学生成绩管理系统，含增删改查、文件读写、排序统计功能，注释详细适合初学者。',                                              'GitHub',          3, 1, 2340, 389, 156, '2025-11-05 15:00:00'),
(9,  'Python数据分析入门教程',         11, 'video',    'https://example.com/files/python-data.mp4',         '零基础入门，从环境搭建到NumPy/Pandas/Matplotlib实战，共计12课时。',                                                                   'B站',             7, 1, 892,  134, 42, '2025-11-10 10:00:00'),
(10, '软件工程-需求分析文档范例',      10, 'document', 'https://example.com/files/se-requirements.pdf',     '完整的需求规格说明书(SRS)模板，包含用例图、类图、时序图等UML建模示例。',                                                             '东北大学教务处',  7, 1, 412,  56,  19, '2025-11-15 09:45:00'),
(11, '计算机组成原理-实验报告合集',    6,  'document', 'https://example.com/files/coa-lab.zip',             '运算器、存储器、控制器、总线等硬件实验报告，含Logisim电路图。',                                                                     '东北大学教务处',  5, 1, 523,  78,  31, '2025-11-20 16:20:00'),
-- 待审核资源
(12, 'Web开发技术-Vue3项目实战',       12, 'video',    'https://www.bilibili.com/video/BV15b4y1a7yG',       '从零搭建一个完整的前后端分离项目，Vue3 + Element-Plus + SpringBoot技术栈。',                                                        'B站',             4, 0, 128,  12,  5,  '2025-12-01 11:00:00'),
(13, '高等数学(下)多元微积分笔记',     1,  'document', 'https://example.com/files/math2-notes.pdf',         '多元函数微分学、重积分、曲线积分与曲面积分知识整理。',                                                                              '东北大学教务处',  2, 0, 56,   8,   2,  '2025-12-05 14:30:00'),
-- 已拒绝资源
(14, '不知名广告资料',                 1,  'other',    'https://example.com/files/spam.pdf',                '不符合社区规范的内容。',                                                                                                               '其他',            8, 2, 45,   5,   0,  '2025-11-25 08:00:00'),

-- ==================== 新增资源（35 条，涵盖全部12分类+多来源） ====================
-- 高等数学 (category 1)
(15, '高等数学(上)宋浩全程视频',       1,  'video',    'https://www.bilibili.com/video/BV1Eb411u7Fw',       '宋浩老师《高等数学》同济版全程教学视频，播放量2亿+，考研复习首选。',                                                                'B站',             2, 1, 3200, 567, 201, '2025-09-10 08:00:00'),
(16, '高数公式手册(LaTeX排版)',         1,  'document', 'https://github.com/neu-share/math-formulas',         '用LaTeX排版的极限、导数、积分常用公式速查手册，支持PDF下载，源码开源可自行修改。',                                                  'GitHub',          4, 1, 780,  142, 55, '2025-11-08 14:00:00'),
-- 线性代数 (category 2)
(17, '线性代数-宋浩精讲视频',          2,  'video',    'https://www.bilibili.com/video/BV1aW411Q7x1',       '宋浩老师线性代数2024更新版，播放量7761万+，覆盖行列式到二次型全部章节。',                                                           'B站',             3, 1, 2800, 489, 178, '2025-09-25 09:00:00'),
(18, '线性代数考研真题解析(2015-2025)', 2, 'document', 'https://example.com/files/linear-algebra-exam.pdf', '近10年考研数学一线代真题逐题精讲，含解题思路和易错点标注。',                                                                        '知乎',            5, 1, 623,  112, 43, '2025-12-10 10:00:00'),
-- 程序设计基础/C语言 (category 3)
(19, 'C语言从入门到精通-郝斌教程',     3,  'video',    'https://www.bilibili.com/video/BV1os411h77o',       '郝斌老师C语言180集完整教程，被无数计算机专业学生称为C语言启蒙第一课。',                                                            'B站',             4, 1, 4500, 678, 234, '2025-08-20 11:00:00'),
(20, 'C Primer Plus 第六版 习题解答',   3,  'document', 'https://github.com/neu-share/c-primer-solutions',  '《C Primer Plus》全书编程练习参考答案，含详细注释和多种解法对比。',                                                                 'GitHub',          2, 1, 534,  98,  37, '2025-10-15 16:00:00'),
-- 面向对象/Java (category 4)
(21, 'Java核心技术 卷I 笔记',          4,  'document', 'https://example.com/files/java-core-notes.pdf',     '《Java核心技术》读书笔记，涵盖集合框架、并发编程、Stream API等重点章节。',                                                         '知乎',            3, 1, 456,  78,  29, '2025-11-22 13:00:00'),
(22, 'Spring Boot 3.x 实战教程',       4,  'video',    'https://www.bilibili.com/video/BV15b4y1a7yG',       '黑马程序员Spring Boot 3最新版，RESTful API、MyBatis、Spring Security全覆盖。',                                                     'B站',             7, 1, 1890, 312, 98, '2025-12-15 10:00:00'),
-- 数据结构与算法 (category 5)
(23, 'LeetCode热题100 Java版',         5,  'video',    'https://www.bilibili.com/video/BV1wM4y1U7bK',       '代码随想录Carl讲解LeetCode最热100题，含暴力→优化的完整推导过程。',                                                                  'B站',             2, 1, 5600, 1023, 456, '2025-10-08 08:00:00'),
(24, 'Hello 算法-动画图解数据结构',    5,  'tutorial', 'https://www.hello-algo.com/',                       'GitHub 60k+ Stars开源数据结构教程，动画图解+13种语言可运行代码，邓俊辉教授推荐。',                                                'GitHub',          4, 1, 2100, 389, 145, '2025-12-20 15:00:00'),
-- 计算机组成原理 (category 6)
(25, '计算机组成原理-王道考研',        6,  'video',    'https://www.bilibili.com/video/BV1ps4y1x7Hx',       '王道考研408计算机组成原理全程班，配合王道书使用效果最佳。',                                                                         'B站',             5, 1, 1670, 267, 89, '2025-11-12 09:00:00'),
-- 操作系统 (category 7)
(26, '操作系统-哈工大李治军MOOC',      7,  'video',    'https://www.icourse163.org/course/HIT-1002531008',  '哈尔滨工业大学李治军教授操作系统课程，中国大学MOOC国家精品课，深入讲解进程线程、内存管理、文件系统。',                             '中国大学MOOC',    3, 1, 1450, 234, 78, '2025-10-20 14:00:00'),
(27, 'Linux内核源码剖析-进程管理',     7,  'document', 'https://github.com/torvalds/linux',                 '基于Linux 6.x内核源码，深入分析进程调度、内存管理、VFS等核心子系统实现。',                                                         'GitHub',          7, 1, 678,  134, 52, '2025-12-08 16:00:00'),
-- 计算机网络 (category 8)
(28, '计算机网络(湖科大教书匠)',       8,  'video',    'https://www.bilibili.com/video/BV1c4411d7jb',       '湖南科技大学高军副教授主讲，B站粉丝15万+，深入浅出讲解各层协议，配套Cisco仿真实验。',                                            'B站',             4, 1, 2340, 423, 156, '2025-09-30 10:00:00'),
(29, '图解HTTP+HTTPS协议',             8,  'tutorial', 'https://example.com/files/http-illustrated.pdf',    '图文并茂讲解HTTP/1.1到HTTP/3演进、HTTPS加密原理、TLS握手过程，Web开发者必读。',                                                  '掘金',            2, 1, 890,  178, 65, '2025-12-18 11:00:00'),
-- 数据库原理 (category 9)
(30, 'MySQL必知必会-速查手册',         9,  'document', 'https://example.com/files/mysql-crash.pdf',         '提炼《MySQL必知必会》核心SQL语法，SELECT/JOIN/子查询/存储过程/事务一页速查。',                                                   '掘金',            5, 1, 534,  98,  36, '2025-11-28 08:00:00'),
(31, 'Redis核心原理与实战',            9,  'video',    'https://www.bilibili.com/video/BV1CJ411m7Gc',       'Redis五大数据类型+持久化+集群+缓存穿透解决方案，面试必考全面覆盖。',                                                               'B站',             2, 1, 1560, 245, 89, '2025-12-22 14:00:00'),
-- 软件工程 (category 10)
(32, '设计模式(GoF)详解+代码示例',     10, 'tutorial', 'https://github.com/neu-share/design-patterns-java', '23种设计模式的Java实现，每种模式含UML类图、代码示例、应用场景分析。',                                                              'GitHub',          3, 1, 890,  189, 67, '2025-11-18 10:00:00'),
(33, '敏捷开发与Scrum实践指南',        10, 'document', 'https://example.com/files/scrum-guide.pdf',         'Scrum框架完整指南，含Sprint规划、每日站会、评审回顾等实践模板。',                                                                  '掘金',            7, 1, 345,  56,  18, '2026-01-05 09:00:00'),
-- Python (category 11)
(34, 'Python爬虫从入门到入狱',         11, 'video',    'https://www.bilibili.com/video/BV1Yh411o7Sz',       '路飞学城Python爬虫教程，requests+scrapy+selenium全覆盖，温馨提示：遵守robots协议。',                                             'B站',             2, 1, 3450, 567, 198, '2025-11-25 15:00:00'),
(35, 'PyTorch深度学习实战(李沐)',      11, 'video',    'https://www.bilibili.com/video/BV1xBgaeJEwN',       '亚马逊首席科学家李沐《动手学深度学习》PyTorch版，从线性回归到Transformer全流程。',                                              'B站',             4, 1, 2800, 489, 178, '2025-12-05 16:00:00'),
-- Web开发 (category 12)
(36, '前端三件套-HTML/CSS/JS入门',     12, 'video',    'https://www.bilibili.com/video/BV1vY4y1W7cN',       'coderwhy前端系统课，HTML5语义化+CSS3动画+JS ES6+语法+DOM操作，前端入门首选。',                                                  'B站',             4, 1, 2100, 345, 123, '2025-10-28 13:00:00'),
(37, 'Git团队协作工作流详解',          12, 'tutorial', 'https://www.atlassian.com/git/tutorials',           'Git Flow / GitHub Flow / Trunk-Based三种工作流对比，含分支策略和PR规范模板。',                                                    '官方文档',        7, 1, 678,  123, 45, '2026-01-02 10:00:00'),
-- 跨分类补充
(38, 'CS50 哈佛计算机科学导论',        3,  'video',    'https://cs50.harvard.edu/x/',                       '哈佛大学David J. Malan教授主讲，全球最受欢迎的计算机入门课，2025最新版含AI专题。',                                              '哈佛官网',        2, 1, 6700, 1200, 567, '2025-08-15 08:00:00'),
(39, '吴恩达《机器学习》专项课程',     11, 'video',    'https://www.coursera.org/specializations/machine-learning-introduction', 'Andrew Ng亲授，全球公认最好的机器学习入门课，2022全新录制含Python实战。',                                                'Coursera',        4, 1, 3200, 567, 234, '2025-09-05 09:00:00'),
(40, '算法导论 CLRS 精读笔记',         5,  'document', 'https://github.com/neu-share/clrs-notes',           '《算法导论》全书章节笔记，含伪代码转Java/Python实现、课后习题思路。',                                                             'GitHub',          3, 1, 1230, 234, 89, '2025-12-25 14:00:00'),
(41, '大模型API开发指南(DeepSeek)',    12, 'tutorial', 'https://platform.deepseek.com/api-docs/',           'DeepSeek API完整教程：获取Key、chat/completions端点、流式响应、Function Calling实战。',                                          'DeepSeek官方',    7, 1, 2340, 389, 134, '2026-01-08 15:00:00'),
(42, 'GitHub Copilot高效使用指南',     12, 'tutorial', 'https://docs.github.com/copilot',                   'GitHub Copilot全攻略：安装配置、代码补全技巧、Copilot Chat对话式编程、最佳实践。',                                              'GitHub官方',      2, 1, 1560, 245, 89,  '2026-01-10 10:00:00'),
(43, 'Ollama本地部署DeepSeek大模型',   12, 'tutorial', 'https://ollama.com/',                               'Ollama+Open WebUI搭建本地私有AI助手，支持DeepSeek/Llama/Qwen模型，数据不出本机。',                                               '官方文档',        4, 1, 1890, 312, 112, '2026-01-12 11:00:00'),
(44, '东北大学软件学院课程攻略',       10, 'tutorial', 'https://github.com/neu-share/neu-software-courses', '东大软件学院本科四年的课程笔记、实验代码、历年试卷合集，学弟学妹人手一份。',                                                    'GitHub',          2, 1, 4500, 890, 345, '2025-08-10 08:00:00'),
(45, '考研408计算机专业基础综合',      5,  'tutorial', 'https://www.bilibili.com/video/BV1Fp4y1W7tK',       '王道考研408四门课全套视频+真题解析，数据结构+组成原理+操作系统+计算机网络。',                                                   'B站',             5, 1, 3400, 678, 234, '2025-11-01 09:00:00'),
(46, 'VS Code 插件开发入门',           12, 'tutorial', 'https://code.visualstudio.com/api',                 'VS Code官方插件开发文档翻译+实战，从Hello World到发布Marketplace全流程。',                                                       '官方文档',        7, 1, 567,  89,  34, '2026-01-15 13:00:00'),
(47, '牛客网SQL实战题库精讲',          9,  'video',    'https://www.nowcoder.com/ta/sql',                   '牛客网SQL题库全80题视频讲解，从简单查询到窗口函数逐题拆解。',                                                                     '牛客网',          2, 1, 1780, 298, 89,  '2025-12-28 14:00:00'),
(48, '计算机科学速成课(Crash Course)', 3,  'video',    'https://www.bilibili.com/video/BV1EW411u7th',       'Crash Course Computer Science中英字幕40集，从布尔逻辑到AI的计算机科学简史。',                                                   'B站',             4, 1, 4500, 789, 278, '2025-08-25 10:00:00'),
(49, 'Conventional Commits规范实战',   10, 'tutorial', 'https://www.conventionalcommits.org/',              '约定式提交规范feat/fix/docs详解，配合commitlint+husky自动校验，自动生成CHANGELOG。',                                            '官方文档',        3, 1, 456,  78,  23, '2026-01-18 09:00:00');

-- ==================== 评论数据（含嵌套回复，覆盖更多资源） ====================
INSERT INTO `comment` (`id`, `resource_id`, `user_id`, `content`, `parent_id`, `create_time`) VALUES
-- 资源1 高等数学笔记
(1,  1, 2, '这份笔记太详细了！函数极限那部分讲得特别清楚，期末考试有信心了。',     0, '2025-09-16 10:00:00'),
(2,  1, 4, '请问有下册的笔记吗？求分享！',                                       0, '2025-09-16 11:30:00'),
(3,  1, 6, '下册笔记还在整理中，预计下周上传。',                                 2, '2025-09-16 14:00:00'),
(4,  1, 3, '感谢王老师！中值定理那块终于看懂了。',                               0, '2025-09-17 09:00:00'),
-- 资源2 数据结构课件
(5,  2, 3, '课件里面的动画演示太赞了，红黑树旋转一看就明白！',                   0, '2025-09-21 08:00:00'),
(6,  2, 2, '老师能分享一下实验代码吗？',                                         5, '2025-09-21 10:00:00'),
(7,  2, 6, '实验代码在课程群里已经发了。',                                       6, '2025-09-21 11:00:00'),
-- 资源8 C语言学生管理
(8,  8, 4, '学长这个代码太实用了，我改了一下做成了图书管理系统！',               0, '2025-11-06 12:00:00'),
(9,  8, 5, '注释写得很详细，适合初学者学习文件操作。',                           0, '2025-11-06 15:00:00'),
(10, 8, 3, '学弟学妹们加油，C语言是基础！',                                     0, '2025-11-07 08:00:00'),
(11, 8, 1, '已加精，欢迎同学们踊跃分享优质资源！',                               0, '2025-11-07 09:00:00'),
-- 资源5 计算机网络
(12, 5, 2, 'TCP三次握手四次挥手的图总结得很清晰。',                             0, '2025-10-19 10:00:00'),
-- 资源9 Python教程
(13, 9, 2, '想学Python好久了，这个教程对新手友好吗？',                           0, '2025-11-11 09:00:00'),
(14, 9, 7, '非常适合零基础，建议跟着视频动手敲代码，效果更好。',                 13, '2025-11-11 10:00:00'),
-- 资源6 SQL练习
(15, 6, 3, '第35题的嵌套子查询有更优的写法，可以用EXISTS替代IN。',              0, '2025-10-26 14:00:00'),
(16, 6, 7, '说得对，参考答案里给了两种写法的对比。',                             15, '2025-10-26 15:00:00'),
-- 资源10 软件工程
(17, 10,5, '这个SRS模板很适合课程设计用，UML图很标准。',                        0, '2025-11-16 10:00:00'),
-- 新增评论（覆盖热门资源）
(18, 15,2, '宋浩老师yyds！高数全靠他了。',                                      0, '2025-09-11 09:00:00'),
(19, 15,4, '配合课本一起看效果最好，边看边做笔记。',                             0, '2025-09-12 10:00:00'),
(20, 15,6, '推荐给我的学生了，比课堂讲得还清楚。',                               0, '2025-09-13 14:00:00'),
(21, 19,3, '郝斌老师的C语言是我的编程启蒙，大一全靠这个入门的。',               0, '2025-08-22 08:00:00'),
(22, 19,2, '180集一口气看完了，配合课后练习效果很好。',                          0, '2025-08-25 11:00:00'),
(23, 23,4, 'Carl哥讲得太清楚了，跟着刷了50题已经拿到实习offer了！',            0, '2025-10-10 09:00:00'),
(24, 23,2, '暴力→优化这个讲法太赞了，理解为什么这么优化比背答案重要。',        0, '2025-10-12 15:00:00'),
(25, 23,5, '已刷完100题，面试碰到3道原题。',                                    0, '2025-10-15 10:00:00'),
(26, 24,4, '动画图解太直观了，红黑树旋转终于看懂了！',                           0, '2025-12-22 11:00:00'),
(27, 28,3, '湖科大教书匠讲得比我们老师好多了，考前看了三遍。',                   0, '2025-10-02 08:00:00'),
(28, 28,2, '配套的Cisco实验很实用，动手抓包印象更深。',                          0, '2025-10-03 14:00:00'),
(29, 38,2, '哈佛的课就是不一样，Malan教授太有感染力了。',                        0, '2025-08-18 09:00:00'),
(30, 38,4, 'CS50是计算机入门的天花板，大一必看。',                               0, '2025-08-20 10:00:00'),
(31, 38,7, '我校也在用CS50的部分内容做教学参考。',                               0, '2025-08-22 15:00:00'),
(32, 44,3, '学长太强了！这份攻略从大一用到大四，选课复习都不愁。',              0, '2025-08-12 08:00:00'),
(33, 44,2, '希望能持续更新，学弟学妹的福音。',                                  0, '2025-08-15 10:00:00'),
(34, 44,5, '毕业了回头看，这份资料真的良心。',                                  0, '2025-08-18 14:00:00'),
(35, 41,4, 'DeepSeek的API比GPT便宜太多了，学生党友好。',                         0, '2026-01-09 10:00:00'),
(36, 41,2, 'Function Calling部分写得很好，照着做了一遍就通了。',                 0, '2026-01-10 15:00:00'),
(37, 9, 4, '12个课时跟着敲完了，现在能用Pandas处理数据了。',                     0, '2025-11-15 09:00:00'),
(38, 35,3, '李沐大神的课，讲Transformer那几节特别透彻。',                        0, '2025-12-08 10:00:00'),
(39, 35,2, 'PyTorch比TensorFlow好用太多了，推荐！',                               0, '2025-12-10 14:00:00'),
(40, 34,4, '爬虫课太有意思了，但确实要注意法律边界哈哈。',                       0, '2025-11-28 08:00:00'),
(41, 26,3, '哈工大操作系统国家精品课，配合实验一起做收获很大。',                 0, '2025-10-22 10:00:00'),
(42, 26,5, '进程调度那块讲得特别清楚，终于搞懂了PV操作。',                        0, '2025-10-25 14:00:00'),
(43, 48,2, '40集看完等于上了一门计算机导论，太值了。',                            0, '2025-08-28 09:00:00'),
(44, 48,4, '中英字幕对英语学习也有帮助，一举两得。',                             0, '2025-08-30 11:00:00'),
(45, 45,5, '王道408全套，考研党必备，看了两遍上岸了。',                           0, '2025-11-05 08:00:00');

-- ==================== 收藏数据 ====================
INSERT INTO `favorite` (`id`, `user_id`, `resource_id`, `create_time`) VALUES
-- 原有
(1,  2, 2,  '2025-09-22 10:00:00'),
(2,  2, 5,  '2025-10-20 09:00:00'),
(3,  2, 8,  '2025-11-08 11:00:00'),
(4,  3, 1,  '2025-09-17 08:00:00'),
(5,  3, 2,  '2025-09-23 14:00:00'),
(6,  3, 6,  '2025-10-27 10:00:00'),
(7,  3, 9,  '2025-11-12 15:00:00'),
(8,  4, 8,  '2025-11-06 16:00:00'),
(9,  4, 2,  '2025-09-24 09:00:00'),
(10, 5, 5,  '2025-10-19 11:00:00'),
(11, 5, 7,  '2025-11-02 10:00:00'),
(12, 5, 10, '2025-11-17 13:00:00'),
-- 新增收藏
(13, 2, 15, '2025-09-12 09:00:00'),
(14, 2, 23, '2025-10-10 11:00:00'),
(15, 2, 38, '2025-08-17 08:00:00'),
(16, 2, 44, '2025-08-12 14:00:00'),
(17, 3, 19, '2025-08-22 10:00:00'),
(18, 3, 28, '2025-10-01 09:00:00'),
(19, 3, 35, '2025-12-06 11:00:00'),
(20, 3, 48, '2025-08-26 15:00:00'),
(21, 4, 15, '2025-09-14 10:00:00'),
(22, 4, 19, '2025-08-23 08:00:00'),
(23, 4, 34, '2025-11-26 14:00:00'),
(24, 4, 45, '2025-11-03 09:00:00'),
(25, 5, 23, '2025-10-11 15:00:00'),
(26, 5, 26, '2025-10-21 10:00:00'),
(27, 5, 41, '2026-01-09 11:00:00'),
(28, 2, 41, '2026-01-10 08:00:00'),
(29, 3, 44, '2025-08-14 10:00:00'),
(30, 4, 38, '2025-08-19 09:00:00');

-- ==================== 点赞数据 ====================
INSERT INTO `resource_like` (`id`, `user_id`, `resource_id`, `create_time`) VALUES
(1,  2, 1,  '2025-09-16 10:00:00'),
(2,  3, 1,  '2025-09-17 08:00:00'),
(3,  4, 1,  '2025-09-18 09:00:00'),
(4,  2, 2,  '2025-09-21 10:00:00'),
(5,  3, 2,  '2025-09-22 08:00:00'),
(6,  4, 2,  '2025-09-23 09:00:00'),
(7,  5, 2,  '2025-09-24 10:00:00'),
(8,  2, 8,  '2025-11-06 12:00:00'),
(9,  3, 8,  '2025-11-07 08:00:00'),
(10, 4, 8,  '2025-11-06 16:00:00'),
(11, 2, 15, '2025-09-11 09:00:00'),
(12, 3, 15, '2025-09-12 10:00:00'),
(13, 4, 15, '2025-09-13 08:00:00'),
(14, 5, 15, '2025-09-14 11:00:00'),
(15, 2, 19, '2025-08-21 10:00:00'),
(16, 3, 19, '2025-08-22 08:00:00'),
(17, 4, 19, '2025-08-23 09:00:00'),
(18, 2, 23, '2025-10-09 10:00:00'),
(19, 3, 23, '2025-10-10 11:00:00'),
(20, 4, 23, '2025-10-11 08:00:00'),
(21, 5, 23, '2025-10-12 14:00:00'),
(22, 2, 38, '2025-08-16 09:00:00'),
(23, 3, 38, '2025-08-18 10:00:00'),
(24, 4, 38, '2025-08-19 08:00:00'),
(25, 5, 38, '2025-08-20 15:00:00'),
(26, 2, 44, '2025-08-11 09:00:00'),
(27, 3, 44, '2025-08-13 10:00:00'),
(28, 4, 44, '2025-08-14 08:00:00'),
(29, 5, 44, '2025-08-16 14:00:00'),
(30, 2, 28, '2025-10-01 10:00:00'),
(31, 3, 28, '2025-10-02 08:00:00'),
(32, 4, 28, '2025-10-03 09:00:00'),
(33, 2, 35, '2025-12-06 10:00:00'),
(34, 3, 35, '2025-12-07 08:00:00'),
(35, 4, 35, '2025-12-08 11:00:00'),
(36, 2, 34, '2025-11-26 14:00:00'),
(37, 3, 34, '2025-11-27 08:00:00'),
(38, 2, 48, '2025-08-27 09:00:00'),
(39, 4, 48, '2025-08-29 10:00:00'),
(40, 2, 45, '2025-11-02 09:00:00'),
(41, 3, 45, '2025-11-03 08:00:00'),
(42, 5, 45, '2025-11-04 14:00:00'),
(43, 2, 41, '2026-01-09 10:00:00'),
(44, 3, 41, '2026-01-10 08:00:00'),
(45, 4, 41, '2026-01-11 15:00:00'),
(46, 2, 26, '2025-10-21 09:00:00'),
(47, 3, 26, '2025-10-22 08:00:00'),
(48, 2, 9,  '2025-11-11 10:00:00'),
(49, 3, 9,  '2025-11-12 08:00:00'),
(50, 4, 9,  '2025-11-13 09:00:00');

-- ==================== 轮播图数据 ====================
INSERT INTO `banner` (`id`, `title`, `image_url`, `link_url`, `sort`, `status`) VALUES
(1, '欢迎使用NeuShare学习资料共享平台',   'https://picsum.photos/1200/400?random=1', '/resource',     1, 1),
(2, '期末复习资料专区-助你轻松备考',      'https://picsum.photos/1200/400?random=2', '/resource',     2, 1),
(3, '上传优质资源-赢取社区积分',           'https://picsum.photos/1200/400?random=3', '/upload',       3, 1);

-- ==================== 服务卡片数据 ====================
INSERT INTO `form_card` (`id`, `title`, `resource_type`, `resource_id`, `content_url`, `sort_order`, `status`) VALUES
(1, '数据结构与算法课件合集', 'book',    2,  'https://example.com/files/dsa-slides.zip',         1, 1),
(2, 'Python数据分析入门教程', 'video',   9,  'https://example.com/files/python-data.mp4',         2, 1),
(3, 'C语言-学生管理系统源码', 'software', 8, 'https://example.com/files/student-mgmt-c.zip',      3, 0);
