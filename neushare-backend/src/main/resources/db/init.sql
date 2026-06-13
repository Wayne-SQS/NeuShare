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
INSERT INTO `resource` (`id`, `title`, `category_id`, `type`, `content_url`, `description`, `upload_user_id`, `status`, `view_count`, `like_count`, `favorite_count`, `create_time`) VALUES
-- 已发布资源
(1,  '高等数学(上)期末复习笔记',       1,  'document', 'https://example.com/files/math-review.pdf',         '手写扫描版，涵盖函数极限、导数与微分、中值定理等核心知识点，期末复习必备。',                                                      6, 1, 856, 128, 45, '2025-09-15 10:30:00'),
(2,  '数据结构与算法课件合集',         5,  'document', 'https://example.com/files/dsa-slides.zip',          '王老师课堂全套PPT，包含线性表、栈队列、树、图、查找、排序等章节，配有动画演示。',                                              6, 1, 1203, 256, 89, '2025-09-20 14:00:00'),
(3,  'Java实验报告模板',               4,  'document', 'https://example.com/files/java-lab-template.docx',  '标准实验报告格式模板，含封面、实验目的、代码实现、运行截图、实验总结等板块。',                                                    2, 1, 432, 67,  23, '2025-10-05 09:15:00'),
(4,  '操作系统-进程调度算法详解',      7,  'document', 'https://example.com/files/os-process.pdf',          '详细讲解FCFS、SJF、优先级调度、时间片轮转、多级反馈队列等经典调度算法，附课后习题答案。',                                         3, 1, 678, 98,  34, '2025-10-12 16:45:00'),
(5,  '计算机网络-期末重点整理',        8,  'document', 'https://example.com/files/network-review.pdf',       'TCP/IP五层模型、HTTP协议、DNS解析、路由算法等核心考点整理，含历年真题。',                                                          4, 1, 945, 156, 67, '2025-10-18 11:30:00'),
(6,  '数据库原理-SQL练习题50道',       9,  'document', 'https://example.com/files/sql-exercise.pdf',        '涵盖SELECT子查询、JOIN、GROUP BY、HAVING、事务等知识点，难度递增，附参考答案。',                                                   5, 1, 567, 89,  28, '2025-10-25 08:20:00'),
(7,  '线性代数-矩阵运算笔记',          2,  'document', 'https://example.com/files/linear-algebra.pdf',      '矩阵基本运算、行列式、特征值与特征向量、二次型等内容的手写笔记。',                                                                   2, 1, 341, 45,  12, '2025-11-01 13:00:00'),
(8,  'C语言课程设计-学生管理系统源码', 3,  'other',    'https://example.com/files/student-mgmt-c.zip',       '控制台版本学生成绩管理系统，含增删改查、文件读写、排序统计功能，注释详细适合初学者。',                                              3, 1, 2340, 389, 156, '2025-11-05 15:00:00'),
(9,  'Python数据分析入门教程',         11, 'video',    'https://example.com/files/python-data.mp4',         '零基础入门，从环境搭建到NumPy/Pandas/Matplotlib实战，共计12课时。',                                                                   7, 1, 892, 134, 42, '2025-11-10 10:00:00'),
(10, '软件工程-需求分析文档范例',      10, 'document', 'https://example.com/files/se-requirements.pdf',     '完整的需求规格说明书(SRS)模板，包含用例图、类图、时序图等UML建模示例。',                                                             7, 1, 412, 56,  19, '2025-11-15 09:45:00'),
(11, '计算机组成原理-实验报告合集',    6,  'document', 'https://example.com/files/coa-lab.zip',             '运算器、存储器、控制器、总线等硬件实验报告，含Logisim电路图。',                                                                     5, 1, 523, 78,  31, '2025-11-20 16:20:00'),
-- 待审核资源
(12, 'Web开发技术-Vue3项目实战',       12, 'video',    'https://example.com/files/vue3-project.mp4',        '从零搭建一个完整的前后端分离项目，Vue3 + Element-Plus + SpringBoot技术栈。',                                                        4, 0, 0,   0,   0,  '2025-12-01 11:00:00'),
(13, '高等数学(下)多元微积分笔记',     1,  'document', 'https://example.com/files/math2-notes.pdf',         '多元函数微分学、重积分、曲线积分与曲面积分知识整理。',                                                                              2, 0, 0,   0,   0,  '2025-12-05 14:30:00'),
-- 已拒绝资源
(14, '不知名广告资料',                 1,  'other',    'https://example.com/files/spam.pdf',                '不符合社区规范的内容。',                                                                                                               8, 2, 45,  5,   0,  '2025-11-25 08:00:00');

-- ==================== 评论数据（含嵌套回复） ====================
INSERT INTO `comment` (`id`, `resource_id`, `user_id`, `content`, `parent_id`, `create_time`) VALUES
-- 资源1 高等数学笔记的评论
(1,  1, 2, '这份笔记太详细了！函数极限那部分讲得特别清楚，期末考试有信心了。',     0, '2025-09-16 10:00:00'),
(2,  1, 4, '请问有下册的笔记吗？求分享！',                                       0, '2025-09-16 11:30:00'),
(3,  1, 6, '下册笔记还在整理中，预计下周上传。',                                 2, '2025-09-16 14:00:00'),
(4,  1, 3, '感谢王老师！中值定理那块终于看懂了。',                               0, '2025-09-17 09:00:00'),
-- 资源2 数据结构课件的评论
(5,  2, 3, '课件里面的动画演示太赞了，红黑树旋转一看就明白！',                   0, '2025-09-21 08:00:00'),
(6,  2, 2, '老师能分享一下实验代码吗？',                                         5, '2025-09-21 10:00:00'),
(7,  2, 6, '实验代码在课程群里已经发了，也可以在资源广场搜"数据结构实验"。',    6, '2025-09-21 11:00:00'),
-- 资源8 C语言学生管理系统的评论
(8,  8, 4, '学长这个代码太实用了，我改了一下做成了图书管理系统！',               0, '2025-11-06 12:00:00'),
(9,  8, 5, '注释写得很详细，适合初学者学习文件操作。',                           0, '2025-11-06 15:00:00'),
(10, 8, 3, '学弟学妹们加油，C语言是基础，学好对后面学数据结构有很大帮助。',     0, '2025-11-07 08:00:00'),
(11, 8, 1, '已加精，欢迎同学们踊跃分享优质资源！',                               0, '2025-11-07 09:00:00'),
-- 资源5 计算机网络评论
(12, 5, 2, 'TCP三次握手四次挥手的图总结得很清晰。',                             0, '2025-10-19 10:00:00'),
-- 资源9 Python教程评论
(13, 9, 2, '想学Python好久了，这个教程对新手友好吗？',                           0, '2025-11-11 09:00:00'),
(14, 9, 7, '非常适合零基础，建议跟着视频动手敲代码，效果更好。',                 13, '2025-11-11 10:00:00'),
-- 资源6 SQL练习评论
(15, 6, 3, '第35题的嵌套子查询有更优的写法，可以用EXISTS替代IN。',              0, '2025-10-26 14:00:00'),
(16, 6, 7, '说得对，参考答案里给了两种写法的对比，仔细看看。',                   15, '2025-10-26 15:00:00'),
-- 资源10 软件工程文档评论
(17, 10,5, '这个SRS模板很适合课程设计用，UML图很标准。',                        0, '2025-11-16 10:00:00');

-- ==================== 收藏数据 ====================
INSERT INTO `favorite` (`id`, `user_id`, `resource_id`, `create_time`) VALUES
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
(12, 5, 10, '2025-11-17 13:00:00');

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
