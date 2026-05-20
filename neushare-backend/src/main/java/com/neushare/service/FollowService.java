package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Follow;
import com.neushare.vo.UserVO;

public interface FollowService extends IService<Follow> {

    void followUser(Long followerId, Long followedId);

    void unfollowUser(Long followerId, Long followedId);

    boolean isFollowing(Long followerId, Long followedId);

    IPage<UserVO> getFollowing(Integer pageNum, Integer pageSize, Long followerId);

    IPage<UserVO> getFollowers(Integer pageNum, Integer pageSize, Long followedId);
}
