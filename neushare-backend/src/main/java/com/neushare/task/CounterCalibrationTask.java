package com.neushare.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.*;
import com.neushare.mapper.*;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 冗余计数器定期校准任务
 * 每天凌晨3点执行，校准 resource 表和 user 表的冗余计数字段
 * 使用分页查询避免全量加载，仅更新有变化的记录
 */
@Component
public class CounterCalibrationTask {

    @Autowired
    private ResourceMapper resourceMapper;

    @Autowired
    private ResourceLikeMapper resourceLikeMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private FollowMapper followMapper;

    @Autowired
    private CommentMapper commentMapper;

    @Autowired
    private CommentLikeMapper commentLikeMapper;

    @Autowired
    private PostCommentMapper postCommentMapper;

    @Autowired
    private PostCommentLikeMapper postCommentLikeMapper;

    private static final int BATCH_SIZE = 500;

    @Scheduled(cron = "0 0 3 * * ?")
    public void calibrateCounters() {
        calibrateResourceCounters();
        calibrateUserCounters();
        calibrateCommentLikeCounters();
    }

    private void calibrateResourceCounters() {
        int pageNum = 1;
        long total;
        do {
            Page<Resource> page = new Page<>(pageNum, BATCH_SIZE);
            Page<Resource> result = resourceMapper.selectPage(page,
                    new LambdaQueryWrapper<Resource>().select(Resource::getId, Resource::getLikeCount, Resource::getFavoriteCount));
            total = result.getTotal();
            for (Resource resource : result.getRecords()) {
                Long resourceId = resource.getId();
                boolean dirty = false;

                // 校准点赞数
                long likeCount = resourceLikeMapper.selectCount(
                        new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getResourceId, resourceId));
                if (!resource.getLikeCount().equals((int) likeCount)) {
                    resourceMapper.update(null, new LambdaUpdateWrapper<Resource>()
                            .eq(Resource::getId, resourceId)
                            .set(Resource::getLikeCount, (int) likeCount));
                    dirty = true;
                }

                // 校准收藏数
                long favoriteCount = favoriteMapper.selectCount(
                        new LambdaQueryWrapper<Favorite>().eq(Favorite::getResourceId, resourceId));
                if (!resource.getFavoriteCount().equals((int) favoriteCount)) {
                    resourceMapper.update(null, new LambdaUpdateWrapper<Resource>()
                            .eq(Resource::getId, resourceId)
                            .set(Resource::getFavoriteCount, (int) favoriteCount));
                    dirty = true;
                }
                // 注：view_count 是纯计数器，无法从关联表校准，仅校准 like/favorite
            }
            pageNum++;
        } while ((long) (pageNum - 1) * BATCH_SIZE < total);
    }

    private void calibrateUserCounters() {
        int pageNum = 1;
        long total;
        do {
            Page<User> page = new Page<>(pageNum, BATCH_SIZE);
            Page<User> result = userMapper.selectPage(page,
                    new LambdaQueryWrapper<User>().select(User::getId, User::getResourceCount,
                            User::getFollowerCount, User::getFollowingCount, User::getTotalLikesReceived));
            total = result.getTotal();
            for (User user : result.getRecords()) {
                Long userId = user.getId();
                boolean dirty = false;

                // 校准已发布资源数
                long resourceCount = resourceMapper.selectCount(
                        new LambdaQueryWrapper<Resource>()
                                .eq(Resource::getUploadUserId, userId)
                                .eq(Resource::getStatus, 1));
                if (user.getResourceCount() == null || resourceCount != user.getResourceCount().longValue()) {
                    dirty = true;
                }

                // 校准粉丝数
                long followerCount = followMapper.selectCount(
                        new LambdaQueryWrapper<Follow>().eq(Follow::getFollowedId, userId));
                if (user.getFollowerCount() == null || followerCount != user.getFollowerCount().longValue()) {
                    dirty = true;
                }

                // 校准关注数
                long followingCount = followMapper.selectCount(
                        new LambdaQueryWrapper<Follow>().eq(Follow::getFollowerId, userId));
                if (user.getFollowingCount() == null || followingCount != user.getFollowingCount().longValue()) {
                    dirty = true;
                }

                // 校准总获赞数（SQL SUM 聚合，避免 Java 循环）
                Long totalLikes = resourceMapper.selectTotalLikesReceived(userId);
                if (totalLikes == null) totalLikes = 0L;
                if (user.getTotalLikesReceived() == null || totalLikes.longValue() != user.getTotalLikesReceived().longValue()) {
                    dirty = true;
                }

                // 仅在有变化时更新
                if (dirty) {
                    userMapper.update(null, new LambdaUpdateWrapper<User>()
                            .eq(User::getId, userId)
                            .set(User::getResourceCount, resourceCount)
                            .set(User::getFollowerCount, followerCount)
                            .set(User::getFollowingCount, followingCount)
                            .set(User::getTotalLikesReceived, totalLikes));
                }
            }
            pageNum++;
        } while ((long) (pageNum - 1) * BATCH_SIZE < total);
    }

    private void calibrateCommentLikeCounters() {
        // 校准资源评论的 like_count
        int pageNum = 1;
        long total;
        do {
            Page<Comment> page = new Page<>(pageNum, BATCH_SIZE);
            Page<Comment> result = commentMapper.selectPage(page,
                    new LambdaQueryWrapper<Comment>().select(Comment::getId, Comment::getLikeCount));
            total = result.getTotal();
            for (Comment comment : result.getRecords()) {
                long likeCount = commentLikeMapper.selectCount(
                        new LambdaQueryWrapper<CommentLike>().eq(CommentLike::getCommentId, comment.getId()));
                if (!comment.getLikeCount().equals((int) likeCount)) {
                    commentMapper.update(null, new LambdaUpdateWrapper<Comment>()
                            .eq(Comment::getId, comment.getId())
                            .set(Comment::getLikeCount, (int) likeCount));
                }
            }
            pageNum++;
        } while ((long) (pageNum - 1) * BATCH_SIZE < total);

        // 校准帖子评论的 like_count
        pageNum = 1;
        do {
            Page<PostComment> page = new Page<>(pageNum, BATCH_SIZE);
            Page<PostComment> result = postCommentMapper.selectPage(page,
                    new LambdaQueryWrapper<PostComment>().select(PostComment::getId, PostComment::getLikeCount));
            total = result.getTotal();
            for (PostComment comment : result.getRecords()) {
                long likeCount = postCommentLikeMapper.selectCount(
                        new LambdaQueryWrapper<PostCommentLike>().eq(PostCommentLike::getCommentId, comment.getId()));
                if (!comment.getLikeCount().equals((int) likeCount)) {
                    postCommentMapper.update(null, new LambdaUpdateWrapper<PostComment>()
                            .eq(PostComment::getId, comment.getId())
                            .set(PostComment::getLikeCount, (int) likeCount));
                }
            }
            pageNum++;
        } while ((long) (pageNum - 1) * BATCH_SIZE < total);
    }
}
