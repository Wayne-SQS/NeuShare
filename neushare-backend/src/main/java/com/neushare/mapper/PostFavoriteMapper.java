package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.PostFavorite;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 帖子收藏Mapper接口
 */
@Mapper
public interface PostFavoriteMapper extends BaseMapper<PostFavorite> {

    PostFavorite selectByUserIdAndPostId(@Param("userId") Long userId, @Param("postId") Long postId);
}
