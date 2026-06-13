package com.neushare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 资源实体类
 */
@Data
@TableName("resource")
public class Resource implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 资源ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 资源标题
     */
    @TableField("title")
    private String title;

    /**
     * 分类ID
     */
    @TableField("category_id")
    private Long categoryId;

    /**
     * 资源类型：document-文档，video-视频，image-图片，other-其他
     */
    @TableField("type")
    private String type;

    /**
     * 资源内容URL
     */
    @TableField("content_url")
    private String contentUrl;

    /**
     * 资源描述
     */
    @TableField("description")
    private String description;

    /**
     * 封面图URL
     */
    @TableField("cover_url")
    private String coverUrl;

    /**
     * 来源网站（B站/GitHub/慕课网等）
     */
    @TableField("source")
    private String source;

    /**
     * 上传用户ID
     */
    @TableField("upload_user_id")
    private Long uploadUserId;

    /**
     * 状态：0-待审核，1-已发布，2-已拒绝
     */
    @TableField("status")
    private Integer status;

    /**
     * 审核驳回原因
     */
    @TableField("reject_reason")
    private String rejectReason;

    /**
     * 浏览次数
     */
    @TableField("view_count")
    private Integer viewCount;

    /**
     * 点赞数
     */
    @TableField("like_count")
    private Integer likeCount;

    /**
     * 收藏数
     */
    @TableField("favorite_count")
    private Integer favoriteCount;

    /**
     * 创建时间
     */
    @TableField("create_time")
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    @TableField("update_time")
    private LocalDateTime updateTime;
}
