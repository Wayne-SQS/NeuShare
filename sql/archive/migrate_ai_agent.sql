-- NeuShare AI Agent: 对话历史表
-- 执行: mysql -h 127.0.0.1 -P 3307 -u root -p neushare < migrate_ai_agent.sql

CREATE TABLE IF NOT EXISTS `ai_conversation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '所属用户',
  `title` VARCHAR(200) NOT NULL DEFAULT '新对话' COMMENT '会话标题',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ai_conv_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 助手会话';

CREATE TABLE IF NOT EXISTS `ai_message` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `conversation_id` BIGINT NOT NULL COMMENT '所属会话',
  `role` VARCHAR(20) NOT NULL COMMENT 'user / assistant',
  `content` MEDIUMTEXT NOT NULL COMMENT '消息正文',
  `sources` JSON NULL COMMENT '引用来源 [{title, resource_id, file_name, snippet}]',
  `resources` JSON NULL COMMENT '推荐资源 [{resource_id, title, cover_url}]',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ai_msg_conv` (`conversation_id`),
  CONSTRAINT `fk_ai_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversation` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 助手消息';
