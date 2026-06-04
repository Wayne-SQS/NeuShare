package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Favorite;
import com.neushare.entity.Resource;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.FavoriteMapper;
import com.neushare.service.FavoriteService;
import com.neushare.service.ResourceService;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 收藏服务实现类
 */
@Service
public class FavoriteServiceImpl extends ServiceImpl<FavoriteMapper, Favorite> implements FavoriteService {

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private ResourceService resourceService;

    @Override
    @Transactional
    public void addFavorite(Long userId, Long resourceId) {
        // 检查资源是否存在
        Resource resource = resourceService.getById(resourceId);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 检查是否已收藏
        Favorite existFavorite = favoriteMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (existFavorite != null) {
            throw new BusinessException("已收藏该资源");
        }
        // 添加收藏
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setResourceId(resourceId);
        favorite.setCreateTime(LocalDateTime.now());
        save(favorite);
        // 原子更新收藏数
        resourceService.update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, resourceId)
                .setSql("favorite_count = favorite_count + 1"));
    }

    @Override
    @Transactional
    public void removeFavorite(Long userId, Long resourceId) {
        Favorite favorite = favoriteMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (favorite == null) {
            throw new BusinessException("未收藏该资源");
        }
        removeById(favorite.getId());
        resourceService.update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, resourceId)
                .gt(Resource::getFavoriteCount, 0)
                .setSql("favorite_count = favorite_count - 1"));
    }

    @Override
    public boolean isFavorite(Long userId, Long resourceId) {
        Favorite favorite = favoriteMapper.selectByUserIdAndResourceId(userId, resourceId);
        return favorite != null;
    }

    @Override
    public IPage<ResourceVO> getUserFavorites(Integer pageNum, Integer pageSize, Long userId) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return favoriteMapper.selectUserFavorites(page, userId);
    }
}
