package com.neushare.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.PostComment;
import com.neushare.vo.PostCommentVO;

import java.util.List;

/**
 * 帖子评论服务接口
 */
public interface PostCommentService extends IService<PostComment> {

    List<PostCommentVO> getCommentTree(Long postId);

    void addComment(Long postId, Long userId, String content, Long parentId);

    void deleteComment(Long id, Long userId, String role);

    /**
     * 点赞帖子评论
     */
    void likePostComment(Long commentId, Long userId);

    /**
     * 取消点赞帖子评论
     */
    void unlikePostComment(Long commentId, Long userId);

    /**
     * 检查是否已点赞帖子评论
     */
    boolean isPostCommentLiked(Long commentId, Long userId);
}
