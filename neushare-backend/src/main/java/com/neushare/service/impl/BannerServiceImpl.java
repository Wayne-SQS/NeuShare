package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Banner;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.BannerMapper;
import com.neushare.service.BannerService;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 轮播图服务实现类
 */
@Service
public class BannerServiceImpl extends ServiceImpl<BannerMapper, Banner> implements BannerService {

    @Override
    public List<Banner> getActiveBanners() {
        return list(new LambdaQueryWrapper<Banner>()
                .eq(Banner::getStatus, 1)
                .orderByAsc(Banner::getSort));
    }

    @Override
    public void addBanner(Banner banner) {
        banner.setCreateTime(LocalDateTime.now());
        if (banner.getStatus() == null) {
            banner.setStatus(1);
        }
        if (banner.getSort() == null) {
            banner.setSort(0);
        }
        save(banner);
    }

    @Override
    public void updateBanner(Banner banner) {
        Banner existBanner = getById(banner.getId());
        if (existBanner == null) {
            throw new BusinessException("轮播图不存在");
        }
        updateById(banner);
    }

    @Override
    public void deleteBanner(Long id) {
        Banner banner = getById(id);
        if (banner == null) {
            throw new BusinessException("轮播图不存在");
        }
        removeById(id);
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        Banner banner = getById(id);
        if (banner == null) {
            throw new BusinessException("轮播图不存在");
        }
        banner.setStatus(status);
        updateById(banner);
    }
}
