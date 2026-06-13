package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.ResourceLike;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ResourceLikeMapper extends BaseMapper<ResourceLike> {

    ResourceLike selectByUserIdAndResourceId(@Param("userId") Long userId, @Param("resourceId") Long resourceId);
}
