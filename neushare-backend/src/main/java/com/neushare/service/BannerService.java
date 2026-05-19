package com.neushare.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Banner;

import java.util.List;

/**
 * 轮播图服务接口
 */
public interface BannerService extends IService<Banner> {

    /**
     * 获取启用的轮播图列表
     */
    List<Banner> getActiveBanners();

    /**
     * 添加轮播图
     */
    void addBanner(Banner banner);

    /**
     * 更新轮播图
     */
    void updateBanner(Banner banner);

    /**
     * 删除轮播图
     */
    void deleteBanner(Long id);

    /**
     * 更新轮播图状态
     */
    void updateStatus(Long id, Integer status);
}
