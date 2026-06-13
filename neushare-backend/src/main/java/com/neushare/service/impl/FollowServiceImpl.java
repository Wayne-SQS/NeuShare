package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Follow;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.FollowMapper;
import com.neushare.service.FollowService;
import com.neushare.service.NotificationService;
import com.neushare.service.UserService;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class FollowServiceImpl extends ServiceImpl<FollowMapper, Follow> implements FollowService {

    @Autowired
    private FollowMapper followMapper;

    @Autowired
    private UserService userService;

    @Autowired
    private NotificationService notificationService;

    @Override
    @Transactional
    public void followUser(Long followerId, Long followedId) {
        if (followerId.equals(followedId)) {
            throw new BusinessException("不能关注自己");
        }
        User followedUser = userService.getById(followedId);
        if (followedUser == null || followedUser.getStatus() == 0) {
            throw new BusinessException("用户不存在或已被禁用");
        }
        Follow existFollow = followMapper.selectByFollowerIdAndFollowedId(followerId, followedId);
        if (existFollow != null) {
            throw new BusinessException("已关注该用户");
        }
        Follow follow = new Follow();
        follow.setFollowerId(followerId);
        follow.setFollowedId(followedId);
        follow.setCreateTime(LocalDateTime.now());
        save(follow);
        // 通知被关注者
        User followerUser = userService.getById(followerId);
        String followerName = followerUser != null ? followerUser.getNickname() : "有人";
        notificationService.send(followedId, "follow", null, followerId,
                "有人关注了你", followerName + " 关注了你。");
    }

    @Override
    @Transactional
    public void unfollowUser(Long followerId, Long followedId) {
        Follow follow = followMapper.selectByFollowerIdAndFollowedId(followerId, followedId);
        if (follow == null) {
            throw new BusinessException("未关注该用户");
        }
        removeById(follow.getId());
    }

    @Override
    public boolean isFollowing(Long followerId, Long followedId) {
        return followMapper.selectByFollowerIdAndFollowedId(followerId, followedId) != null;
    }

    @Override
    public IPage<UserVO> getFollowing(Integer pageNum, Integer pageSize, Long followerId) {
        Page<UserVO> page = new Page<>(pageNum, pageSize);
        return followMapper.selectFollowing(page, followerId);
    }

    @Override
    public IPage<UserVO> getFollowers(Integer pageNum, Integer pageSize, Long followedId) {
        Page<UserVO> page = new Page<>(pageNum, pageSize);
        return followMapper.selectFollowers(page, followedId);
    }
}
