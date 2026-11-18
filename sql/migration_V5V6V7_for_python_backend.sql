-- ============================================================
-- Python 主干取优合并：把 master 的 V5/V6/V7 能力迁到 Python 后端
-- 执行：mysql -h 127.0.0.1 -P 3307 -u root -p neushare < migration_V5V6V7_for_python_backend.sql
--
-- 前提：数据库表结构保持与 Java 版一致（迁移计划硬约束）。
-- 本脚本只加列 / 加索引 / 加表，不改名、不改类型、不删数据。
-- 可重复执行（每步前先探测，已存在则跳过）。
-- ============================================================

USE neushare;

-- ------------------------------------------------------------
-- V5-1 结构化字段（course_name / teacher / school_year / term）
-- MySQL 8 支持 ADD COLUMN IF NOT EXISTS 以外的写法，这里用存储过程做幂等探测。
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS _ns_add_col;
DELIMITER $$
CREATE PROCEDURE _ns_add_col(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND COLUMN_NAME = col) THEN
    SET @s = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN ', ddl);
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
DELIMITER ;

CALL _ns_add_col('resource', 'course_name',  '`course_name` VARCHAR(100) DEFAULT NULL COMMENT ''课程名称'' AFTER `category_id`');
CALL _ns_add_col('resource', 'teacher',      '`teacher` VARCHAR(50) DEFAULT NULL COMMENT ''授课教师'' AFTER `course_name`');
CALL _ns_add_col('resource', 'school_year',  '`school_year` VARCHAR(20) DEFAULT NULL COMMENT ''学年，如 2024-2025'' AFTER `teacher`');
CALL _ns_add_col('resource', 'term',         '`term` VARCHAR(20) DEFAULT NULL COMMENT ''学期 spring/summer/autumn/winter'' AFTER `school_year`');
CALL _ns_add_col('resource', 'tags_text',    '`tags_text` TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(`tags`, ''$[*]''))) STORED COMMENT ''tags 文本化，供全文索引'' AFTER `tags`');
DROP PROCEDURE IF EXISTS _ns_add_col;

-- ------------------------------------------------------------
-- V5-2 结构化筛选索引 + 中文全文索引（ngram）
-- 注意：ngram_token_size 是 MySQL 实例级参数（默认 2），改 my.cnf 后需重启。
-- 若实例未开 ngram，创建 FULLTEXT 会失败；Python 后端会自动降级为 LIKE，不报错。
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS _ns_add_idx;
DELIMITER $$
CREATE PROCEDURE _ns_add_idx(IN tbl VARCHAR(64), IN idx VARCHAR(64), IN ddl TEXT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND INDEX_NAME = idx) THEN
    SET @s = CONCAT('ALTER TABLE `', tbl, '` ', ddl);
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
DELIMITER ;

CALL _ns_add_idx('resource', 'idx_course_name', 'ADD INDEX `idx_course_name` (`course_name`)');
CALL _ns_add_idx('resource', 'idx_teacher',     'ADD INDEX `idx_teacher` (`teacher`)');
CALL _ns_add_idx('resource', 'idx_school_year', 'ADD INDEX `idx_school_year` (`school_year`)');
CALL _ns_add_idx('resource', 'idx_type',        'ADD INDEX `idx_type` (`type`)');
CALL _ns_add_idx('resource', 'ft_resource_search',
                 'ADD FULLTEXT INDEX `ft_resource_search` (`title`,`description`,`tags_text`) WITH PARSER ngram');
DROP PROCEDURE IF EXISTS _ns_add_idx;

-- ------------------------------------------------------------
-- V5-3 搜索日志：记录搜了什么、命中多少、用了哪些筛选
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `search_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT DEFAULT NULL COMMENT '用户ID（未登录为空）',
  `keyword` VARCHAR(100) NOT NULL,
  `result_count` INT DEFAULT 0,
  `filters` VARCHAR(255) DEFAULT NULL,
  `search_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_keyword` (`keyword`),
  KEY `idx_search_time` (`search_time`),
  KEY `idx_zero_result` (`result_count`,`keyword`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='搜索日志表';

-- ------------------------------------------------------------
-- V6 存量课程名回填：只补空值、幂等、匹配不上保持原值
-- 与 master 的 migration_V6_backfill_course.sql 同一套词典
-- ------------------------------------------------------------
UPDATE resource
SET course_name = (
  CASE
    WHEN title LIKE '%数据结构%' OR title LIKE '%数据结构与算法%' THEN '数据结构与算法'
    WHEN title LIKE '%面向对象%' OR title LIKE '%JAVA%' OR title LIKE '%Java%' THEN '面向对象程序设计（JAVA）'
    WHEN title LIKE '%高等数学%' OR title LIKE '%高数%' THEN '高等数学'
    WHEN title LIKE '%线性代数%' OR title LIKE '%线代%' THEN '线性代数'
    WHEN title LIKE '%概率论%' OR title LIKE '%数理统计%' THEN '概率论与数理统计'
    WHEN title LIKE '%离散数学%' THEN '离散数学'
    WHEN title LIKE '%计算机组成原理%' OR title LIKE '%计组%' OR title LIKE '%组成原理%' THEN '计算机组成原理'
    WHEN title LIKE '%操作系统%' THEN '操作系统'
    WHEN title LIKE '%计算机网络%' OR title LIKE '%计网%' THEN '计算机网络'
    WHEN title LIKE '%编译原理%' THEN '编译原理'
    WHEN title LIKE '%数据库原理%' OR title LIKE '%数据库系统%' THEN '数据库原理'
    WHEN title LIKE '%软件工程%' OR title LIKE '%软工%' THEN '软件工程'
    WHEN title LIKE '%软件项目管理%' OR title LIKE '%项目管理%' THEN '软件项目管理'
    WHEN title LIKE '%算法设计%' OR title LIKE '%算法分析%' THEN '数据结构与算法'
    WHEN title LIKE '%程序设计基础%' OR title LIKE '%C语言%' OR title LIKE '%C 语言%' THEN '程序设计基础'
    WHEN title LIKE '%Python%' OR title LIKE '%python%' OR title LIKE '%数据分析%' THEN 'Python编程与数据分析'
    WHEN title LIKE '%Web开发%' OR title LIKE '%前端%' THEN 'Web开发技术'
    WHEN title LIKE '%机器学习%' THEN '机器学习'
    WHEN title LIKE '%人工智能%' OR title LIKE '%AI导论%' THEN '人工智能导论'
    WHEN title LIKE '%信息安全%' OR title LIKE '%网络安全%' THEN '信息安全'
    WHEN title LIKE '%大学英语%' OR title LIKE '%四级%' OR title LIKE '%六级%' THEN '大学英语'
    WHEN title LIKE '%大学物理%' THEN '大学物理'
    WHEN title LIKE '%毕业设计%' THEN '毕业设计'
    WHEN title LIKE '%毕业实习%' THEN '毕业实习'
    WHEN title LIKE '%毕业论文%' THEN '毕业论文'
    ELSE course_name
  END
)
WHERE course_name IS NULL OR course_name = '';

-- ------------------------------------------------------------
-- V7 BYOK：用户自带 AI Key（AES-256-GCM 密文，主密钥只在环境变量里）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ai_user_api_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `deepseek_key_enc` TEXT COMMENT 'DeepSeek key 密文（Base64: nonce+ct）',
  `tavily_key_enc` TEXT COMMENT 'Tavily key 密文',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户自带 AI API Key';

-- ------------------------------------------------------------
-- 验收
-- ------------------------------------------------------------
-- SELECT COUNT(*) AS total, SUM(CASE WHEN course_name IS NULL OR course_name='' THEN 1 ELSE 0 END) AS missing FROM resource;
-- SELECT course_name, COUNT(*) FROM resource WHERE course_name IS NOT NULL AND course_name<>'' GROUP BY course_name ORDER BY 2 DESC;
-- SELECT keyword, COUNT(*) FROM search_log WHERE result_count = 0 GROUP BY keyword ORDER BY 2 DESC LIMIT 20;
-- SHOW INDEX FROM resource WHERE Key_name IN ('ft_resource_search','idx_course_name','idx_teacher');
