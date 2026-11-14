package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.LoginDTO;
import com.neushare.dto.RegisterDTO;
import com.neushare.entity.*;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.*;
import com.neushare.service.ResourceService;
import com.neushare.service.UserService;
import com.neushare.util.JwtUtil;
import com.neushare.util.BCryptUtil;
import com.neushare.vo.ResourceVO;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户服务实现类
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ResourceService resourceService;

    @Autowired
    private CommentMapper commentMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private FollowMapper followMapper;

    @Autowired
    private ResourceLikeMapper resourceLikeMapper;

    @Autowired
    private ResourceMapper resourceMapper;

    @Autowired
    private PostMapper postMapper;

    @Autowired
    private PostCommentMapper postCommentMapper;

    @Autowired
    private PostCommentLikeMapper postCommentLikeMapper;

    @Autowired
    private PostLikeMapper postLikeMapper;

    @Autowired
    private PostFavoriteMapper postFavoriteMapper;

    @Autowired
    private NotificationMapper notificationMapper;

    @Override
    public User login(LoginDTO loginDTO) {
        User user = getByUsername(loginDTO.getUsername());
        if (user == null || !BCryptUtil.verify(loginDTO.getPassword(), user.getPassword())) {
            throw new BusinessException("用户名或密码错误");
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BusinessException("账号已被禁用");
        }
        return user;
    }

    @Override
    public void register(RegisterDTO registerDTO) {
        // 检查用户名是否存在
        User existUser = getByUsername(registerDTO.getUsername());
        if (existUser != null) {
            throw new BusinessException("用户名已存在");
        }
        // 创建用户
        User user = new User();
        user.setUsername(registerDTO.getUsername());
        user.setPassword(BCryptUtil.encrypt(registerDTO.getPassword()));
        user.setNickname(registerDTO.getNickname() != null ? registerDTO.getNickname() : registerDTO.getUsername());
        user.setAvatarUrl(registerDTO.getAvatarUrl());
        user.setCollege(registerDTO.getCollege());
        user.setGrade(registerDTO.getGrade());
        user.setRole("student");
        user.setStatus(1);
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());
        save(user);
    }

    @Override
    public User getByUsername(String username) {
        return getOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
    }

    @Override
    public UserVO getUserVOById(Long id) {
        User user = getById(id);
        if (user == null) {
            return null;
        }
        UserVO userVO = new UserVO();
        BeanUtil.copyProperties(user, userVO);
        return userVO;
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        User user = getById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        update(new LambdaUpdateWrapper<User>()
                .eq(User::getId, id)
                .set(User::getStatus, status)
                .set(User::getUpdateTime, LocalDateTime.now()));
    }

    @Override
    @Transactional
    public void deleteUserCascade(Long id) {
        User user = getById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        // 1. 删除用户的所有资源（每个资源级联删除其评论、收藏、点赞）
        List<Resource> resources = resourceMapper.selectList(
                new LambdaQueryWrapper<Resource>().eq(Resource::getUploadUserId, id));
        for (Resource resource : resources) {
            // 级联删除评论、收藏、点赞
            commentMapper.delete(new LambdaQueryWrapper<Comment>().eq(Comment::getResourceId, resource.getId()));
            favoriteMapper.delete(new LambdaQueryWrapper<Favorite>().eq(Favorite::getResourceId, resource.getId()));
            resourceLikeMapper.delete(new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getResourceId, resource.getId()));
            resourceMapper.deleteById(resource.getId());
        }
        // 2. 删除用户发布的帖子及其评论、评论点赞、点赞、收藏
        List<Post> posts = postMapper.selectList(
                new LambdaQueryWrapper<Post>().eq(Post::getUserId, id));
        for (Post post : posts) {
            List<PostComment> postComments = postCommentMapper.selectList(
                    new LambdaQueryWrapper<PostComment>().eq(PostComment::getPostId, post.getId()));
            for (PostComment pc : postComments) {
                postCommentLikeMapper.delete(
                        new LambdaQueryWrapper<PostCommentLike>().eq(PostCommentLike::getCommentId, pc.getId()));
            }
            postCommentMapper.delete(new LambdaQueryWrapper<PostComment>().eq(PostComment::getPostId, post.getId()));
            postLikeMapper.delete(new LambdaQueryWrapper<PostLike>().eq(PostLike::getPostId, post.getId()));
            postFavoriteMapper.delete(new LambdaQueryWrapper<PostFavorite>().eq(PostFavorite::getPostId, post.getId()));
            postMapper.deleteById(post.getId());
        }
        // 3. 删除用户在他人内容下留下的评论、点赞、收藏
        List<PostComment> ownPostComments = postCommentMapper.selectList(
                new LambdaQueryWrapper<PostComment>().eq(PostComment::getUserId, id));
        for (PostComment pc : ownPostComments) {
            postCommentLikeMapper.delete(
                    new LambdaQueryWrapper<PostCommentLike>().eq(PostCommentLike::getCommentId, pc.getId()));
        }
        postCommentMapper.delete(new LambdaQueryWrapper<PostComment>().eq(PostComment::getUserId, id));
        postCommentLikeMapper.delete(new LambdaQueryWrapper<PostCommentLike>().eq(PostCommentLike::getUserId, id));
        postLikeMapper.delete(new LambdaQueryWrapper<PostLike>().eq(PostLike::getUserId, id));
        postFavoriteMapper.delete(new LambdaQueryWrapper<PostFavorite>().eq(PostFavorite::getUserId, id));
        // 4. 删除用户的所有评论、收藏
        commentMapper.delete(new LambdaQueryWrapper<Comment>().eq(Comment::getUserId, id));
        favoriteMapper.delete(new LambdaQueryWrapper<Favorite>().eq(Favorite::getUserId, id));
        // 5. 删除用户的所有关注关系
        followMapper.delete(new LambdaQueryWrapper<Follow>().eq(Follow::getFollowerId, id)
                .or().eq(Follow::getFollowedId, id));
        // 6. 删除用户的所有资源点赞
        resourceLikeMapper.delete(new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getUserId, id));
        // 7. 删除与用户相关的通知（收到的和触发的）
        notificationMapper.delete(new LambdaQueryWrapper<Notification>().eq(Notification::getUserId, id)
                .or().eq(Notification::getFromUserId, id));
        // 8. 删除用户
        removeById(id);
    }
}
