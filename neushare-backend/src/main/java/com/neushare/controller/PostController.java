package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.entity.Post;
import com.neushare.service.PostService;
import com.neushare.vo.PostVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

@RestController
@RequestMapping("/api/post")
public class PostController {

    @Autowired
    private PostService postService;

    @GetMapping("/list")
    public Result<PageResult<PostVO>> getPostList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "new") String sortBy,
            HttpServletRequest request) {
        // 公开接口：未登录用户只能看已发布帖子，防止通过 status 参数窥探待审核/驳回内容
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        boolean isAdminOrOwner = userId != null && "admin".equals(role);
        Integer effectiveStatus = (status != null && isAdminOrOwner) ? status : 1;
        IPage<PostVO> page = postService.getPostPage(pageNum, pageSize, effectiveStatus, tag, keyword, sortBy);
        PageResult<PostVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/detail/{id}")
    public Result<PostVO> getPostDetail(@PathVariable Long id) {
        PostVO postVO = postService.getPostDetail(id);
        if (postVO == null) {
            return Result.error(404, "帖子不存在");
        }
        postService.incrementViewCount(id);
        return Result.success(postVO);
    }

    @GetMapping("/hot")
    public Result<List<PostVO>> getHotPosts(@RequestParam(defaultValue = "10") Integer limit) {
        return Result.success(postService.getHotPosts(limit));
    }

    @PostMapping("/create")
    public Result<Void> createPost(HttpServletRequest request, @RequestBody Post post) {
        Long userId = (Long) request.getAttribute("userId");
        postService.createPost(post, userId);
        return Result.success("发布成功");
    }

    @PutMapping("/update")
    public Result<Void> updatePost(HttpServletRequest request, @RequestBody Post post) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        postService.updatePost(post, userId, role);
        return Result.success("更新成功");
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deletePost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        postService.deletePost(id, userId, role);
        return Result.success("删除成功");
    }

    @PostMapping("/like/{id}")
    public Result<Void> likePost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postService.likePost(id, userId);
        return Result.success("点赞成功");
    }

    @DeleteMapping("/like/{id}")
    public Result<Void> unlikePost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postService.unlikePost(id, userId);
        return Result.success("取消点赞成功");
    }

    @GetMapping("/like/check/{id}")
    public Result<Boolean> checkLiked(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.success(postService.isLiked(id, userId));
    }

    @PostMapping("/favorite/{id}")
    public Result<Void> favoritePost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postService.favoritePost(id, userId);
        return Result.success("收藏成功");
    }

    @DeleteMapping("/favorite/{id}")
    public Result<Void> unfavoritePost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        postService.unfavoritePost(id, userId);
        return Result.success("取消收藏成功");
    }

    @GetMapping("/favorite/check/{id}")
    public Result<Boolean> checkFavorited(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.success(postService.isFavorited(id, userId));
    }

    @GetMapping("/user")
    public Result<PageResult<PostVO>> getUserPosts(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<PostVO> page = postService.getUserPosts(pageNum, pageSize, userId);
        PageResult<PostVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @PutMapping("/recommend/{id}")
    public Result<Void> recommendPost(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        postService.recommendPost(id, userId, role);
        return Result.success("推荐成功");
    }
}
