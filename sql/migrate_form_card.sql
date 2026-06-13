-- NEUShare 服务卡片表迁移脚本
-- 在已有数据库上执行（不删除数据）

USE neushare;

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

-- 示例数据
INSERT INTO `form_card` (`title`, `resource_type`, `resource_id`, `content_url`, `sort_order`, `status`) VALUES
('数据结构与算法课件合集', 'book',    2,  'https://example.com/files/dsa-slides.zip',    1, 1),
('Python数据分析入门教程', 'video',   9,  'https://example.com/files/python-data.mp4',    2, 1),
('C语言-学生管理系统源码', 'software', 8, 'https://example.com/files/student-mgmt-c.zip', 3, 0);
