package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Post;
import com.neushare.entity.PostComment;
import com.neushare.entity.PostCommentLike;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.PostCommentLikeMapper;
import com.neushare.mapper.PostCommentMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.NotificationService;
import com.neushare.service.PostCommentService;
import com.neushare.service.PostService;
import com.neushare.vo.PostCommentVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 帖子评论服务实现类
 */
@Slf4j
@Service
public class PostCommentServiceImpl extends ServiceImpl<PostCommentMapper, PostComment> implements PostCommentService {

    @Autowired
    private PostCommentMapper postCommentMapper;

    @Autowired
    private PostCommentLikeMapper postCommentLikeMapper;

    @Autowired
    private PostService postService;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @Override
    public List<PostCommentVO> getCommentTree(Long postId) {
        List<PostCommentVO> allComments = postCommentMapper.selectCommentsByPostId(postId);
        List<PostCommentVO> roots = allComments.stream()
                .filter(c -> c.getParentId() == null || c.getParentId() == 0)
                .collect(Collectors.toList());
        for (PostCommentVO root : roots) {
            root.setChildren(findChildren(root.getId(), allComments));
        }
        return roots;
    }

    private List<PostCommentVO> findChildren(Long parentId, List<PostCommentVO> allComments) {
        List<PostCommentVO> children = new ArrayList<>();
        for (PostCommentVO comment : allComments) {
            if (parentId.equals(comment.getParentId())) {
                comment.setChildren(findChildren(comment.getId(), allComments));
                children.add(comment);
            }
        }
        return children;
    }

    @Override
    public void addComment(Long postId, Long userId, String content, Long parentId) {
        PostComment comment = new PostComment();
        comment.setPostId(postId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setParentId(parentId != null ? parentId : 0L);
        comment.setDeleted(0);
        comment.setCreateTime(LocalDateTime.now());
        comment.setUpdateTime(LocalDateTime.now());
        save(comment);

        // 原子更新帖子评论数
        postService.update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, postId)
                .setSql("comment_count = comment_count + 1"));

        // 通知帖子作者（如果评论者不是作者本人）
        Post post = postService.getById(postId);
        if (post != null && !post.getUserId().equals(userId)) {
            User user = userMapper.selectById(userId);
            String userName = user != null ? user.getNickname() : "有人";
            notificationService.send(post.getUserId(), "comment", postId, userId,
                    "有人评论了你的帖子",
                    userName + " 评论了你的帖子「" + post.getTitle() + "」。");
        }

        // 如果是回复，通知被回复者
        if (parentId != null && parentId > 0) {
            PostComment parentComment = getById(parentId);
            if (parentComment != null && !parentComment.getUserId().equals(userId)) {
                User user = userMapper.selectById(userId);
                String userName = user != null ? user.getNickname() : "有人";
                String postTitle = post != null ? post.getTitle() : "未知帖子";
                notificationService.send(parentComment.getUserId(), "comment", postId, userId,
                        "有人回复了你的评论",
                        "在帖子「" + postTitle + "」中，" + userName + " 回复了你的评论。");
            }
        }
    }

    @Override
    public void deleteComment(Long id, Long userId, String role) {
        PostComment comment = getById(id);
        if (comment == null) {
            throw new BusinessException("评论不存在");
        }
        // 权限校验：评论者本人 或 管理员
        boolean isCommentOwner = comment.getUserId().equals(userId);
        boolean isAdmin = "admin".equals(role);
        if (!isCommentOwner && !isAdmin) {
            throw new BusinessException("无权删除此评论");
        }
        // 软删除：标记为已删除，内容替换
        comment.setDeleted(1);
        comment.setContent("该评论已被删除");
        comment.setUpdateTime(LocalDateTime.now());
        updateById(comment);

        // 原子递减帖子评论数
        if (comment.getPostId() != null) {
            try {
                postService.update(new LambdaUpdateWrapper<Post>()
                        .eq(Post::getId, comment.getPostId())
                        .gt(Post::getCommentCount, 0)
                        .setSql("comment_count = comment_count - 1"));
            } catch (Exception e) {
                // 评论数校准失败不影响删除操作
                log.error("递减帖子评论数失败: postId={}", comment.getPostId(), e);
            }
        }
    }

    @Override
    public void likePostComment(Long commentId, Long userId) {
        PostComment comment = getById(commentId);
        if (comment == null) {
            throw new BusinessException("评论不存在");
        }
        PostCommentLike existing = postCommentLikeMapper.selectByUserIdAndCommentId(userId, commentId);
        if (existing != null) {
            throw new BusinessException("已经点过赞了");
        }
        PostCommentLike like = new PostCommentLike();
        like.setUserId(userId);
        like.setCommentId(commentId);
        postCommentLikeMapper.insert(like);
        update(new LambdaUpdateWrapper<PostComment>()
                .eq(PostComment::getId, commentId)
                .setSql("like_count = like_count + 1"));
    }

    @Override
    public void unlikePostComment(Long commentId, Long userId) {
        PostComment comment = getById(commentId);
        if (comment == null) {
            throw new BusinessException("评论不存在");
        }
        PostCommentLike existing = postCommentLikeMapper.selectByUserIdAndCommentId(userId, commentId);
        if (existing == null) {
            throw new BusinessException("还没有点赞");
        }
        postCommentLikeMapper.deleteById(existing.getId());
        update(new LambdaUpdateWrapper<PostComment>()
                .eq(PostComment::getId, commentId)
                .gt(PostComment::getLikeCount, 0)
                .setSql("like_count = like_count - 1"));
    }

    @Override
    public boolean isPostCommentLiked(Long commentId, Long userId) {
        return postCommentLikeMapper.selectByUserIdAndCommentId(userId, commentId) != null;
    }
}
