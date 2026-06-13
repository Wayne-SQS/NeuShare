package com.neushare.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neushare.entity.*;
import com.neushare.mapper.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 冗余计数器定期校准任务
 * 每天凌晨3点执行，校准 resource 表的 view_count / like_count / favorite_count
 */
@Component
public class CounterCalibrationTask {

    @Autowired
    private ResourceMapper resourceMapper;

    @Autowired
    private ResourceLikeMapper resourceLikeMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Scheduled(cron = "0 0 3 * * ?")
    public void calibrateCounters() {
        List<Resource> resources = resourceMapper.selectList(null);
        for (Resource resource : resources) {
            Long resourceId = resource.getId();

            // 校准点赞数
            long likeCount = resourceLikeMapper.selectCount(
                    new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getResourceId, resourceId));
            if (!resource.getLikeCount().equals((int) likeCount)) {
                resource.setLikeCount((int) likeCount);
            }

            // 校准收藏数
            long favoriteCount = favoriteMapper.selectCount(
                    new LambdaQueryWrapper<Favorite>().eq(Favorite::getResourceId, resourceId));
            if (!resource.getFavoriteCount().equals((int) favoriteCount)) {
                resource.setFavoriteCount((int) favoriteCount);
            }

            // 注：view_count 是纯计数器，无法从关联表校准，仅校准 like/favorite
            resourceMapper.updateById(resource);
        }
    }
}
