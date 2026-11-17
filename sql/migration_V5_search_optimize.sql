-- ============================================================
-- NeuShare V5 迁移：搜索能力优化
-- 执行方式：mysql -u root -p neushare < migration_V5_search_optimize.sql
--
-- 解决三个问题：
--   1. LIKE '%关键词%' 全表扫描，数据一大就慢 → 改用 ngram 全文索引
--   2. 搜索结果按时间排，不按匹配度排 → 引入相关度打分
--   3. 只有关键词搜索，无法按「课程 + 教师 + 学年」定位 → 补结构化字段
-- ============================================================

USE neushare;

-- 1. 资源表补充结构化维度（按课程/教师/学年定位资料的核心字段）
ALTER TABLE `resource` ADD COLUMN `course_name` VARCHAR(100) DEFAULT NULL COMMENT '课程名称' AFTER `category_id`;
ALTER TABLE `resource` ADD COLUMN `teacher`     VARCHAR(50)  DEFAULT NULL COMMENT '授课教师' AFTER `course_name`;
ALTER TABLE `resource` ADD COLUMN `school_year` VARCHAR(20)  DEFAULT NULL COMMENT '学年，如 2024-2025' AFTER `teacher`;
ALTER TABLE `resource` ADD COLUMN `term`        VARCHAR(20)  DEFAULT NULL COMMENT '学期：spring/summer/autumn/winter' AFTER `school_year`;

-- 2. 结构化筛选索引
ALTER TABLE `resource` ADD INDEX `idx_course_name` (`course_name`);
ALTER TABLE `resource` ADD INDEX `idx_teacher` (`teacher`);
ALTER TABLE `resource` ADD INDEX `idx_school_year` (`school_year`);
ALTER TABLE `resource` ADD INDEX `idx_type` (`type`);

-- 3. 中文全文索引（ngram 分词器，默认 2 字切分，适配中文）
--    注意 1：ngram_token_size 是 MySQL 实例级参数（默认 2），需在 my.cnf 配置后重启才生效
--    注意 2：tags 是 JSON 列，MySQL 不允许直接对 JSON 建 FULLTEXT（ERROR 3152），
--            先加一列存储型生成列把 tags 数组摊平成文本，再对生成列建索引
ALTER TABLE `resource`
    ADD COLUMN `tags_text` TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(`tags`, '$[*]'))) STORED
    COMMENT 'tags 文本化视图，供全文索引使用（JSON 列不能直接建 FULLTEXT）' AFTER `tags`;

CREATE FULLTEXT INDEX `ft_resource_search` ON `resource` (`title`, `description`, `tags_text`) WITH PARSER ngram;

-- 4. 搜索日志表：记录用户搜了什么、搜到多少，用于发现「搜不到」的高频词
CREATE TABLE IF NOT EXISTS `search_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    `user_id` BIGINT DEFAULT NULL COMMENT '用户ID（未登录为空）',
    `keyword` VARCHAR(100) NOT NULL COMMENT '搜索关键词',
    `result_count` INT DEFAULT 0 COMMENT '命中结果数',
    `filters` VARCHAR(255) DEFAULT NULL COMMENT '结构化筛选条件摘要',
    `search_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '搜索时间',
    PRIMARY KEY (`id`),
    KEY `idx_keyword` (`keyword`),
    KEY `idx_search_time` (`search_time`),
    KEY `idx_zero_result` (`result_count`, `keyword`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='搜索日志表';

-- ============================================================
-- 验证语句（执行完可跑一下确认索引生效）
-- ============================================================
-- SHOW INDEX FROM resource WHERE Key_name = 'ft_resource_search';
--
-- SELECT id, title,
--        MATCH(title, description, tags) AGAINST('操作系统 期末' IN NATURAL LANGUAGE MODE) AS relevance
-- FROM resource
-- WHERE status = 1
--   AND MATCH(title, description, tags) AGAINST('操作系统 期末' IN NATURAL LANGUAGE MODE)
-- ORDER BY relevance DESC
-- LIMIT 10;
--
-- 查看「用户想找但平台没有」的高频词（供给缺口，直接指导运营补内容）：
-- SELECT keyword, COUNT(*) AS cnt
-- FROM search_log
-- WHERE result_count = 0
-- GROUP BY keyword
-- ORDER BY cnt DESC
-- LIMIT 20;
