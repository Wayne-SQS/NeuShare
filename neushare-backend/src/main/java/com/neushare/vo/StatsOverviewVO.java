package com.neushare.vo;

import lombok.Data;

import java.util.List;

/**
 * 统计概览视图对象
 */
@Data
public class StatsOverviewVO {

    /** 资源总数 */
    private Long totalResources;
    /** 用户总数 */
    private Long totalUsers;
    /** 评论总数 */
    private Long totalComments;
    /** 收藏总数 */
    private Long totalFavorites;
    /** 点赞总数 */
    private Long totalLikes;
    /** 总浏览量 */
    private Long totalViews;
    /** 待审核资源数 */
    private Long pendingResources;

    /** 分类分布 */
    private List<DistributionItem> categoryDistribution;
    /** 类型分布 */
    private List<DistributionItem> typeDistribution;
    /** 来源网站分布 */
    private List<DistributionItem> sourceDistribution;
    /** 热门资源 Top10 */
    private List<TopResourceItem> topResources;
    /** 近7天新增资源数 */
    private Long recentUploads;

    @Data
    public static class DistributionItem {
        private String name;
        private Long count;
    }

    @Data
    public static class TopResourceItem {
        private Long id;
        private String title;
        private String type;
        private Integer viewCount;
        private Integer likeCount;
        private Integer favoriteCount;
    }
}
