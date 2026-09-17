package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Comment;
import com.neushare.vo.CommentVO;
import com.neushare.vo.MyCommentVO;

import java.util.List;

/**
 * 评论服务接口
 */
public interface CommentService extends IService<Comment> {

    /**
     * 获取资源的评论列表
     */
    List<CommentVO> getCommentsByResourceId(Long resourceId);

    /**
     * 添加评论
     */
    void addComment(Long resourceId, Long userId, String content, Long parentId);

    /**
     * 删除评论
     */
    void deleteComment(Long id, Long userId);

    /**
     * 获取用户的评论列表
     */
    IPage<CommentVO> getCommentsByUserId(Integer pageNum, Integer pageSize, Long userId);

    /**
     * 分页获取所有评论（管理员）
     */
    IPage<CommentVO> getCommentVOPage(Integer pageNum, Integer pageSize);

    /**
     * 获取用户的所有评论（合并资源评论 + 帖子评论）
     */
    IPage<MyCommentVO> getMyCommentsMerged(Integer pageNum, Integer pageSize, Long userId);

    /**
     * 点赞资源评论
     */
    void likeComment(Long commentId, Long userId);

    /**
     * 取消点赞资源评论
     */
    void unlikeComment(Long commentId, Long userId);

    /**
     * 检查是否已点赞资源评论
     */
    boolean isCommentLiked(Long commentId, Long userId);
}
