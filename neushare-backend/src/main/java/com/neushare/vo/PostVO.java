package com.neushare.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 帖子视图对象（包含作者信息）
 */
@Data
public class PostVO {

    private Long id;

    private Long userId;

    private String title;

    private String content;

    private String tags;

    private String imageUrls;

    private String files;

    private Integer isRecommended;

    private Integer viewCount;

    private Integer likeCount;

    private Integer favoriteCount;

    private Integer commentCount;

    private Integer status;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    private String authorNickname;

    private String authorAvatarUrl;

    private String authorCollege;
}
