package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.service.PostCommentService;
import com.neushare.vo.PostCommentVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

@RestController
@RequestMapping("/api/post/comment")
public class PostCommentController {

    @Autowired
    private PostCommentService postCommentService;

    @GetMapping("/list/{postId}")
    public Result<List<PostCommentVO>> getCommentTree(@PathVariable Long postId) {
        return Result.success(postCommentService.getCommentTree(postId));
    }

    @PostMapping("/add")
    public Result<Void> addComment(
            HttpServletRequest request,
            @RequestParam Long postId,
            @RequestParam String content,
            @RequestParam(required = false, defaultValue = "0") Long parentId) {
        Long userId = (Long) request.getAttribute("userId");
        postCommentService.addComment(postId, userId, content, parentId);
        return Result.success("评论成功");
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        postCommentService.deleteComment(id, userId, role);
        return Result.success("删除成功");
    }

    @PostMapping("/like/{id}")
    public Result<Void> likeComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postCommentService.likePostComment(id, userId);
        return Result.success("点赞成功");
    }

    @DeleteMapping("/like/{id}")
    public Result<Void> unlikeComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postCommentService.unlikePostComment(id, userId);
        return Result.success("取消点赞成功");
    }

    @GetMapping("/like/check/{id}")
    public Result<Boolean> checkCommentLiked(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.success(postCommentService.isPostCommentLiked(id, userId));
    }
}
