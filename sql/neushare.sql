-- NeuShare 数据库初始化脚本
-- 密码使用BCrypt加密，所有用户密码为: 123456
-- BCrypt密码: $2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW

DROP DATABASE IF EXISTS neushare;
CREATE DATABASE neushare DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

USE neushare;

DROP TABLE IF EXISTS favorite;
DROP TABLE IF EXISTS comment;
DROP TABLE IF EXISTS resource;
DROP TABLE IF EXISTS banner;
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
    username VARCHAR(50) NOT NULL COMMENT '学号/工号',
    password VARCHAR(100) NOT NULL COMMENT '密码(BCrypt加密)',
    role VARCHAR(20) NOT NULL DEFAULT 'student' COMMENT '角色: student/teacher/admin',
    nickname VARCHAR(50) NOT NULL COMMENT '昵称',
    avatar_url VARCHAR(255) DEFAULT NULL COMMENT '头像链接',
    college VARCHAR(50) DEFAULT NULL COMMENT '学院',
    grade INT DEFAULT NULL COMMENT '年级(1-4)',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE resource (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
    title VARCHAR(200) NOT NULL COMMENT '资料标题',
    category_id INT NOT NULL COMMENT '所属分类(1~10)',
    type VARCHAR(20) NOT NULL DEFAULT 'link' COMMENT '类型: link/file/document',
    content_url VARCHAR(500) DEFAULT NULL COMMENT '资源地址',
    description TEXT COMMENT '描述',
    cover_url VARCHAR(255) DEFAULT NULL COMMENT '封面图链接',
    upload_user_id BIGINT NOT NULL COMMENT '上传者ID',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '状态: 0待审核 1已发布 2已驳回',
    view_count INT NOT NULL DEFAULT 0 COMMENT '浏览数',
    like_count INT NOT NULL DEFAULT 0 COMMENT '点赞数',
    favorite_count INT NOT NULL DEFAULT 0 COMMENT '收藏数',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    KEY idx_category (category_id),
    KEY idx_upload_user (upload_user_id),
    KEY idx_status (status),
    KEY idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资料表';

CREATE TABLE comment (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键自增',
    resource_id BIGINT NOT NULL COMMENT '资料ID',
    user_id BIGINT NOT NULL COMMENT '评论人ID',
    content TEXT NOT NULL COMMENT '评论内容',
    parent_id BIGINT NOT NULL DEFAULT 0 COMMENT '回复上级评论ID(0为顶级评论)',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
    PRIMARY KEY (id),
    KEY idx_resource (resource_id),
    KEY idx_user (user_id),
    KEY idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论表';

CREATE TABLE favorite (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    resource_id BIGINT NOT NULL COMMENT '资料ID',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_resource (user_id, resource_id),
    KEY idx_user (user_id),
    KEY idx_resource (resource_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏表';

CREATE TABLE banner (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
    title VARCHAR(100) NOT NULL COMMENT '轮播图标题',
    image_url VARCHAR(255) NOT NULL COMMENT '图片链接',
    link_url VARCHAR(255) DEFAULT NULL COMMENT '跳转链接',
    sort INT NOT NULL DEFAULT 0 COMMENT '排序(越小越靠前)',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='轮播图表';

-- 插入用户数据 (密码都是 123456 的BCrypt加密)
INSERT INTO user (username, password, role, nickname, avatar_url, college, grade, status) VALUES
('admin', '$2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW', 'admin', '系统管理员', NULL, NULL, NULL, 1),
('20240001', '$2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW', 'student', '张同学', NULL, '软件学院', 1, 1),
('20240002', '$2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW', 'student', '李同学', NULL, '软件学院', 1, 1),
('20240003', '$2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW', 'student', '王同学', NULL, '计算机学院', 2, 1),
('T20240001', '$2a$10$EqKcp1WFKVQISheBxmXNGexPR.i7QYXOJC.OFfQDT8iSaHuuPdlrW', 'teacher', '赵老师', NULL, '软件学院', NULL, 1);

-- 插入资料数据
INSERT INTO resource (title, category_id, type, content_url, description, upload_user_id, status, view_count, like_count, favorite_count) VALUES
('数据结构与算法精品网课合集', 1, 'link', 'https://example.com/ds-algorithm', '包含数据结构与算法的完整视频课程，涵盖链表、树、图等核心知识点', 2, 1, 256, 45, 32),
('高等数学题库网站汇总', 2, 'link', 'https://example.com/math-bank', '整理了多个优质高数题库网站，包含历年真题和模拟题', 3, 1, 189, 38, 28),
('Java编程思想推荐阅读', 3, 'document', 'https://example.com/java-book', 'Java经典书籍推荐，适合从入门到进阶的学习路径', 5, 1, 312, 67, 45),
('软件工程教材PDF资源', 4, 'document', 'https://example.com/se-textbook', '软件工程课程配套教材电子版，包含UML建模和设计模式', 2, 1, 145, 23, 18),
('超星学习通使用教程', 5, 'link', 'https://example.com/chaoxing', '超星学习通平台使用指南，包含作业提交和考试操作', 3, 1, 98, 15, 12),
('GitHub入门到精通教程', 6, 'link', 'https://example.com/github-guide', '从零开始学习Git和GitHub，掌握版本控制和团队协作', 4, 1, 278, 52, 41),
('DeepSeek API调用实战教程', 7, 'link', 'https://example.com/deepseek-api', 'DeepSeek大模型API接入教程，包含代码示例和应用场景', 2, 1, 356, 89, 63),
('Claude开发环境搭建指南', 8, 'document', 'https://example.com/claude-setup', 'Claude AI环境配置教程，支持多种编程语言开发辅助', 5, 1, 201, 41, 35),
('GitHub Actions CI/CD学习路径', 9, 'link', 'https://example.com/github-actions', 'GitHub Actions自动化部署教程，从基础到高级工作流配置', 4, 1, 167, 33, 26),
('Java SpringBoot实战教程', 10, 'link', 'https://example.com/springboot', 'SpringBoot框架从入门到实战，包含RESTful API开发', 5, 1, 423, 95, 72),
('操作系统原理网课推荐', 1, 'link', 'https://example.com/os-course', '操作系统核心概念视频讲解，进程管理和内存管理重点', 3, 1, 134, 28, 19),
('线性代数解题方法总结', 2, 'document', 'https://example.com/linear-algebra', '线代常见题型解题技巧，矩阵运算和特征值分析', 4, 1, 178, 36, 25);

-- 插入评论数据
INSERT INTO comment (resource_id, user_id, content, parent_id) VALUES
(1, 3, '这个网课合集太棒了，讲得很清楚！', 0),
(1, 4, '同感，链表那部分讲得特别好', 1),
(2, 2, '题库很全面，感谢整理！', 0),
(7, 2, 'DeepSeek的API确实好用，教程很详细', 0),
(7, 3, '请问有Python版本的示例吗？', 4),
(7, 2, '有的，我后续会补充Python示例', 5),
(10, 4, 'SpringBoot教程非常实用，项目直接用上了', 0),
(10, 5, '同学可以关注下MyBatis-Plus的配合使用', 7);

-- 插入收藏数据
INSERT INTO favorite (user_id, resource_id) VALUES
(2, 7),
(2, 10),
(3, 1),
(3, 2),
(3, 7),
(4, 1),
(4, 6),
(4, 10),
(5, 10),
(5, 3);

-- 插入轮播图数据
INSERT INTO banner (title, image_url, link_url, sort, status) VALUES
('欢迎来到NEU Share', 'https://via.placeholder.com/1200x400/1e293b/ffffff?text=NEU+Share', '/resource', 1, 1),
('精品课程资源推荐', 'https://via.placeholder.com/1200x400/334155/ffffff?text=精品资源', '/resource?categoryId=1', 2, 1),
('AI学习工具合集', 'https://via.placeholder.com/1200x400/475569/ffffff?text=AI学习', '/resource?categoryId=7', 3, 1);
