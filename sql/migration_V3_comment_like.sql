-- ============================================================
-- NeuShare V3 迁移：评论点赞系统 + 我的评论查询优化
-- 执行方式：mysql -u root -p neushare < migration_V3_comment_like.sql
-- ============================================================

USE neushare;

-- 1. comment 表增加 like_count 列
ALTER TABLE `comment` ADD COLUMN `like_count` INT DEFAULT 0 COMMENT '点赞数' AFTER `deleted`;

-- 2. post_comment 表增加 like_count 列
ALTER TABLE `post_comment` ADD COLUMN `like_count` INT DEFAULT 0 COMMENT '点赞数' AFTER `deleted`;

-- 3. 新建 comment_like 表（资源评论点赞记录）
CREATE TABLE IF NOT EXISTS `comment_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `comment_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_comment` (`user_id`, `comment_id`),
    KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源评论点赞记录表';

-- 4. 新建 post_comment_like 表（帖子评论点赞记录）
CREATE TABLE IF NOT EXISTS `post_comment_like` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `comment_id` BIGINT NOT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_comment` (`user_id`, `comment_id`),
    KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子评论点赞记录表';

-- 5. comment 表增加 parent_id 索引（加速回复数子查询）
ALTER TABLE `comment` ADD INDEX `idx_parent_id` (`parent_id`);

-- 6. post_comment 表增加 parent_id 索引
ALTER TABLE `post_comment` ADD INDEX `idx_parent_id` (`parent_id`);
