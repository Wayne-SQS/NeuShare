package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.service.FavoriteService;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/favorite")
public class FavoriteController {

    @Autowired
    private FavoriteService favoriteService;

    @PostMapping("/add")
    public Result<Void> addFavorite(HttpServletRequest request, @RequestParam Long resourceId) {
        Long userId = (Long) request.getAttribute("userId");
        favoriteService.addFavorite(userId, resourceId);
        return Result.success("收藏成功");
    }

    @DeleteMapping("/remove")
    public Result<Void> removeFavorite(HttpServletRequest request, @RequestParam Long resourceId) {
        Long userId = (Long) request.getAttribute("userId");
        favoriteService.removeFavorite(userId, resourceId);
        return Result.success("取消收藏成功");
    }

    @GetMapping("/check")
    public Result<Map<String, Boolean>> checkFavorite(HttpServletRequest request, @RequestParam Long resourceId) {
        Long userId = (Long) request.getAttribute("userId");
        boolean isFavorite = favoriteService.isFavorite(userId, resourceId);
        Map<String, Boolean> result = new HashMap<>();
        result.put("isFavorite", isFavorite);
        return Result.success(result);
    }

    @GetMapping("/list")
    public Result<PageResult<ResourceVO>> getUserFavorites(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<ResourceVO> page = favoriteService.getUserFavorites(pageNum, pageSize, userId);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }
}
