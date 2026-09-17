package com.neushare.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 统一「我的评论」VO
 * 合并资源评论和帖子评论，按时间倒序排列
 */
@Data
public class MyCommentVO {

    /** 评论ID */
    private Long id;

    /** 来源ID（resource.id 或 post.id） */
    private Long sourceId;

    /** 来源类型："resource" 或 "post" */
    private String sourceType;

    /** 来源标题（resource.title 或 post.title） */
    private String sourceTitle;

    /** 评论内容 */
    private String content;

    /** 父评论ID（0=一级评论） */
    private Long parentId;

    /** 是否已删除 0-正常 1-已删除 */
    private Integer deleted;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 点赞数 */
    private Integer likeCount;

    /** 回复数（子评论数量） */
    private Integer replyCount;
}
