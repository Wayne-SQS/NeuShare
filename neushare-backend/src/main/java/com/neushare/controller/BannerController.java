package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.entity.Banner;
import com.neushare.service.BannerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 轮播图控制器
 */
@RestController
@RequestMapping("/api/banner")
public class BannerController {

    @Autowired
    private BannerService bannerService;

    /**
     * 获取启用的轮播图列表
     */
    @GetMapping("/list")
    public Result<List<Banner>> getBannerList() {
        List<Banner> banners = bannerService.getActiveBanners();
        return Result.success(banners);
    }
}
