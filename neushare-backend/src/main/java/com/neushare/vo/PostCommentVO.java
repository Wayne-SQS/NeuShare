package com.neushare.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 帖子评论视图对象（包含用户信息）
 */
@Data
public class PostCommentVO {

    private Long id;

    private Long postId;

    private Long userId;

    private String content;

    private Long parentId;

    private Integer deleted;

    private LocalDateTime createTime;

    private String nickname;

    private String avatarUrl;

    private List<PostCommentVO> children;
}
