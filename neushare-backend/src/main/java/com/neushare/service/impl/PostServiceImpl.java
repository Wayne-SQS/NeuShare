package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Post;
import com.neushare.entity.PostComment;
import com.neushare.entity.PostFavorite;
import com.neushare.entity.PostLike;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.PostCommentMapper;
import com.neushare.mapper.PostFavoriteMapper;
import com.neushare.mapper.PostLikeMapper;
import com.neushare.mapper.PostMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.NotificationService;
import com.neushare.service.PostService;
import com.neushare.vo.PostVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 帖子服务实现类
 */
@Service
public class PostServiceImpl extends ServiceImpl<PostMapper, Post> implements PostService {

    @Autowired
    private PostMapper postMapper;

    @Autowired
    private PostLikeMapper postLikeMapper;

    @Autowired
    private PostFavoriteMapper postFavoriteMapper;

    @Autowired
    private PostCommentMapper postCommentMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @Override
    public IPage<PostVO> getPostPage(Integer pageNum, Integer pageSize, Integer status, String tag, String keyword, String sortBy) {
        Page<PostVO> page = new Page<>(pageNum, pageSize);
        return postMapper.selectPostPage(page, status, tag, keyword, sortBy);
    }

    @Override
    public PostVO getPostDetail(Long id) {
        PostVO postVO = postMapper.selectPostById(id);
        if (postVO == null) {
            throw new BusinessException("帖子不存在");
        }
        return postVO;
    }

    @Override
    public void createPost(Post post, Long userId) {
        post.setUserId(userId);
        post.setStatus(1);
        post.setViewCount(0);
        post.setLikeCount(0);
        post.setFavoriteCount(0);
        post.setCommentCount(0);
        post.setIsRecommended(0);
        post.setCreateTime(LocalDateTime.now());
        post.setUpdateTime(LocalDateTime.now());
        save(post);
    }

    @Override
    public void updatePost(Post post, Long userId, String role) {
        Post existing = getById(post.getId());
        if (existing == null) {
            throw new BusinessException("帖子不存在");
        }
        if (!existing.getUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权修改此帖子");
        }
        post.setUpdateTime(LocalDateTime.now());
        updateById(post);
    }

    @Override
    @Transactional
    public void deletePost(Long id, Long userId, String role) {
        Post post = getById(id);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        if (!post.getUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权删除此帖子");
        }
        // 级联删除：帖子点赞、帖子收藏、帖子评论
        postLikeMapper.delete(new LambdaQueryWrapper<PostLike>().eq(PostLike::getPostId, id));
        postFavoriteMapper.delete(new LambdaQueryWrapper<PostFavorite>().eq(PostFavorite::getPostId, id));
        postCommentMapper.delete(new LambdaQueryWrapper<PostComment>().eq(PostComment::getPostId, id));
        removeById(id);
    }

    @Override
    public List<PostVO> getHotPosts(Integer limit) {
        return postMapper.selectHotPosts(limit);
    }

    @Override
    public void incrementViewCount(Long id) {
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, id)
                .setSql("view_count = view_count + 1"));
    }

    @Override
    @Transactional
    public void likePost(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        PostLike exist = postLikeMapper.selectByUserIdAndPostId(userId, postId);
        if (exist != null) {
            throw new BusinessException("已点赞该帖子");
        }
        PostLike like = new PostLike();
        like.setUserId(userId);
        like.setPostId(postId);
        like.setCreateTime(LocalDateTime.now());
        postLikeMapper.insert(like);
        // 原子更新点赞数
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, postId)
                .setSql("like_count = like_count + 1"));
        // 通知帖子作者
        if (!post.getUserId().equals(userId)) {
            User user = userMapper.selectById(userId);
            String userName = user != null ? user.getNickname() : "有人";
            notificationService.send(post.getUserId(), "like", postId, userId,
                    "有人点赞了你的帖子", userName + " 点赞了你的帖子「" + post.getTitle() + "」。");
        }
    }

    @Override
    @Transactional
    public void unlikePost(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        PostLike exist = postLikeMapper.selectByUserIdAndPostId(userId, postId);
        if (exist == null) {
            throw new BusinessException("未点赞该帖子");
        }
        postLikeMapper.deleteById(exist.getId());
        // 原子更新点赞数
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, postId)
                .gt(Post::getLikeCount, 0)
                .setSql("like_count = like_count - 1"));
    }

    @Override
    public boolean isLiked(Long postId, Long userId) {
        return postLikeMapper.selectByUserIdAndPostId(userId, postId) != null;
    }

    @Override
    @Transactional
    public void favoritePost(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        PostFavorite exist = postFavoriteMapper.selectByUserIdAndPostId(userId, postId);
        if (exist != null) {
            throw new BusinessException("已收藏该帖子");
        }
        PostFavorite favorite = new PostFavorite();
        favorite.setUserId(userId);
        favorite.setPostId(postId);
        favorite.setCreateTime(LocalDateTime.now());
        postFavoriteMapper.insert(favorite);
        // 原子更新收藏数
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, postId)
                .setSql("favorite_count = favorite_count + 1"));
        // 通知帖子作者
        if (!post.getUserId().equals(userId)) {
            User user = userMapper.selectById(userId);
            String userName = user != null ? user.getNickname() : "有人";
            notificationService.send(post.getUserId(), "favorite", postId, userId,
                    "有人收藏了你的帖子", userName + " 收藏了你的帖子「" + post.getTitle() + "」。");
        }
    }

    @Override
    @Transactional
    public void unfavoritePost(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        PostFavorite exist = postFavoriteMapper.selectByUserIdAndPostId(userId, postId);
        if (exist == null) {
            throw new BusinessException("未收藏该帖子");
        }
        postFavoriteMapper.deleteById(exist.getId());
        // 原子更新收藏数
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getId, postId)
                .gt(Post::getFavoriteCount, 0)
                .setSql("favorite_count = favorite_count - 1"));
    }

    @Override
    public boolean isFavorited(Long postId, Long userId) {
        return postFavoriteMapper.selectByUserIdAndPostId(userId, postId) != null;
    }

    @Override
    public IPage<PostVO> getUserPosts(Integer pageNum, Integer pageSize, Long userId) {
        Page<PostVO> page = new Page<>(pageNum, pageSize);
        return postMapper.selectUserPosts(page, userId);
    }

    @Override
    public void recommendPost(Long id, Long userId, String role) {
        if (!"admin".equals(role)) {
            throw new BusinessException("仅管理员可推荐帖子");
        }
        Post post = getById(id);
        if (post == null) {
            throw new BusinessException("帖子不存在");
        }
        // 先取消其他推荐
        update(new LambdaUpdateWrapper<Post>()
                .eq(Post::getIsRecommended, 1)
                .set(Post::getIsRecommended, 0));
        // 设置当前帖子为推荐
        post.setIsRecommended(1);
        post.setUpdateTime(LocalDateTime.now());
        updateById(post);
    }
}
