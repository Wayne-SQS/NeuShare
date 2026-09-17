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
    `resource_count` BIGINT DEFAULT 0 COMMENT '上传资源数',
    `follower_count` BIGINT DEFAULT 0 COMMENT '粉丝数',
    `following_count` BIGINT DEFAULT 0 COMMENT '关注数',
    `total_likes_received` BIGINT DEFAULT 0 COMMENT '总获赞数',
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
    `tags` JSON DEFAULT NULL COMMENT '标签数组',
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
    `like_count` INT DEFAULT 0 COMMENT '点赞数',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_resource_id` (`resource_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_parent_id` (`parent_id`)
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

CREATE TABLE IF NOT EXISTS `post` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '发帖用户ID',
    `title` VARCHAR(200) NOT NULL COMMENT '标题',
    `content` TEXT COMMENT '正文',
    `tags` JSON COMMENT '标签数组',
    `image_urls` JSON COMMENT '图片URL数组',
    `files` JSON COMMENT '附件信息数组',
    `is_recommended` TINYINT DEFAULT 0 COMMENT '0-普通 1-推荐',
    `view_count` INT DEFAULT 0 COMMENT '浏览数',
    `like_count` INT DEFAULT 0 COMMENT '点赞数',
    `favorite_count` INT DEFAULT 0 COMMENT '收藏数',
    `comment_count` INT DEFAULT 0 COMMENT '评论数',
    `status` INT DEFAULT 1 COMMENT '0-待审核 1-已发布 2-已驳回',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_status` (`status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区帖子表';

CREATE TABLE IF NOT EXISTS `post_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `post_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_post` (`user_id`, `post_id`),
    KEY `idx_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子点赞记录表';

CREATE TABLE IF NOT EXISTS `post_favorite` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `post_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_post` (`user_id`, `post_id`),
    KEY `idx_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子收藏记录表';

CREATE TABLE IF NOT EXISTS `post_comment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '评论ID',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `content` TEXT NOT NULL COMMENT '内容',
    `parent_id` BIGINT DEFAULT 0 COMMENT '父评论ID(0=一级)',
    `deleted` TINYINT DEFAULT 0 COMMENT '0-正常 1-已删除',
    `like_count` INT DEFAULT 0 COMMENT '点赞数',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_post_id` (`post_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子评论表';

CREATE TABLE IF NOT EXISTS `comment_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `comment_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_comment` (`user_id`, `comment_id`),
    KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源评论点赞记录表';

CREATE TABLE IF NOT EXISTS `post_comment_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `comment_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_comment` (`user_id`, `comment_id`),
    KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子评论点赞记录表';

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
(1,  '高等数学(上)期末复习笔记',       1,  'document', 'test-math-notes.pdf',         '手写扫描版，涵盖函数极限、导数与微分、中值定理等核心知识点，期末复习必备。',                                                      '东北大学教务处',  6, 1, 856,  128, 45, '2025-09-15 10:30:00'),
(2,  '数据结构与算法课件合集',         5,  'document', 'test-dsa-notes.txt',          '数据结构与算法复习提纲，包含线性表、栈队列、树、图、查找、排序等章节。',                                              '东北大学教务处',  6, 1, 1203, 256, 89, '2025-09-20 14:00:00'),
(3,  'Java实验报告模板',               4,  'document', 'test-dsa-notes.txt',  '标准实验报告格式模板，含封面、实验目的、代码实现、运行截图、实验总结等板块。',                                                    '东北大学教务处',  2, 1, 432,  67,  23, '2025-10-05 09:15:00'),
(4,  '操作系统-进程调度算法详解',      7,  'document', 'test-dsa-notes.txt',          '详细讲解FCFS、SJF、优先级调度、时间片轮转、多级反馈队列等经典调度算法，附课后习题答案。',                                         '东北大学教务处',  3, 1, 678,  98,  34, '2025-10-12 16:45:00'),
(5,  '计算机网络-期末重点整理',        8,  'document', 'test-math-review.txt',       'TCP/IP五层模型、HTTP协议、DNS解析、路由算法等核心考点整理，含历年真题。',                                                          '东北大学教务处',  4, 1, 945,  156, 67, '2025-10-18 11:30:00'),
(6,  '数据库原理-SQL练习题50道',       9,  'document', 'test-sql-exercise.sql',        '涵盖SELECT子查询、JOIN、GROUP BY、HAVING、事务等知识点，难度递增，附参考答案。',                                                   '牛客网',          5, 1, 567,  89,  28, '2025-10-25 08:20:00'),
(7,  '线性代数-矩阵运算笔记',          2,  'document', 'test-math-review.txt',      '矩阵基本运算、行列式、特征值与特征向量、二次型等内容的手写笔记。',                                                                   '东北大学教务处',  2, 1, 341,  45,  12, '2025-11-01 13:00:00'),
(8,  'C语言课程设计-学生管理系统源码', 3,  'other',    'test-student-manager.java',       '控制台版本学生成绩管理系统，含增删改查、文件读写、排序统计功能，注释详细适合初学者。',                                              'GitHub',          3, 1, 2340, 389, 156, '2025-11-05 15:00:00'),
(9,  'Python数据分析入门教程',         11, 'video',    'https://example.com/files/python-data.mp4',         '零基础入门，从环境搭建到NumPy/Pandas/Matplotlib实战，共计12课时。',                                                                   'B站',             7, 1, 892,  134, 42, '2025-11-10 10:00:00'),
(10, '软件工程-需求分析文档范例',      10, 'document', 'test-math-review.txt',     '完整的需求规格说明书(SRS)模板，包含用例图、类图、时序图等UML建模示例。',                                                             '东北大学教务处',  7, 1, 412,  56,  19, '2025-11-15 09:45:00'),
(11, '计算机组成原理-实验报告合集',    6,  'document', 'test-sql-exercise.sql',             '运算器、存储器、控制器、总线等硬件实验报告，含Logisim电路图。',                                                                     '东北大学教务处',  5, 1, 523,  78,  31, '2025-11-20 16:20:00'),
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
(49, 'Conventional Commits规范实战',   10, 'tutorial', 'https://www.conventionalcommits.org/',              '约定式提交规范feat/fix/docs详解，配合commitlint+husky自动校验，自动生成CHANGELOG。',                                            '官方文档',        3, 1, 456,  78,  23, '2026-01-18 09:00:00'),

-- ==================== 网课视频资源（37条，覆盖12分类+概率论） ====================
-- 高等数学 (category 1)
(50, '《高等数学》同济版 全程教学视频',       1, 'video', 'https://www.bilibili.com/video/BV1Eb411u7Fw', '宋浩老师《高等数学》同济版全程教学视频，播放量2亿+，适合系统学习。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-01 08:00:00'),
(51, '《高等数学》教学视频 3.0版',            1, 'video', 'https://www.bilibili.com/video/BV1YY576yEX4', '宋浩老师最新版，黑板板书，逐步更新中。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-01 08:10:00'),
(52, '《高等数学》全程教学视频 2.0版（下册黑板版）', 1, 'video', 'https://www.bilibili.com/video/BV1CAxaeHEeH', '下册增加黑板版，适合复习。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-01 08:20:00'),
-- 线性代数 (category 2)
(53, '《线性代数》高清教学视频"惊叹号"系列',  2, 'video', 'https://www.bilibili.com/video/BV1aW411Q7x1', '宋浩老师线性代数经典版，播放量3600万+，考研/期末必备。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-02 08:00:00'),
(54, '《线性代数》教学视频 3.0版',            2, 'video', 'https://www.bilibili.com/video/BV1d7wAzsE8V', '宋浩老师最新版，更新中。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-02 08:10:00'),
(55, '线性代数的本质',                         2, 'video', 'https://www.bilibili.com/video/BV1ys411472E', '3Blue1Brown经典系列，几何直觉理解线性代数，配合宋浩食用效果最佳。', '3Blue1Brown', 6, 1, 0, 0, 0, '2026-06-02 08:20:00'),
-- 程序设计基础/C语言 (category 3)
(56, 'C语言程序设计-浙大翁恺',                3, 'video', 'https://www.bilibili.com/video/BV1s4411U7sN', '浙大国家精品课，播放量1000万+，零基础首选。', '浙大翁恺', 6, 1, 0, 0, 0, '2026-06-03 08:00:00'),
(57, '黑马程序员C++从0到1入门编程',           3, 'video', 'https://www.bilibili.com/video/BV1et411b73Z', '播放量3788万+，前半部分讲C语言，后半部分C++。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-03 08:10:00'),
(58, '小甲鱼零基础入门学习C语言',             3, 'video', 'https://www.bilibili.com/video/BV11s41167h6', '幽默风趣，适合初学者。', '鱼C-小甲鱼', 6, 1, 0, 0, 0, '2026-06-03 08:20:00'),
-- 面向对象/Java (category 4)
(59, '黑马程序员Java基础教程',                4, 'video', 'https://www.bilibili.com/video/BV17F411T7Ao', '最新版Java SE，播放量3000万+，零基础入门。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-04 08:00:00'),
(60, '尚硅谷Java零基础教程',                 4, 'video', 'https://www.bilibili.com/video/BV1Kb411W75J', '经典版，播放量2500万+，讲解细致。', '尚硅谷-宋红康', 6, 1, 0, 0, 0, '2026-06-04 08:10:00'),
(61, '黑马程序员SpringBoot3+Vue3全栈开发',    4, 'video', 'https://www.bilibili.com/video/BV14z4y1N7pg', '框架实战，含前后端，播放量500万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-04 08:20:00'),
-- 数据结构与算法 (category 5)
(62, '数据结构与算法基础-青岛大学王卓',       5, 'video', 'https://www.bilibili.com/video/BV1nJ411V7bd', '通俗易懂，学生评价极高，播放量1000万+。', '青岛大学王卓', 6, 1, 0, 0, 0, '2026-06-05 08:00:00'),
(63, '数据结构-浙江大学',                     5, 'video', 'https://www.bilibili.com/video/BV1JW411i731', '国家精品课，适合有基础，播放量800万+。', '浙大陈越', 6, 1, 0, 0, 0, '2026-06-05 08:10:00'),
(64, '尚硅谷Java数据结构与算法',              5, 'video', 'https://www.bilibili.com/video/BV1E4411H73v', 'Java语言实现，配套代码，播放量600万+。', '尚硅谷-韩顺平', 6, 1, 0, 0, 0, '2026-06-05 08:20:00'),
-- 计算机组成原理 (category 6)
(65, '计算机组成原理-哈工大刘宏伟',           6, 'video', 'https://www.bilibili.com/video/BV1t4411e7LH', '国家精品课，适合考研和初学者，播放量1500万+。', '哈工大刘宏伟', 6, 1, 0, 0, 0, '2026-06-06 08:00:00'),
(66, '王道考研计算机组成原理',                6, 'video', 'https://www.bilibili.com/video/BV1ps4y1d73V', '考研408专用，配合王道教材，播放量1000万+。', '王道计算机教育', 6, 1, 0, 0, 0, '2026-06-06 08:10:00'),
-- 操作系统 (category 7)
(67, '王道考研操作系统',                      7, 'video', 'https://www.bilibili.com/video/BV1YE411D7nH', '考研408首选，播放量1500万+。', '王道计算机教育', 6, 1, 0, 0, 0, '2026-06-07 08:00:00'),
(68, '南京大学操作系统：设计与实现',          7, 'video', 'https://www.bilibili.com/video/BV1N741177F5', '用OSTEP教材，深入理解，播放量500万+。', '南大蒋炎岩', 6, 1, 0, 0, 0, '2026-06-07 08:10:00'),
(69, '清华操作系统原理',                      7, 'video', 'https://www.bilibili.com/video/BV1uW411f72n', '清华本科课，偏理论，播放量400万+。', '清华向勇/陈渝', 6, 1, 0, 0, 0, '2026-06-07 08:20:00'),
-- 计算机网络 (category 8)
(70, '计算机网络微课堂',                      8, 'video', 'https://www.bilibili.com/video/BV1c4411d7jb', 'B站计网播放量第一，PPT动画+实验，播放量3000万+。', '湖科大教书匠', 6, 1, 0, 0, 0, '2026-06-08 08:00:00'),
(71, '王道考研计算机网络',                    8, 'video', 'https://www.bilibili.com/video/BV19E411D78Q', '考研408专用，播放量2000万+。', '王道计算机教育', 6, 1, 0, 0, 0, '2026-06-08 08:10:00'),
(72, '中科大计算机网络',                      8, 'video', 'https://www.bilibili.com/video/BV1JV411t7ow', '手写板书，反复强调重点，播放量500万+。', '中科大郑烇', 6, 1, 0, 0, 0, '2026-06-08 08:20:00'),
-- 数据库原理 (category 9)
(73, 'MySQL基础教程-尚硅谷',                  9, 'video', 'https://www.bilibili.com/video/BV12b411K7Zu', 'MySQL入门到进阶，播放量1500万+。', '尚硅谷', 6, 1, 0, 0, 0, '2026-06-09 08:00:00'),
(74, 'MySQL入门基础-老杜',                    9, 'video', 'https://www.bilibili.com/video/BV1Vy4y1z7EX', '零基础友好，讲解清晰，播放量800万+。', '老杜', 6, 1, 0, 0, 0, '2026-06-09 08:10:00'),
(75, 'Redis入门到精通',                       9, 'video', 'https://www.bilibili.com/video/BV1cr4y1671t', '缓存技术，进阶必备，播放量600万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-09 08:20:00'),
-- 软件工程 (category 10)
(76, '黑马程序员苍穹外卖项目',                10, 'video', 'https://www.bilibili.com/video/BV1TP411v7v6', 'SpringBoot实战项目，适合毕设，播放量1000万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-10 08:00:00'),
(77, '黑马程序员SpringBoot3+Vue3全栈',        10, 'video', 'https://www.bilibili.com/video/BV14z4y1N7pg', '前后端分离，企业级开发，播放量500万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-10 08:10:00'),
(78, '尚硅谷设计模式',                        10, 'video', 'https://www.bilibili.com/video/BV1G4411c7N4', '图解+源码，设计模式入门，播放量400万+。', '尚硅谷', 6, 1, 0, 0, 0, '2026-06-10 08:20:00'),
-- Python (category 11)
(79, 'Python教程600集从入门到精通',           11, 'video', 'https://www.bilibili.com/video/BV1ex411x7Em', '含Linux基础，系统全面，播放量800万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-11 08:00:00'),
(80, '零基础入门学习Python',                  11, 'video', 'https://www.bilibili.com/video/BV1xs411Q799', '幽默风趣，适合零基础，播放量334万+。', '鱼C-小甲鱼', 6, 1, 0, 0, 0, '2026-06-11 08:10:00'),
(81, '北京大学Python语言基础与应用',          11, 'video', 'https://www.icourse163.org/course/PKU-1461177162', '北大公开课，偏学术，适合系统学习。', '北大陈斌', 6, 1, 0, 0, 0, '2026-06-11 08:20:00'),
-- Web开发 (category 12)
(82, '黑马程序员JavaWeb教程',                 12, 'video', 'https://www.bilibili.com/video/BV1yGydYEE3H', '2024最新版，含Tomcat/Servlet，播放量800万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-12 08:00:00'),
(83, '尚硅谷Vue3教程',                        12, 'video', 'https://www.bilibili.com/video/BV1Zp4y1S7of', 'Vue3全家桶，前端主流，播放量600万+。', '尚硅谷-张天禹', 6, 1, 0, 0, 0, '2026-06-12 08:10:00'),
(84, '黑马程序员前端HTML/CSS/JS',              12, 'video', 'https://www.bilibili.com/video/BV1p84y1P7cW', '前端三件套入门，播放量500万+。', '黑马程序员', 6, 1, 0, 0, 0, '2026-06-12 08:20:00'),
-- 概率论与数理统计 (category 1)
(85, '《概率论与数理统计》教学视频全集',      1, 'video', 'https://www.bilibili.com/video/BV1ot411y7mU', '宋浩概率论，配套同济教材，播放量367万+。', '宋浩老师官方', 6, 1, 0, 0, 0, '2026-06-13 08:00:00'),
(86, '概率论与数理统计4小时速成',             1, 'video', 'https://www.bilibili.com/video/BV1194y1f7vr', '期末突击专用，播放量200万+。', '框框老师', 6, 1, 0, 0, 0, '2026-06-13 08:10:00'),

-- ==================== 开源技术资源（29条，AI/开发/学习） ====================
-- Anthropic / Claude 生态
(87, 'Anthropic Skills - Claude Agent 技能仓库',  12, 'tutorial', 'https://github.com/anthropics/skills', 'Anthropic 官方 Claude Agent 技能仓库，含文档处理/创意设计/企业沟通等技能模板，138k+ Stars', 'Anthropic', 6, 1, 0, 0, 0, '2026-06-14 08:00:00'),
(88, 'Claude Code - AI 终端编程代理',              12, 'tutorial', 'https://github.com/anthropics/claude-code', 'Claude Code 终端编程代理完整源码，支持自然语言命令、Git 工作流、插件系统，115k+ Stars', 'Anthropic', 6, 1, 0, 0, 0, '2026-06-14 08:10:00'),
(89, 'Anthropic Cookbook - Claude 代码示例集',     12, 'tutorial', 'https://github.com/anthropics/anthropic-cookbook', 'Anthropic 官方代码示例集，40+ Notebook 涵盖 RAG、工具调用、多模态分析、Prompt 工程等，44k+ Stars', 'Anthropic', 6, 1, 0, 0, 0, '2026-06-14 08:20:00'),
(90, 'Anthropic Prompt 工程交互式教程',           12, 'tutorial', 'https://github.com/anthropics/prompt-eng-interactive-tutorial', 'Anthropic 官方交互式 Prompt 工程教程，从零学习编写高质量提示词，33k+ Stars', 'Anthropic', 6, 1, 0, 0, 0, '2026-06-14 08:30:00'),
(91, 'Anthropic 官方课程资料',                    12, 'tutorial', 'https://github.com/anthropics/courses', 'Anthropic 官方免费课程，涵盖 Prompt 工程、Agent 架构、工具调用、多轮对话设计等，19k+ Stars', 'Anthropic', 6, 1, 0, 0, 0, '2026-06-14 08:40:00'),
(92, 'Superpowers - Claude Code 工程化技能框架',  12, 'tutorial', 'https://github.com/obra/superpowers', '最受欢迎的 Claude Code 技能框架，20+ 验证技能覆盖头脑风暴、计划编写、代码审查等，201k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 08:50:00'),
-- MCP (Model Context Protocol)
(93, 'MCP 官方规范 - Model Context Protocol',     12, 'tutorial', 'https://github.com/modelcontextprotocol/modelcontextprotocol', 'MCP 官方规范，定义 AI 客户端与外部工具/数据源的标准通信协议(JSON-RPC)，Linux 基金会托管，25k+ Stars', 'Linux基金会', 6, 1, 0, 0, 0, '2026-06-14 09:00:00'),
(94, 'MCP 官方服务器集合',                        12, 'tutorial', 'https://github.com/modelcontextprotocol/servers', 'MCP 官方服务器集合，含文件系统/GitHub/PostgreSQL/Brave搜索等 50+ 服务器实现，82k+ Stars', 'MCP官方', 6, 1, 0, 0, 0, '2026-06-14 09:10:00'),
(95, 'Awesome MCP Servers - MCP 服务器资源聚合',   12, 'tutorial', 'https://github.com/punkpeye/awesome-mcp-servers', '最全面的 MCP 服务器资源聚合，收录 3000+ 开源 MCP 服务器，覆盖 20+ 垂直领域，33k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 09:20:00'),
(96, 'GitHub MCP - GitHub 官方 MCP 服务器',       12, 'tutorial', 'https://github.com/github/github-mcp', 'GitHub 官方 MCP 服务器，支持 OAuth 认证，让 AI 直接操作仓库/PR/Issue/CI/CD，21k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 09:30:00'),
(97, 'Playwright MCP - AI 浏览器自动化',          12, 'tutorial', 'https://github.com/playwright/mcp', 'Playwright MCP 服务器，让 AI 驱动浏览器执行页面跳转/截图/表单填写/端到端测试，15k+ Stars', 'Microsoft', 6, 1, 0, 0, 0, '2026-06-14 09:40:00'),
(98, 'Context7 - MCP 文档检索服务器',             12, 'tutorial', 'https://github.com/upstash/context7', 'Context7 MCP 服务器，自动检索库/框架最新文档，解决 LLM 训练数据滞后问题，12k+ Stars', 'Upstash', 6, 1, 0, 0, 0, '2026-06-14 09:50:00'),
-- 技术栈学习资源
(99, 'Build Your Own X - 从零手写教程合集',       5, 'tutorial', 'https://github.com/codecrafters-io/build-your-own-x', '从零手写数据库/编译器/操作系统/Docker/神经网络等 30+ 领域教程，费曼学习法最佳实践，491k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 10:00:00'),
(100, 'Free Programming Books - 免费编程书籍',    5, 'document', 'https://github.com/EbookFoundation/free-programming-books', '全球最大免费编程书籍资源库，50+ 语言、4000+ 免费书籍、2000+ 免费课程，含中文资源，389k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 10:10:00'),
(101, 'Developer Roadmap - 开发者学习路线图',      12, 'tutorial', 'https://github.com/kamranahmedse/developer-roadmap', '60+ 职业路径(前端/后端/DevOps/AI等)交互式学习路线图，社区持续更新，345k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 10:20:00'),
(102, 'System Design Primer - 系统设计入门',       10, 'document', 'https://github.com/donnemartin/system-design-primer', '系统设计入门圣经，17种语言翻译，图解缓存/分片/负载均衡等核心概念，含Anki闪卡和面试题，300k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 10:30:00'),
(103, 'Coding Interview University - 编程面试自学指南', 5, 'document', 'https://github.com/jwasham/coding-interview-university', '覆盖 CS 核心课程 75% 内容，从数据结构到系统设计的完整学习计划，16种语言翻译，347k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 10:40:00'),
(104, 'Awesome - 精选资源汇总',                   12, 'tutorial', 'https://github.com/sindresorhus/awesome', '编程/DevOps/AI/Web 等各领域精选资源汇总入口，发现优质工具的第一站，290k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 10:50:00'),
(105, 'Public APIs - 免费 API 大全',              12, 'tutorial', 'https://github.com/public-apis/public-apis', '1400+ 免费 API 分 50 个类别，开发者集成第三方服务的首选参考，260k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 11:00:00'),
(106, 'Project Based Learning - 项目驱动学习',    5, 'tutorial', 'https://github.com/practical-tutorials/project-based-learning', '多语言实战项目教程合集，从入门到进阶的渐进式难度设计，184k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 11:10:00'),
(107, 'JavaScript Algorithms - JS 算法与数据结构', 5, 'tutorial', 'https://github.com/trekhleb/javascript-algorithms', 'JavaScript 算法与数据结构实现，排序/搜索/树/图/动态规划等，算法解释+代码并排，190k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 11:20:00'),
(108, 'Tech Interview Handbook - 技术面试手册',   10, 'document', 'https://github.com/yangshun/tech-interview-handbook', '前 Facebook 工程师编写，含 LeetCode 精选题、简历技巧、行为面试、薪资谈判，100k+ Stars', 'GitHub', 6, 1, 0, 0, 0, '2026-06-14 11:30:00'),
-- 热门开源开发工具
(109, 'Ollama - 本地大模型运行工具',              12, 'tutorial', 'https://github.com/ollama/ollama', '一条命令拉取运行 Llama/Mistral/Gemma/DeepSeek 等模型，隐私优先零数据外传，150k+ Stars', 'Ollama', 6, 1, 0, 0, 0, '2026-06-14 12:00:00'),
(110, 'AutoGPT - 自主 AI Agent 平台',            12, 'tutorial', 'https://github.com/Significant-Gravitas/AutoGPT', '自主 AI Agent 先驱，支持可视化工作流构建、持久运行、多模型集成，177k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 12:10:00'),
(111, 'Cline - VS Code AI 编程 Agent',           12, 'tutorial', 'https://github.com/cline/cline', 'VS Code 自主编程 Agent 扩展，支持文件编辑/终端命令/无头浏览器/MCP工具，每步需人工审批，61k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 12:20:00'),
(112, 'Aider - 终端 AI 结对编程工具',             12, 'tutorial', 'https://github.com/Aider-AI/aider', '终端 AI 结对编程工具，自动映射仓库结构、编辑文件、Git 提交，SWE-bench 基准表现优异，44k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 12:30:00'),
(113, 'OpenHands - 开源自主编程 Agent',           12, 'tutorial', 'https://github.com/OpenHands/OpenHands', '开源自主编程 Agent 平台，Docker 隔离执行，支持完整功能开发委托，MIT 协议，74k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 12:40:00'),
(114, 'LangChain - LLM 应用开发框架',            12, 'tutorial', 'https://github.com/langchain-ai/langchain', 'LLM 应用开发标准框架，LangGraph 扩展支持生产级有状态 Agent 工作流，100k+ Stars', 'LangChain', 6, 1, 0, 0, 0, '2026-06-14 12:50:00'),
(115, 'Stable Diffusion WebUI - AI 绘画工具',    12, 'tutorial', 'https://github.com/AUTOMATIC1111/stable-diffusion-webui', 'Stable Diffusion 本地 Web UI，支持文生图/直观控制/自定义扩展，AI 绘画入门首选，145k+ Stars', '开源社区', 6, 1, 0, 0, 0, '2026-06-14 13:00:00');

-- ==================== 资源标签数据 ====================
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 1;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 2;
UPDATE `resource` SET `tags` = '["专业学习","后端"]' WHERE `id` = 3;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 4;
UPDATE `resource` SET `tags` = '["专业学习","408考研","期末速成"]' WHERE `id` = 5;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 6;
UPDATE `resource` SET `tags` = '["考研数学"]' WHERE `id` = 7;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 8;
UPDATE `resource` SET `tags` = '["专业学习","AI/大模型"]' WHERE `id` = 9;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 10;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 11;
UPDATE `resource` SET `tags` = '["前端"]' WHERE `id` = 12;
UPDATE `resource` SET `tags` = '["考研数学"]' WHERE `id` = 13;
UPDATE `resource` SET `tags` = '[]' WHERE `id` = 14;
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 15;
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 16;
UPDATE `resource` SET `tags` = '["考研数学"]' WHERE `id` = 17;
UPDATE `resource` SET `tags` = '["考研数学"]' WHERE `id` = 18;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 19;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 20;
UPDATE `resource` SET `tags` = '["专业学习","后端"]' WHERE `id` = 21;
UPDATE `resource` SET `tags` = '["专业学习","后端"]' WHERE `id` = 22;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 23;
UPDATE `resource` SET `tags` = '["专业学习","408考研","开源"]' WHERE `id` = 24;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 25;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 26;
UPDATE `resource` SET `tags` = '["专业学习","开源"]' WHERE `id` = 27;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 28;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 29;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 30;
UPDATE `resource` SET `tags` = '["专业学习","后端"]' WHERE `id` = 31;
UPDATE `resource` SET `tags` = '["专业学习","开源"]' WHERE `id` = 32;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 33;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 34;
UPDATE `resource` SET `tags` = '["专业学习","AI/大模型"]' WHERE `id` = 35;
UPDATE `resource` SET `tags` = '["专业学习","前端"]' WHERE `id` = 36;
UPDATE `resource` SET `tags` = '["工具"]' WHERE `id` = 37;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 38;
UPDATE `resource` SET `tags` = '["专业学习","AI/大模型"]' WHERE `id` = 39;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 40;
UPDATE `resource` SET `tags` = '["AI/大模型"]' WHERE `id` = 41;
UPDATE `resource` SET `tags` = '["工具","AI/大模型"]' WHERE `id` = 42;
UPDATE `resource` SET `tags` = '["AI/大模型","工具"]' WHERE `id` = 43;
UPDATE `resource` SET `tags` = '["校内","开源"]' WHERE `id` = 44;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 45;
UPDATE `resource` SET `tags` = '["工具"]' WHERE `id` = 46;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 47;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 48;
UPDATE `resource` SET `tags` = '["工具","开源"]' WHERE `id` = 49;
-- 网课视频资源 tags
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 50;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 51;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 52;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 53;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 54;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 55;
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 56;
UPDATE `resource` SET `tags` = '["考研数学"]' WHERE `id` = 57;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 58;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 59;
UPDATE `resource` SET `tags` = '["专业学习","AI/大模型"]' WHERE `id` = 60;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 61;
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 62;
UPDATE `resource` SET `tags` = '["考研数学","期末速成"]' WHERE `id` = 63;
UPDATE `resource` SET `tags` = '["专业学习","408考研"]' WHERE `id` = 64;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 65;
UPDATE `resource` SET `tags` = '["专业学习","AI/大模型"]' WHERE `id` = 66;
UPDATE `resource` SET `tags` = '["专业学习"]' WHERE `id` = 67;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 68;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 69;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 70;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 71;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 72;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 73;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 74;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 75;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 76;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 77;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 78;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 79;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 80;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 81;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 82;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 83;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 84;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 85;
UPDATE `resource` SET `tags` = '["网课","视频教程"]' WHERE `id` = 86;
-- 开源技术资源 tags
UPDATE `resource` SET `tags` = '["AI技能","开源"]' WHERE `id` = 87;
UPDATE `resource` SET `tags` = '["AI编程工具","开源"]' WHERE `id` = 88;
UPDATE `resource` SET `tags` = '["AI教程","开源"]' WHERE `id` = 89;
UPDATE `resource` SET `tags` = '["AI教程","开源"]' WHERE `id` = 90;
UPDATE `resource` SET `tags` = '["AI教程","开源"]' WHERE `id` = 91;
UPDATE `resource` SET `tags` = '["AI技能","开源"]' WHERE `id` = 92;
UPDATE `resource` SET `tags` = '["AI协议","开源"]' WHERE `id` = 93;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 94;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 95;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 96;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 97;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 98;
UPDATE `resource` SET `tags` = '["编程实践","开源"]' WHERE `id` = 99;
UPDATE `resource` SET `tags` = '["编程书籍","开源"]' WHERE `id` = 100;
UPDATE `resource` SET `tags` = '["学习路线","开源"]' WHERE `id` = 101;
UPDATE `resource` SET `tags` = '["系统设计","开源"]' WHERE `id` = 102;
UPDATE `resource` SET `tags` = '["面试准备","开源"]' WHERE `id` = 103;
UPDATE `resource` SET `tags` = '["资源导航","开源"]' WHERE `id` = 104;
UPDATE `resource` SET `tags` = '["API资源","开源"]' WHERE `id` = 105;
UPDATE `resource` SET `tags` = '["编程实践","开源"]' WHERE `id` = 106;
UPDATE `resource` SET `tags` = '["算法","开源"]' WHERE `id` = 107;
UPDATE `resource` SET `tags` = '["面试准备","开源"]' WHERE `id` = 108;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 109;
UPDATE `resource` SET `tags` = '["AI工具","开源"]' WHERE `id` = 110;
UPDATE `resource` SET `tags` = '["AI编程工具","开源"]' WHERE `id` = 111;
UPDATE `resource` SET `tags` = '["AI编程工具","开源"]' WHERE `id` = 112;
UPDATE `resource` SET `tags` = '["AI编程工具","开源"]' WHERE `id` = 113;
UPDATE `resource` SET `tags` = '["AI框架","开源"]' WHERE `id` = 114;
UPDATE `resource` SET `tags` = '["AI绘画","开源"]' WHERE `id` = 115;

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
(1, '欢迎使用NeuShare学习资料共享平台',   'http://localhost:8080/files/校园学习.png', '/resource',     1, 1),
(2, '期末复习资料专区-助你轻松备考',      'http://localhost:8080/files/网课学习.png', '/resource',     2, 1),
(3, '上传优质资源-赢取社区积分',           'http://localhost:8080/files/计算机专业学习.png', '/upload',       3, 1),
(4, 'AI大模型前沿探索',                    'http://localhost:8080/files/AI大模型.png', '/community',       4, 1);

-- ==================== 服务卡片数据 ====================
INSERT INTO `form_card` (`id`, `title`, `resource_type`, `resource_id`, `content_url`, `sort_order`, `status`) VALUES
(1, '数据结构与算法课件合集', 'book',    2,  'https://example.com/files/dsa-slides.zip',         1, 1),
(2, 'Python数据分析入门教程', 'video',   9,  'https://example.com/files/python-data.mp4',         2, 1),
(3, 'C语言-学生管理系统源码', 'software', 8, 'https://example.com/files/student-mgmt-c.zip',      3, 0);

-- ==================== 帖子数据 ====================
INSERT INTO `post` (`id`, `user_id`, `title`, `content`, `tags`, `image_urls`, `files`, `is_recommended`, `view_count`, `like_count`, `favorite_count`, `comment_count`, `status`, `create_time`) VALUES
(1, 2, '高数期末复习经验分享', '期末高数怎么复习？我的经验是：先把课本例题全部做一遍，然后刷历年真题至少3套，最后整理错题本。推荐宋浩老师的视频，配合课本看效果最好！', '["课程","考研","笔记"]', NULL, NULL, 1, 356, 45, 12, 8, 1, '2025-12-01 10:00:00'),
(2, 3, 'LeetCode刷题路线推荐', '从简单题开始，按专题刷：数组→链表→栈→树→动态规划。推荐代码随想录的刷题路线，每天2-3题，坚持3个月基本能覆盖面试高频题。', '["AI","面试","算法"]', NULL, NULL, 0, 234, 38, 9, 5, 1, '2025-12-05 14:30:00'),
(3, 4, '宿舍网络优化小技巧', '校园网太卡？试试这些方法：1.用5GHz WiFi 2.避开高峰期下载 3.修改DNS为114.114.114.114 4.用网线直连。亲测下载速度提升3倍！', '["工具","生活"]', NULL, NULL, 0, 189, 22, 7, 3, 1, '2025-12-10 09:15:00'),
(4, 5, '考研408复习规划', '408四门课建议复习顺序：数据结构→组成原理→操作系统→计算机网络。数据结构最基础先搞定，计网知识点最多放最后。每天6小时，4个月足够。', '["考研","课程"]', NULL, NULL, 0, 412, 56, 18, 6, 1, '2025-12-12 16:00:00'),
(5, 6, '软件工程课程设计指南', '课程设计选题建议：选一个有实际需求的项目，不要为了炫技选太复杂的。推荐用Spring Boot + Vue做前后端分离，文档一定要写好，SRS和测试报告占分很大。', '["课程","笔记"]', NULL, NULL, 0, 178, 15, 5, 4, 1, '2025-12-15 11:30:00'),
(6, 3, '概率论与数理统计复习攻略', '概率论重点：随机变量分布、期望方差、大数定律、中心极限定理、参数估计、假设检验。推荐看宋浩老师的概率论视频，配合课后习题效果最好。考试前一定要把历年真题做一遍，题型重复率很高！', '["考研数学","期末速成"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2025-12-18 09:00:00'),
(7, 4, '推荐几个好用的编程学习网站', '1. LeetCode - 刷题必备，每天2题保持手感\n2. 牛客网 - 国内面试题库最全\n3. Codeforces - 竞赛选手必刷\n4. Hello Algo - 数据结构动画教程\n5. 菜鸟教程 - 快速查语法\n6. MDN Web Docs - 前端权威文档\n\n大家还有什么好用的网站？评论区补充！', '["工具","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2025-12-20 14:00:00'),
(8, 2, 'Spring Boot + Vue 全栈项目经验分享', '最近做完了一个全栈项目，分享一下技术选型和踩坑经验：\n\n后端：Spring Boot 3 + MyBatis-Plus + MySQL + JWT\n前端：Vue 3 + Element Plus + Pinia + Axios\n\n踩坑记录：\n1. CORS问题：后端加@CrossOrigin或全局配置\n2. JWT过期：前端用拦截器自动刷新token\n3. 分页查询：MyBatis-Plus的Page对象很方便\n4. 文件上传：注意配置multipart最大文件大小\n5. 部署：用nginx反向代理，前后端分离部署', '["后端","前端","分享"]', NULL, NULL, 1, 0, 0, 0, 0, 1, '2025-12-22 10:30:00'),
(9, 5, '期末考试时间管理技巧', '期末周怎么安排复习？我的方法是：\n\n1. 提前2周列复习计划，按考试时间倒序排\n2. 每门课分配2-3天，最后1天总复习\n3. 早上8-12点做数学类题目（脑子最清醒）\n4. 下午看文科类/记忆类内容\n5. 晚上做真题模拟，计时练习\n6. 考前一天只看错题本和重点笔记\n\n关键：不要熬夜！睡眠不足第二天效率极低。', '["期末速成","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2025-12-25 08:00:00'),
(10, 6, '关于课程设计的几点建议', '作为老师，给同学们几点课程设计建议：\n\n1. 选题要切合实际需求，不要为了炫技选太复杂的\n2. 文档和代码一样重要，SRS占分很大\n3. 代码要有注释，变量命名要规范\n4. 测试用例要覆盖边界情况\n5. 提前准备，不要拖到最后一周\n6. 遇到问题及时问老师/助教\n\n推荐用Spring Boot + Vue做前后端分离，技术栈成熟、资料多。', '["专业学习","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2025-12-28 11:00:00'),
(11, 7, '计算机专业学生必读的5本书', '推荐5本对计算机专业学生影响最大的书：\n\n1. 《深入理解计算机系统》(CSAPP) - 理解计算机底层原理\n2. 《算法导论》- 算法基础必读\n3. 《设计模式》- 代码架构思维\n4. 《代码大全》- 编程实践指南\n5. 《人月神话》- 软件工程经典\n\n注意：这些书不需要一次读完，按需阅读即可。CSAPP建议大二开始读，配合实验效果最好。', '["专业学习","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-02 09:30:00'),
(12, 3, '考研复试经验贴', '刚经历完考研复试，分享一些经验：\n\n1. 提前联系导师：发邮件附简历和成绩单\n2. 专业课复习：重点看本科核心课程\n3. 英语面试：准备自我介绍+常见问题\n4. 项目经历：至少准备1-2个能讲清楚的项目\n5. 机试：刷LeetCode简单+中等题\n6. 心态：不要紧张，老师更看重学习能力和态度\n\n祝学弟学妹们都能上岸！', '["408考研","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-05 14:00:00'),
(13, 4, 'Docker入门指南-从零开始容器化部署', 'Docker是后端开发必备技能，分享一个快速入门路线：\n\n1. 安装Docker Desktop\n2. 学习基本命令：run, build, push, pull\n3. 写第一个Dockerfile\n4. docker-compose编排多容器\n5. 数据卷和网络配置\n6. 实战：部署一个Spring Boot应用\n\n推荐资源：Docker官方文档 + B站"狂神说Java"Docker教程。', '["后端","工具","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-08 16:00:00'),
(14, 2, '东北大学选课攻略', '东大选课经验分享：\n\n1. 体育课：选自己感兴趣的，乒乓球和羽毛球比较热门\n2. 通识课：推荐"创新思维"和"创业基础"，给分不错\n3. 专业选修：根据考研/就业方向选择\n4. 选课时间：提前排好志愿，第一志愿最重要\n5. 退课：开学第一周可以退换，别错过\n\n注意：学分别选太多，每学期20-24学分比较合理。', '["校内","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-10 10:00:00'),
(15, 5, 'Git常用命令速查', 'Git是团队协作必备工具，整理了最常用的命令：\n\n基本操作：git add . / git commit -m "msg" / git push\n分支操作：git branch / git checkout -b feature / git merge\n撤销操作：git reset --soft HEAD~1 / git stash / git stash pop\n查看信息：git log --oneline / git diff / git status\n协作流程：1. fork仓库 → 2. 创建分支 → 3. 提交PR → 4. code review → 5. merge\n\n建议：commit message用约定式提交（feat/fix/docs等前缀）', '["工具","开源","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-12 13:30:00'),
(16, 3, '机器学习入门路线推荐', '想入门机器学习的同学看这里：\n\n1. 数学基础：线性代数+概率论+微积分\n2. 编程基础：Python + NumPy + Pandas\n3. 入门课程：吴恩达Coursera机器学习\n4. 实战框架：PyTorch（推荐）或TensorFlow\n5. 进阶：李沐《动手学深度学习》\n6. 论文阅读：从经典论文开始（ResNet, Transformer等）\n\n不要一上来就看论文，先打好基础。数学是ML的地基，跳过数学直接上手框架容易走弯路。', '["AI/大模型","专业学习","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-15 09:00:00'),
(17, 4, '实习面试经验总结', '拿到了几个大厂实习offer，分享面试经验：\n\n1. 简历：一页纸，突出项目经历和技术栈\n2. 算法：LeetCode Hot 100必刷，面试常考\n3. 八股文：Java基础+Spring+MySQL+Redis\n4. 项目：至少1个能深入讲的项目\n5. 场景题：高并发、缓存、分布式等\n6. HR面：准备自我介绍+优缺点+职业规划\n\n时间线：3月投递→4月面试→5月拿offer。建议提前3个月开始准备。', '["专业学习","分享"]', NULL, NULL, 0, 0, 0, 0, 0, 1, '2026-01-18 14:00:00'),
(18, 2, '分享我的高数复习资料包', '大家期末复习加油！我把这学期整理的高数笔记打包上传了，包含PDF和TXT两种格式，PDF适合打印，TXT适合手机看。有问题评论区问我！', '["分享","期末","高数"]', NULL, '[{"name":"高等数学期末复习笔记(手写版).pdf","url":"/files/test-math-notes.pdf","size":451},{"name":"高数复习要点整理.txt","url":"/files/test-math-review.txt","size":977}]', 0, 0, 0, 0, 0, 1, '2026-01-20 10:00:00'),
(19, 3, '数据结构考前救命指南', '数据结构是软工专业的硬课！我整理了一份超详细的复习提纲，覆盖全部考点。排序算法的时间复杂度对比表一定要背下来！', '["数据结构","考试","笔记"]', NULL, '[{"name":"数据结构与算法复习提纲.txt","url":"/files/test-dsa-notes.txt","size":1474}]', 0, 0, 0, 0, 0, 1, '2026-01-22 15:00:00'),
(20, 4, '编程入门资料大放送', '学弟学妹们看过来！整理了一些入门级的编程资料：Java学生管理系统源码、Python数据分析示例、SQL练习题。都是可以直接跑的代码！', '["编程","分享","入门"]', NULL, '[{"name":"学生管理系统源码.java","url":"/files/test-student-manager.java","size":1758},{"name":"Python数据分析示例.py","url":"/files/test-data-analysis.py","size":738},{"name":"SQL练习题.sql","url":"/files/test-sql-exercise.sql","size":1341}]', 1, 0, 0, 0, 0, 1, '2026-01-25 11:00:00');

-- ==================== 帖子评论数据 ====================
INSERT INTO `post_comment` (`id`, `post_id`, `user_id`, `content`, `parent_id`, `create_time`) VALUES
-- 帖子1 高数复习经验
(1,  1, 3, '宋浩老师确实讲得好，配合课本效果翻倍。', 0, '2025-12-02 08:00:00'),
(2,  1, 4, '请问错题本怎么整理？电子版还是手写？', 0, '2025-12-02 10:00:00'),
(3,  1, 2, '我用的Notion整理的，方便搜索和分类。', 2, '2025-12-02 14:00:00'),
(4,  1, 5, '历年真题哪里能找到？', 0, '2025-12-03 09:00:00'),
(5,  1, 6, '教务处网站有部分，也可以问学长要。', 4, '2025-12-03 11:00:00'),
(6,  1, 7, '推荐做真题时计时模拟，培养考试节奏。', 0, '2025-12-04 08:00:00'),
(7,  1, 3, '对，计时很重要，我第一次没计时差点没做完。', 6, '2025-12-04 10:00:00'),
(8,  1, 4, '谢谢学长学姐们的建议！', 0, '2025-12-05 09:00:00'),
-- 帖子2 LeetCode刷题
(9,  2, 2, '代码随想录的路线确实科学，按专题刷比随机刷效率高很多。', 0, '2025-12-06 09:00:00'),
(10, 2, 5, '动态规划有什么好的入门方法吗？感觉很难。', 0, '2025-12-06 14:00:00'),
(11, 2, 3, '推荐先从背包问题开始，理解状态转移方程是关键。', 10, '2025-12-07 08:00:00'),
(12, 2, 4, '坚持3个月真的有效，我现在面试碰到原题了。', 0, '2025-12-08 10:00:00'),
(13, 2, 2, '恭喜！坚持就是胜利。', 12, '2025-12-08 14:00:00'),
-- 帖子3 宿舍网络
(14, 3, 2, '5GHz确实快很多，但覆盖范围小，离路由近才行。', 0, '2025-12-11 08:00:00'),
(15, 3, 5, '改DNS这个技巧好用，114.114.114.114确实快。', 0, '2025-12-11 10:00:00'),
(16, 3, 4, '网线直连最稳定，打游戏延迟直接减半。', 0, '2025-12-12 09:00:00'),
-- 帖子4 考研408
(17, 4, 2, '数据结构确实应该先搞，后面几门都用到。', 0, '2025-12-13 08:00:00'),
(18, 4, 3, '计网知识点太多了，建议用思维导图整理。', 0, '2025-12-13 14:00:00'),
(19, 4, 7, '每天6小时4个月够了，但一定要坚持，中间断了很难捡回来。', 0, '2025-12-14 09:00:00'),
(20, 4, 5, '王道的课配合教材效果最好，纯看视频容易忘。', 0, '2025-12-15 10:00:00'),
(21, 4, 4, '谢谢大家建议！我按这个顺序来。', 19, '2025-12-15 14:00:00'),
(22, 4, 2, '加油！坚持就是胜利。', 21, '2025-12-16 08:00:00'),
-- 帖子5 课程设计
(23, 5, 2, 'SRS真的占分很大，我们组代码写得好但文档扣了不少分。', 0, '2025-12-16 09:00:00'),
(24, 5, 3, 'Spring Boot + Vue这个组合确实好用，资料也多。', 0, '2025-12-17 08:00:00'),
(25, 5, 4, '测试用例要覆盖边界情况，这个提醒太重要了。', 0, '2025-12-18 10:00:00'),
(26, 5, 6, '文档规范可以参考IEEE标准模板。', 0, '2025-12-19 09:00:00'),
-- 帖子6 概率论
(27, 6, 2, '概率论题型重复率确实高，真题一定要做！', 0, '2025-12-19 08:00:00'),
(28, 6, 4, '中心极限定理那块有什么好的理解方法吗？', 0, '2025-12-19 14:00:00'),
(29, 6, 3, '把中心极限定理理解为"大量独立同分布随机变量之和近似正态"就好记了。', 28, '2025-12-20 09:00:00'),
(30, 6, 5, '宋浩的概率论和高等数学一样好！', 0, '2025-12-20 14:00:00'),
-- 帖子7 编程网站
(31, 7, 2, '补充一个：freeCodeCamp，免费学前端，项目驱动。', 0, '2025-12-21 08:00:00'),
(32, 7, 3, 'MDN确实是前端圣经，查API第一选择。', 0, '2025-12-21 10:00:00'),
(33, 7, 5, 'Hello Algo的动画太赞了，红黑树终于看懂了。', 0, '2025-12-22 09:00:00'),
(34, 7, 6, '推荐给学生了，比课本讲得直观。', 0, '2025-12-22 14:00:00'),
-- 帖子8 全栈项目
(35, 8, 3, 'CORS那个坑我踩过，搞了半天才解决。', 0, '2025-12-23 08:00:00'),
(36, 8, 5, 'JWT刷新token的拦截器能分享一下代码吗？', 0, '2025-12-23 14:00:00'),
(37, 8, 2, '可以，我整理一下发到资源区。', 36, '2025-12-24 09:00:00'),
(38, 8, 4, 'nginx配置也有坑，WebSocket需要额外配置。', 0, '2025-12-24 14:00:00'),
(39, 8, 7, '部署建议用Docker，环境一致性好管理。', 0, '2025-12-25 10:00:00'),
(40, 8, 3, 'Docker确实方便，我现在的项目全用Docker部署了。', 39, '2025-12-25 14:00:00'),
-- 帖子9 时间管理
(41, 9, 2, '早上做数学题这个建议好，确实脑子最清醒。', 0, '2025-12-26 08:00:00'),
(42, 9, 3, '不熬夜+1，我之前熬夜复习第二天完全废了。', 0, '2025-12-26 10:00:00'),
(43, 9, 4, '错题本真的有用，考前只看错题效率最高。', 0, '2025-12-27 09:00:00'),
-- 帖子10 课程设计建议
(44, 10, 2, '王老师说得对，文档真的很重要！', 0, '2025-12-29 08:00:00'),
(45, 10, 3, 'SRS模板有推荐的吗？', 0, '2025-12-29 10:00:00'),
(46, 10, 6, '资源区有我上传的SRS模板，可以参考。', 45, '2025-12-30 09:00:00'),
-- 帖子11 必读书单
(47, 11, 2, 'CSAPP大二开始读确实合适，配合实验效果翻倍。', 0, '2026-01-03 08:00:00'),
(48, 11, 4, '人月神话很短但很有启发，推荐。', 0, '2026-01-03 14:00:00'),
(49, 11, 5, '设计模式建议结合实际项目读，纯看容易忘。', 0, '2026-01-04 09:00:00'),
-- 帖子12 考研复试
(50, 12, 2, '联系导师的邮件模板能分享一下吗？', 0, '2026-01-06 08:00:00'),
(51, 12, 3, '可以，我整理一下发出来。', 50, '2026-01-06 14:00:00'),
(52, 12, 4, '机试难度大概是什么水平？', 0, '2026-01-07 09:00:00'),
(53, 12, 3, 'LeetCode简单+中等就够用了，不会考hard。', 52, '2026-01-07 14:00:00'),
-- 帖子13 Docker
(54, 13, 2, 'Docker确实是后端必备，部署太方便了。', 0, '2026-01-09 08:00:00'),
(55, 13, 5, 'docker-compose编排多容器那块讲得好。', 0, '2026-01-09 14:00:00'),
-- 帖子14 选课攻略
(56, 14, 3, '乒乓球确实热门，要抢！', 0, '2026-01-11 08:00:00'),
(57, 14, 5, '创新思维给分确实不错，推荐。', 0, '2026-01-11 14:00:00'),
-- 帖子15 Git命令
(58, 15, 2, 'git stash太实用了，之前不知道这个命令。', 0, '2026-01-13 08:00:00'),
(59, 15, 4, '约定式提交确实规范，配合commitlint自动检查。', 0, '2026-01-13 14:00:00'),
(60, 15, 3, '补充一个：git rebase -i 可以合并提交，保持历史整洁。', 0, '2026-01-14 09:00:00'),
-- 帖子16 机器学习
(61, 16, 2, '吴恩达的课真的是ML入门天花板。', 0, '2026-01-16 08:00:00'),
(62, 16, 5, '数学基础确实不能跳，我之前直接上手框架走了很多弯路。', 0, '2026-01-16 14:00:00'),
(63, 16, 4, '李沐的动手学深度学习也很推荐，代码+理论结合。', 0, '2026-01-17 09:00:00'),
-- 帖子17 实习面试
(64, 17, 2, 'LeetCode Hot 100确实是面试高频题库。', 0, '2026-01-19 08:00:00'),
(65, 17, 3, '八股文建议用JavaGuide整理，很全面。', 0, '2026-01-19 14:00:00'),
(66, 17, 5, '简历一页纸这个很重要，我之前写了两页被HR说太长。', 0, '2026-01-20 09:00:00'),
-- 帖子18 高数资料包
(67, 18, 3, '太棒了！正好在找高数资料，下载看看。', 0, '2026-01-21 08:00:00'),
(68, 18, 4, '学长yyds！', 0, '2026-01-21 10:00:00'),
(69, 18, 5, 'PDF能直接打印吗？', 0, '2026-01-21 14:00:00'),
(70, 18, 2, '可以的，A4纸打印效果不错。', 69, '2026-01-22 09:00:00'),
-- 帖子19 数据结构救命
(71, 19, 2, '排序那张表我背下来了哈哈', 0, '2026-01-23 08:00:00'),
(72, 19, 5, '红黑树有什么好的理解方法吗？', 0, '2026-01-23 14:00:00'),
(73, 19, 3, '推荐看Hello Algo的动画演示，一看就懂。', 72, '2026-01-24 09:00:00'),
-- 帖子20 编程入门
(74, 20, 5, '感谢分享！正好想学Python。', 0, '2026-01-26 08:00:00'),
(75, 20, 3, '学生管理系统那个代码可以用来做课设吗？', 0, '2026-01-26 14:00:00'),
(76, 20, 4, '可以的，但建议自己改一改功能和UI，避免查重。', 75, '2026-01-27 09:00:00');

-- ==================== 帖子点赞数据 ====================
INSERT INTO `post_like` (`user_id`, `post_id`, `create_time`) VALUES
(3, 1, '2025-12-02 08:00:00'), (4, 1, '2025-12-03 09:00:00'), (5, 1, '2025-12-04 10:00:00'),
(2, 2, '2025-12-06 08:00:00'), (4, 2, '2025-12-07 09:00:00'),
(3, 3, '2025-12-11 08:00:00'), (5, 3, '2025-12-12 09:00:00'),
(2, 4, '2025-12-13 08:00:00'), (3, 4, '2025-12-14 09:00:00'), (7, 4, '2025-12-15 10:00:00'),
(2, 5, '2025-12-16 08:00:00'), (3, 5, '2025-12-17 09:00:00'), (4, 5, '2025-12-18 10:00:00'),
(2, 6, '2025-12-19 08:00:00'), (4, 6, '2025-12-20 09:00:00'), (5, 6, '2025-12-21 10:00:00'),
(2, 7, '2025-12-21 08:00:00'), (3, 7, '2025-12-22 09:00:00'), (5, 7, '2025-12-23 10:00:00'),
(3, 8, '2025-12-23 08:00:00'), (4, 8, '2025-12-24 09:00:00'), (5, 8, '2025-12-25 10:00:00'), (7, 8, '2025-12-26 09:00:00'),
(2, 9, '2025-12-26 08:00:00'), (3, 9, '2025-12-27 09:00:00'),
(2, 10, '2025-12-29 08:00:00'), (3, 10, '2025-12-30 09:00:00'),
(2, 11, '2026-01-03 08:00:00'), (4, 11, '2026-01-04 09:00:00'),
(2, 12, '2026-01-06 08:00:00'), (4, 12, '2026-01-07 09:00:00'),
(2, 13, '2026-01-09 08:00:00'), (5, 13, '2026-01-10 09:00:00'),
(3, 14, '2026-01-11 08:00:00'), (5, 14, '2026-01-12 09:00:00'),
(2, 15, '2026-01-13 08:00:00'), (4, 15, '2026-01-14 09:00:00'),
(2, 16, '2026-01-16 08:00:00'), (5, 16, '2026-01-17 09:00:00'),
(2, 17, '2026-01-19 08:00:00'), (3, 17, '2026-01-20 09:00:00'),
(3, 18, '2026-01-21 08:00:00'), (4, 18, '2026-01-22 09:00:00'), (5, 18, '2026-01-23 10:00:00'),
(2, 19, '2026-01-23 08:00:00'), (4, 19, '2026-01-24 09:00:00'),
(5, 20, '2026-01-26 08:00:00'), (3, 20, '2026-01-27 09:00:00');

-- ==================== 帖子收藏数据 ====================
INSERT INTO `post_favorite` (`user_id`, `post_id`, `create_time`) VALUES
(3, 1, '2025-12-02 10:00:00'), (2, 2, '2025-12-06 10:00:00'),
(2, 4, '2025-12-13 10:00:00'), (5, 4, '2025-12-14 10:00:00'),
(3, 6, '2025-12-19 10:00:00'), (2, 7, '2025-12-21 10:00:00'),
(4, 8, '2025-12-23 10:00:00'), (2, 9, '2025-12-26 10:00:00'),
(2, 12, '2026-01-06 10:00:00'), (5, 16, '2026-01-16 10:00:00'),
(3, 18, '2026-01-21 10:00:00'), (4, 20, '2026-01-26 10:00:00');

-- ==================== 关注数据 ====================
INSERT INTO `follow` (`follower_id`, `followed_id`, `create_time`) VALUES
(2, 3, '2025-09-20 10:00:00'), (2, 4, '2025-09-25 14:00:00'), (2, 6, '2025-10-01 09:00:00'),
(3, 2, '2025-09-22 08:00:00'), (3, 4, '2025-10-05 10:00:00'), (3, 5, '2025-10-10 14:00:00'),
(4, 2, '2025-09-28 09:00:00'), (4, 3, '2025-10-02 11:00:00'), (4, 6, '2025-10-08 08:00:00'), (4, 7, '2025-10-15 10:00:00'),
(5, 2, '2025-10-01 08:00:00'), (5, 4, '2025-10-12 09:00:00');

-- ==================== 帖子统计校准 ====================
UPDATE `post` p SET p.like_count = (SELECT COUNT(*) FROM `post_like` pl WHERE pl.post_id = p.id);
UPDATE `post` p SET p.favorite_count = (SELECT COUNT(*) FROM `post_favorite` pf WHERE pf.post_id = p.id);
UPDATE `post` p SET p.comment_count = (SELECT COUNT(*) FROM `post_comment` pc WHERE pc.post_id = p.id AND pc.deleted = 0);

-- ==================== 用户统计初始数据（冗余字段校准） ====================
-- resource_count: 每个用户上传的已发布资源数(status=1)
UPDATE `user` u SET u.resource_count = (SELECT COUNT(*) FROM `resource` r WHERE r.upload_user_id = u.id AND r.status = 1);
-- follower_count: 每个用户的粉丝数
UPDATE `user` u SET u.follower_count = (SELECT COUNT(*) FROM `follow` f WHERE f.followed_id = u.id);
-- following_count: 每个用户关注的人数
UPDATE `user` u SET u.following_count = (SELECT COUNT(*) FROM `follow` f WHERE f.follower_id = u.id);
-- total_likes_received: 每个用户上传资源的总获赞数
UPDATE `user` u SET u.total_likes_received = COALESCE((SELECT SUM(r.like_count) FROM `resource` r WHERE r.upload_user_id = u.id AND r.status = 1), 0);
