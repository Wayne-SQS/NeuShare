package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neushare.entity.Category;
import com.neushare.entity.Comment;
import com.neushare.entity.Favorite;
import com.neushare.entity.Resource;
import com.neushare.entity.User;
import com.neushare.mapper.CategoryMapper;
import com.neushare.mapper.CommentMapper;
import com.neushare.mapper.FavoriteMapper;
import com.neushare.mapper.ResourceLikeMapper;
import com.neushare.mapper.ResourceMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.StatsService;
import com.neushare.vo.StatsOverviewVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 统计服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StatsServiceImpl implements StatsService {

    private final ResourceMapper resourceMapper;
    private final UserMapper userMapper;
    private final CommentMapper commentMapper;
    private final FavoriteMapper favoriteMapper;
    private final ResourceLikeMapper resourceLikeMapper;
    private final CategoryMapper categoryMapper;

    @Override
    public StatsOverviewVO getOverview() {
        try {
            return doGetOverview();
        } catch (Exception e) {
            log.error("StatsService error", e);
            throw e;
        }
    }

    private StatsOverviewVO doGetOverview() {
        StatsOverviewVO vo = new StatsOverviewVO();

        // 基础计数（仅已发布资源）
        log.info("Stats: querying published resources...");
        LambdaQueryWrapper<Resource> publishedWrapper = new LambdaQueryWrapper<Resource>()
                .eq(Resource::getStatus, 1);
        List<Resource> publishedResources = resourceMapper.selectList(publishedWrapper);
        long publishedCount = publishedResources.size();
        log.info("Stats: published count = {}", publishedCount);

        // 待审核
        long pendingCount = resourceMapper.selectCount(
                new LambdaQueryWrapper<Resource>().eq(Resource::getStatus, 0));

        long userCount = userMapper.selectCount(null);
        long commentCount = commentMapper.selectCount(
                new LambdaQueryWrapper<Comment>().eq(Comment::getDeleted, 0));
        long favoriteCount = favoriteMapper.selectCount(null);
        long likeCount = resourceLikeMapper.selectCount(null);

        // 总浏览量/点赞/收藏（从 resource 表汇总）
        long totalViews = publishedResources.stream().mapToLong(r -> r.getViewCount() == null ? 0 : r.getViewCount()).sum();
        long totalLikes = publishedResources.stream().mapToLong(r -> r.getLikeCount() == null ? 0 : r.getLikeCount()).sum();
        long totalFavorites = publishedResources.stream().mapToLong(r -> r.getFavoriteCount() == null ? 0 : r.getFavoriteCount()).sum();

        vo.setTotalResources(publishedCount);
        vo.setTotalUsers(userCount);
        vo.setTotalComments(commentCount);
        // 使用 resource 表汇总值（已由定时任务校准，无需加 audit 表）
        vo.setTotalFavorites(totalFavorites);
        vo.setTotalLikes(totalLikes);
        vo.setTotalViews(totalViews);
        vo.setPendingResources(pendingCount);

        // 分类分布
        Map<Long, Long> categoryCountMap = publishedResources.stream()
                .filter(r -> r.getCategoryId() != null)
                .collect(Collectors.groupingBy(Resource::getCategoryId, Collectors.counting()));
        List<Category> categories = categoryMapper.selectList(null);
        Map<Long, String> categoryNameMap = categories.stream()
                .collect(Collectors.toMap(Category::getId, Category::getName));
        vo.setCategoryDistribution(categoryCountMap.entrySet().stream()
                .map(e -> {
                    StatsOverviewVO.DistributionItem item = new StatsOverviewVO.DistributionItem();
                    item.setName(categoryNameMap.getOrDefault(e.getKey(), "未知分类"));
                    item.setCount(e.getValue());
                    return item;
                })
                .sorted((a, b) -> Long.compare(b.getCount(), a.getCount()))
                .collect(Collectors.toList()));

        // 类型分布
        Map<String, Long> typeCountMap = publishedResources.stream()
                .filter(r -> r.getType() != null)
                .collect(Collectors.groupingBy(Resource::getType, Collectors.counting()));
        vo.setTypeDistribution(typeCountMap.entrySet().stream()
                .map(e -> {
                    StatsOverviewVO.DistributionItem item = new StatsOverviewVO.DistributionItem();
                    item.setName(e.getKey());
                    item.setCount(e.getValue());
                    return item;
                })
                .sorted((a, b) -> Long.compare(b.getCount(), a.getCount()))
                .collect(Collectors.toList()));

        // 来源网站分布
        Map<String, Long> sourceCountMap = publishedResources.stream()
                .filter(r -> r.getSource() != null && !r.getSource().isEmpty())
                .collect(Collectors.groupingBy(Resource::getSource, Collectors.counting()));
        vo.setSourceDistribution(sourceCountMap.entrySet().stream()
                .map(e -> {
                    StatsOverviewVO.DistributionItem item = new StatsOverviewVO.DistributionItem();
                    item.setName(e.getKey());
                    item.setCount(e.getValue());
                    return item;
                })
                .sorted((a, b) -> Long.compare(b.getCount(), a.getCount()))
                .collect(Collectors.toList()));

        // 热门资源 Top10
        vo.setTopResources(publishedResources.stream()
                .sorted((a, b) -> {
                    long hotA = (long)(a.getViewCount() == null ? 0 : a.getViewCount())
                            + (long)(a.getLikeCount() == null ? 0 : a.getLikeCount()) * 2
                            + (long)(a.getFavoriteCount() == null ? 0 : a.getFavoriteCount()) * 3;
                    long hotB = (long)(b.getViewCount() == null ? 0 : b.getViewCount())
                            + (long)(b.getLikeCount() == null ? 0 : b.getLikeCount()) * 2
                            + (long)(b.getFavoriteCount() == null ? 0 : b.getFavoriteCount()) * 3;
                    return Long.compare(hotB, hotA);
                })
                .limit(10)
                .map(r -> {
                    StatsOverviewVO.TopResourceItem item = new StatsOverviewVO.TopResourceItem();
                    item.setId(r.getId());
                    item.setTitle(r.getTitle());
                    item.setType(r.getType());
                    item.setViewCount(r.getViewCount());
                    item.setLikeCount(r.getLikeCount());
                    item.setFavoriteCount(r.getFavoriteCount());
                    return item;
                })
                .collect(Collectors.toList()));

        // 近7天新增
        LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);
        vo.setRecentUploads(publishedResources.stream()
                .filter(r -> r.getCreateTime() != null && r.getCreateTime().isAfter(sevenDaysAgo))
                .count());

        return vo;
    }
}
