-- ============================================================
-- NeuShare V4 迁移：AI 智能体 + RAG 知识库
-- 执行方式：mysql -u root -p neushare < migration_V4_ai_agent.sql
--
-- 设计约定：
--   1. 向量本身存在 Qdrant，MySQL 只存元数据与关联关系
--   2. 两侧靠 doc_id / ref_id 对齐，删除时按元数据过滤物理删向量
--   3. 换 embedding 模型必须全量重建索引（向量空间不兼容）
-- ============================================================

USE neushare;

-- 1. AI 会话表
CREATE TABLE IF NOT EXISTS `ai_chat_session` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '会话ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `title` VARCHAR(100) DEFAULT '新对话' COMMENT '会话标题（首条问题截断/LLM生成）',
    `model` VARCHAR(50) DEFAULT 'deepseek-chat' COMMENT '使用的模型',
    `message_count` INT DEFAULT 0 COMMENT '消息轮数',
    `total_tokens` INT DEFAULT 0 COMMENT '累计消耗token',
    `deleted` TINYINT DEFAULT 0 COMMENT '0-正常 1-已删除',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_update_time` (`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI会话表';

-- 2. AI 消息表（同时作为 ChatMemory 的持久化载体）
CREATE TABLE IF NOT EXISTS `ai_chat_message` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '消息ID',
    `session_id` BIGINT NOT NULL COMMENT '会话ID',
    `role` VARCHAR(20) NOT NULL COMMENT 'user/assistant/tool',
    `content` TEXT COMMENT '消息内容',
    `tool_calls` JSON DEFAULT NULL COMMENT '工具调用记录（工具名+入参+结果摘要）',
    `citations` JSON DEFAULT NULL COMMENT '引用溯源：命中的 ref_id 列表',
    `prompt_tokens` INT DEFAULT 0,
    `completion_tokens` INT DEFAULT 0,
    `latency_ms` INT DEFAULT 0 COMMENT '响应耗时',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI消息表';

-- 3. 知识文档元数据表（一个 doc 对应向量库里 N 个 chunk）
CREATE TABLE IF NOT EXISTS `ai_knowledge_doc` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '文档ID',
    `doc_id` VARCHAR(64) NOT NULL COMMENT '向量库关联ID（UUID，全局唯一）',
    `source_type` VARCHAR(20) NOT NULL COMMENT 'RESOURCE/POST/STATIC/DOC',
    `ref_id` BIGINT DEFAULT NULL COMMENT '关联业务ID（资源ID/帖子ID，静态语料为NULL）',
    `title` VARCHAR(200) NOT NULL COMMENT '文档标题',
    `file_path` VARCHAR(500) DEFAULT NULL COMMENT '本地文件路径（仅上传文档）',
    `content_hash` VARCHAR(64) DEFAULT NULL COMMENT '内容hash，用于判断是否需要重建',
    `chunk_count` INT DEFAULT 0 COMMENT '切块数量',
    `embedding_model` VARCHAR(50) NOT NULL COMMENT '入库时使用的embedding模型（换模型需重建）',
    `status` TINYINT DEFAULT 1 COMMENT '0-待入库 1-已入库 2-入库失败 3-已失效',
    `error_msg` VARCHAR(500) DEFAULT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_doc_id` (`doc_id`),
    UNIQUE KEY `uk_source_ref` (`source_type`, `ref_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG知识文档元数据表';

-- 4. 向量同步队列表（增量入库 / 删除，带失败重试）
CREATE TABLE IF NOT EXISTS `ai_embedding_sync` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '任务ID',
    `source_type` VARCHAR(20) NOT NULL COMMENT 'RESOURCE/POST/STATIC/DOC',
    `ref_id` BIGINT DEFAULT NULL COMMENT '关联业务ID',
    `op` VARCHAR(10) NOT NULL COMMENT 'UPSERT/DELETE',
    `status` TINYINT DEFAULT 0 COMMENT '0-待处理 1-处理中 2-成功 3-失败',
    `retry_count` INT DEFAULT 0 COMMENT '重试次数（上限3）',
    `error_msg` VARCHAR(500) DEFAULT NULL,
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_status_retry` (`status`, `retry_count`),
    KEY `idx_source_ref` (`source_type`, `ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='向量同步任务队列表';

-- 5. Spring AI JDBC ChatMemory 所需表（若改用自定义 ChatMemoryRepository 可跳过）
CREATE TABLE IF NOT EXISTS `spring_ai_chat_memory` (
    `conversation_id` VARCHAR(36) NOT NULL,
    `content` TEXT NOT NULL,
    `type` VARCHAR(10) NOT NULL,
    `timestamp` TIMESTAMP NOT NULL,
    PRIMARY KEY (`conversation_id`, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Spring AI 会话记忆表';

-- 6. 资源表补充：记录向量化状态，避免重复入库
ALTER TABLE `resource` ADD COLUMN `indexed` TINYINT DEFAULT 0 COMMENT '是否已入向量库 0-否 1-是' AFTER `favorite_count`;
ALTER TABLE `resource` ADD INDEX `idx_status_indexed` (`status`, `indexed`);
