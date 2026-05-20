package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.Follow;
import com.neushare.vo.UserVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface FollowMapper extends BaseMapper<Follow> {

    Follow selectByFollowerIdAndFollowedId(@Param("followerId") Long followerId, @Param("followedId") Long followedId);

    IPage<UserVO> selectFollowing(Page<UserVO> page, @Param("followerId") Long followerId);

    IPage<UserVO> selectFollowers(Page<UserVO> page, @Param("followedId") Long followedId);
}
