-- ============================================================
-- NeuShare V7 迁移：用户自带 AI API Key（BYOK）
-- 执行方式：mysql -u root -p neushare < migration_V7_user_ai_keys.sql
--
-- 设计约定：
--   1. 不动 user 表：AI 配置单独一张表，一个用户一行（user_id 唯一）
--   2. key 在 Java 侧用 AES-256-GCM 加密后入库，主密钥来自
--      application.yml 的 ai.key-encrypt-secret（生产环境必须换掉默认值）
--   3. 明文 key 只有两个出口：用户自己的 PUT/GET 掩码接口、
--      AI 服务持用户 JWT 调用的 /api/ai/config/internal。前端永远见不到明文。
-- ============================================================

USE neushare;

CREATE TABLE IF NOT EXISTS `ai_user_api_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '用户ID（user.id）',
    `deepseek_key_enc` TEXT COMMENT 'DeepSeek API key 密文（AES-256-GCM，Base64；NULL=未配置）',
    `tavily_key_enc` TEXT COMMENT 'Tavily API key 密文（AES-256-GCM，Base64；NULL=未配置）',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户自带 AI API Key（BYOK）';
