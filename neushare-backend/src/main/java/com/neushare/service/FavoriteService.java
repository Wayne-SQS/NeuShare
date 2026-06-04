package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Favorite;
import com.neushare.vo.ResourceVO;

/**
 * 收藏服务接口
 */
public interface FavoriteService extends IService<Favorite> {

    /**
     * 添加收藏
     */
    void addFavorite(Long userId, Long resourceId);

    /**
     * 取消收藏
     */
    void removeFavorite(Long userId, Long resourceId);

    /**
     * 检查是否已收藏
     */
    boolean isFavorite(Long userId, Long resourceId);

    /**
     * 获取用户收藏列表
     */
    IPage<ResourceVO> getUserFavorites(Integer pageNum, Integer pageSize, Long userId);
}
