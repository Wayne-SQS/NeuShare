package com.neushare.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 资源视图对象（包含上传者信息）
 */
@Data
public class ResourceVO {

    /**
     * 资源ID
     */
    private Long id;

    /**
     * 资源标题
     */
    private String title;

    /**
     * 分类ID
     */
    private Long categoryId;

    /**
     * 分类名称
     */
    private String categoryName;

    /**
     * 课程名称
     */
    private String courseName;

    /**
     * 授课教师
     */
    private String teacher;

    /**
     * 学年，如 2024-2025
     */
    private String schoolYear;

    /**
     * 学期：spring / summer / autumn / winter
     */
    private String term;

    /**
     * 资源类型
     */
    private String type;

    /**
     * 资源内容URL
     */
    private String contentUrl;

    /**
     * 资源描述
     */
    private String description;

    /**
     * 封面图URL
     */
    private String coverUrl;

    /**
     * 来源网站
     */
    private String source;

    /**
     * 标签（JSON数组字符串）
     */
    private String tags;

    /**
     * 上传用户ID
     */
    private Long uploadUserId;

    /**
     * 状态
     */
    private Integer status;

    /**
     * 浏览次数
     */
    private Integer viewCount;

    /**
     * 点赞数
     */
    private Integer likeCount;

    /**
     * 收藏数
     */
    private Integer favoriteCount;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    private LocalDateTime updateTime;

    /**
     * 上传者用户名
     */
    private String uploadUsername;

    /**
     * 上传者昵称
     */
    private String uploadNickname;

    /**
     * 上传者头像
     */
    private String uploadAvatar;

    /**
     * 收藏时间（仅在收藏列表中返回）
     */
    private LocalDateTime favoriteTime;

    /**
     * 全文检索相关度（仅关键词搜索时有值）
     */
    private Double relevance;
}
