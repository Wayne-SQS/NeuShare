package com.neushare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 通知实体类
 */
@Data
@TableName("notification")
public class Notification implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 接收用户ID */
    @TableField("user_id")
    private Long userId;

    /** 通知类型: audit-审核结果, comment-评论回复, follow-被关注, like-被点赞, favorite-被收藏 */
    @TableField("type")
    private String type;

    /** 关联资源ID */
    @TableField("resource_id")
    private Long resourceId;

    /** 触发用户ID（谁触发的通知） */
    @TableField("from_user_id")
    private Long fromUserId;

    /** 通知标题 */
    @TableField("title")
    private String title;

    /** 通知内容 */
    @TableField("content")
    private String content;

    /** 是否已读: 0-未读, 1-已读 */
    @TableField("is_read")
    private Integer isRead;

    @TableField("create_time")
    private LocalDateTime createTime;
}
