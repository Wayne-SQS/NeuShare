package com.neushare.controller;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.entity.Banner;
import com.neushare.entity.Resource;
import com.neushare.entity.User;
import com.neushare.service.*;
import com.neushare.vo.CommentVO;
import com.neushare.vo.ResourceVO;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private UserService userService;

    @Autowired
    private ResourceService resourceService;

    @Autowired
    private CommentService commentService;

    @Autowired
    private BannerService bannerService;

    // ==================== 用户管理 ====================

    @GetMapping("/user/list")
    public Result<PageResult<UserVO>> getUserList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isEmpty()) {
            wrapper.like(User::getUsername, keyword).or().like(User::getNickname, keyword);
        }
        wrapper.orderByDesc(User::getCreateTime);
        Page<User> page = userService.page(new Page<>(pageNum, pageSize), wrapper);
        List<UserVO> voList = page.getRecords().stream().map(u -> {
            UserVO vo = new UserVO();
            BeanUtil.copyProperties(u, vo);
            return vo;
        }).collect(Collectors.toList());
        PageResult<UserVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), voList);
        return Result.success(pageResult);
    }

    @PutMapping("/user/status")
    public Result<Void> updateUserStatus(@RequestParam Long id, @RequestParam Integer status) {
        userService.updateStatus(id, status);
        return Result.success("更新成功");
    }

    @DeleteMapping("/user/delete/{id}")
    public Result<Void> deleteUser(@PathVariable Long id) {
        userService.removeById(id);
        return Result.success("删除成功");
    }

    // ==================== 资源管理 ====================

    @GetMapping("/resource/pending")
    public Result<PageResult<ResourceVO>> getPendingResources(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        IPage<ResourceVO> page = resourceService.getResourcePage(pageNum, pageSize, 0, null, null);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @PutMapping("/resource/audit")
    public Result<Void> auditResource(@RequestParam Long id, @RequestParam Integer status) {
        resourceService.auditResource(id, status);
        return Result.success("审核成功");
    }

    @DeleteMapping("/resource/delete/{id}")
    public Result<Void> deleteResource(@PathVariable Long id) {
        resourceService.removeById(id);
        return Result.success("删除成功");
    }

    // ==================== 评论管理 ====================

    @GetMapping("/comment/list")
    public Result<PageResult<CommentVO>> getCommentList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        IPage<CommentVO> page = commentService.getCommentVOPage(pageNum, pageSize);
        PageResult<CommentVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @DeleteMapping("/comment/delete/{id}")
    public Result<Void> deleteComment(@PathVariable Long id) {
        commentService.removeById(id);
        return Result.success("删除成功");
    }

    // ==================== 轮播图管理 ====================

    @GetMapping("/banner/list")
    public Result<List<Banner>> getBannerList() {
        List<Banner> banners = bannerService.list(new LambdaQueryWrapper<Banner>().orderByAsc(Banner::getSort));
        return Result.success(banners);
    }

    @PostMapping("/banner/add")
    public Result<Void> addBanner(@RequestBody Banner banner) {
        bannerService.addBanner(banner);
        return Result.success("添加成功");
    }

    @PutMapping("/banner/update")
    public Result<Void> updateBanner(@RequestBody Banner banner) {
        bannerService.updateBanner(banner);
        return Result.success("更新成功");
    }

    @DeleteMapping("/banner/delete/{id}")
    public Result<Void> deleteBanner(@PathVariable Long id) {
        bannerService.deleteBanner(id);
        return Result.success("删除成功");
    }

    @PutMapping("/banner/status")
    public Result<Void> updateBannerStatus(@RequestParam Long id, @RequestParam Integer status) {
        bannerService.updateStatus(id, status);
        return Result.success("更新成功");
    }

    // ==================== 统计数据 ====================

    @GetMapping("/statistics")
    public Result<Map<String, Object>> getStatistics() {
        Map<String, Object> statistics = new HashMap<>();
        statistics.put("userCount", userService.count());
        statistics.put("resourceCount", resourceService.count());
        statistics.put("commentCount", commentService.count());
        LambdaQueryWrapper<Resource> pendingWrapper = new LambdaQueryWrapper<>();
        pendingWrapper.eq(Resource::getStatus, 0);
        statistics.put("pendingResourceCount", resourceService.count(pendingWrapper));
        return Result.success(statistics);
    }
}
