package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.service.CommentService;
import com.neushare.vo.CommentVO;
import com.neushare.vo.MyCommentVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

@RestController
@RequestMapping("/api/comment")
public class CommentController {

    @Autowired
    private CommentService commentService;

    @GetMapping("/list/{resourceId}")
    public Result<List<CommentVO>> getComments(@PathVariable Long resourceId) {
        List<CommentVO> comments = commentService.getCommentsByResourceId(resourceId);
        return Result.success(comments);
    }

    @PostMapping("/add")
    public Result<Void> addComment(HttpServletRequest request,
                                   @RequestParam Long resourceId,
                                   @RequestParam String content,
                                   @RequestParam(required = false) Long parentId) {
        Long userId = (Long) request.getAttribute("userId");
        commentService.addComment(resourceId, userId, content, parentId);
        return Result.success("评论成功");
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        commentService.deleteComment(id, userId);
        return Result.success("删除成功");
    }

    @GetMapping("/user")
    public Result<PageResult<CommentVO>> getUserComments(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<CommentVO> page = commentService.getCommentsByUserId(pageNum, pageSize, userId);
        PageResult<CommentVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/my")
    public Result<PageResult<MyCommentVO>> getMyComments(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<MyCommentVO> page = commentService.getMyCommentsMerged(pageNum, pageSize, userId);
        PageResult<MyCommentVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @PostMapping("/like/{id}")
    public Result<Void> likeComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        commentService.likeComment(id, userId);
        return Result.success("点赞成功");
    }

    @DeleteMapping("/like/{id}")
    public Result<Void> unlikeComment(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        commentService.unlikeComment(id, userId);
        return Result.success("取消点赞成功");
    }

    @GetMapping("/like/check/{id}")
    public Result<Boolean> checkCommentLiked(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.success(commentService.isCommentLiked(id, userId));
    }
}
