package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.Favorite;
import com.neushare.vo.ResourceVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 收藏Mapper接口
 */
@Mapper
public interface FavoriteMapper extends BaseMapper<Favorite> {

    /**
     * 查询用户收藏的资源列表
     */
    IPage<ResourceVO> selectUserFavorites(Page<ResourceVO> page, @Param("userId") Long userId);

    /**
     * 检查用户是否已收藏该资源
     */
    Favorite selectByUserIdAndResourceId(@Param("userId") Long userId, @Param("resourceId") Long resourceId);
}
