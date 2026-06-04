package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.service.FollowService;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/follow")
public class FollowController {

    @Autowired
    private FollowService followService;

    @PostMapping("/add")
    public Result<Void> followUser(HttpServletRequest request, @RequestParam Long followedId) {
        Long userId = (Long) request.getAttribute("userId");
        followService.followUser(userId, followedId);
        return Result.success("关注成功");
    }

    @DeleteMapping("/remove")
    public Result<Void> unfollowUser(HttpServletRequest request, @RequestParam Long followedId) {
        Long userId = (Long) request.getAttribute("userId");
        followService.unfollowUser(userId, followedId);
        return Result.success("取消关注成功");
    }

    @GetMapping("/check")
    public Result<Map<String, Boolean>> checkFollow(HttpServletRequest request, @RequestParam Long followedId) {
        Long userId = (Long) request.getAttribute("userId");
        boolean isFollowing = followService.isFollowing(userId, followedId);
        Map<String, Boolean> result = new HashMap<>();
        result.put("isFollowing", isFollowing);
        return Result.success(result);
    }

    @GetMapping("/following")
    public Result<PageResult<UserVO>> getFollowing(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<UserVO> page = followService.getFollowing(pageNum, pageSize, userId);
        PageResult<UserVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/followers")
    public Result<PageResult<UserVO>> getFollowers(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<UserVO> page = followService.getFollowers(pageNum, pageSize, userId);
        PageResult<UserVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }
}
