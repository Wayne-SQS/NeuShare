package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.ResourceDTO;
import com.neushare.dto.ResourceQuery;
import com.neushare.entity.Comment;
import com.neushare.entity.Favorite;
import com.neushare.entity.Resource;
import com.neushare.entity.ResourceLike;
import com.neushare.entity.SearchLog;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.CommentMapper;
import com.neushare.mapper.FavoriteMapper;
import com.neushare.mapper.ResourceLikeMapper;
import com.neushare.mapper.ResourceMapper;
import com.neushare.mapper.SearchLogMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.NotificationService;
import com.neushare.service.ResourceService;
import com.neushare.vo.ResourceVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 资源服务实现类
 */
@Slf4j
@Service
public class ResourceServiceImpl extends ServiceImpl<ResourceMapper, Resource> implements ResourceService {

    @Autowired
    private ResourceMapper resourceMapper;

    @Autowired
    private ResourceLikeMapper resourceLikeMapper;

    @Autowired
    private CommentMapper commentMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private SearchLogMapper searchLogMapper;

    /** 是否启用全文检索（未建 ngram 索引时可关闭，自动降级为 LIKE） */
    @Value("${neushare.search.fulltext-enabled:true}")
    private boolean fulltextEnabled;

    /** 走全文检索的最小关键词长度，ngram 按 2 字切分，单字没有意义 */
    @Value("${neushare.search.fulltext-min-length:2}")
    private int fulltextMinLength;

    @Override
    public IPage<ResourceVO> getResourcePage(Integer pageNum, Integer pageSize, Integer status, Long categoryId, String keyword, String sortBy) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.selectResourcePage(page, status, categoryId, keyword, sortBy);
    }

    @Override
    public ResourceVO getResourceDetail(Long id) {
        ResourceVO resourceVO = resourceMapper.selectResourceById(id);
        if (resourceVO == null) {
            throw new BusinessException("资源不存在");
        }
        return resourceVO;
    }

    @Override
    public void createResource(ResourceDTO resourceDTO, Long userId) {
        Resource resource = new Resource();
        BeanUtil.copyProperties(resourceDTO, resource);
        resource.setUploadUserId(userId);
        resource.setStatus(0);
        resource.setViewCount(0);
        resource.setLikeCount(0);
        resource.setFavoriteCount(0);
        if (resource.getType() == null || resource.getType().isBlank()) {
            resource.setType("document");
        }
        if (resource.getContentUrl() == null) {
            resource.setContentUrl("");
        }
        resource.setCreateTime(LocalDateTime.now());
        resource.setUpdateTime(LocalDateTime.now());
        save(resource);
        // 实时更新用户资源计数（待审核也算，校准任务只算已发布）
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, userId)
                .setSql("resource_count = resource_count + 1"));
    }

    @Override
    public void updateResource(ResourceDTO resourceDTO, Long userId, String role) {
        Resource resource = getById(resourceDTO.getId());
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 校验所有者或管理员
        if (!resource.getUploadUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权修改此资源");
        }
        BeanUtil.copyProperties(resourceDTO, resource);
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    @Transactional
    public void deleteResource(Long id, Long userId, String role) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 校验所有者或管理员
        if (!resource.getUploadUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权删除此资源");
        }
        // 级联删除：评论、收藏、点赞
        commentMapper.delete(new LambdaQueryWrapper<Comment>().eq(Comment::getResourceId, id));
        favoriteMapper.delete(new LambdaQueryWrapper<Favorite>().eq(Favorite::getResourceId, id));
        resourceLikeMapper.delete(new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getResourceId, id));
        removeById(id);
        // 实时更新用户资源计数
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .gt(User::getResourceCount, 0)
                .setSql("resource_count = resource_count - 1"));
    }

    @Override
    public List<ResourceVO> getHotResources(Integer limit) {
        return resourceMapper.selectHotResources(limit);
    }

    @Override
    public void incrementViewCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .setSql("view_count = view_count + 1"));
    }

    @Override
    public void auditResource(Long id, Integer status, String rejectReason) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        resource.setStatus(status);
        if (status == 2 && rejectReason != null && !rejectReason.isEmpty()) {
            resource.setRejectReason(rejectReason);
        }
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    public IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.selectUserResources(page, userId);
    }

    @Override
    public IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId, Integer status) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.selectUserResourcesByStatus(page, userId, status);
    }

    @Override
    public void incrementLikeCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .setSql("like_count = like_count + 1"));
    }

    @Override
    public void decrementLikeCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .gt(Resource::getLikeCount, 0)
                .setSql("like_count = like_count - 1"));
    }

    @Override
    @Transactional
    public void likeResource(Long resourceId, Long userId) {
        Resource resource = getById(resourceId);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 检查是否已点赞
        ResourceLike exist = resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (exist != null) {
            throw new BusinessException("已点赞该资源");
        }
        // 添加点赞记录
        ResourceLike like = new ResourceLike();
        like.setUserId(userId);
        like.setResourceId(resourceId);
        like.setCreateTime(LocalDateTime.now());
        resourceLikeMapper.insert(like);
        // 原子更新点赞数
        incrementLikeCount(resourceId);
        // 实时更新资源作者的 totalLikesReceived
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .setSql("total_likes_received = total_likes_received + 1"));
        // 通知资源上传者（如果点赞者不是上传者本人）
        if (!resource.getUploadUserId().equals(userId)) {
            User user = userMapper.selectById(userId);
            String userName = user != null ? user.getNickname() : "有人";
            notificationService.send(resource.getUploadUserId(), "like", resourceId, userId,
                    "有人点赞了你的资源", userName + " 点赞了你的资源「" + resource.getTitle() + "」。");
        }
    }

    @Override
    @Transactional
    public void unlikeResource(Long resourceId, Long userId) {
        Resource resource = getById(resourceId);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        ResourceLike exist = resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (exist == null) {
            throw new BusinessException("未点赞该资源");
        }
        resourceLikeMapper.deleteById(exist.getId());
        decrementLikeCount(resourceId);
        // 实时更新资源作者的 totalLikesReceived
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .gt(User::getTotalLikesReceived, 0)
                .setSql("total_likes_received = total_likes_received - 1"));
    }

    @Override
    public boolean isLiked(Long resourceId, Long userId) {
        return resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId) != null;
    }

    @Override
    public IPage<ResourceVO> searchResources(Integer pageNum, Integer pageSize, String keyword, String sortBy) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.searchResources(page, keyword, sortBy);
    }

    @Override
    public Long getTotalLikesReceived(Long userId) {
        Long total = resourceMapper.selectTotalLikesReceived(userId);
        return total != null ? total : 0L;
    }

    @Override
    public IPage<ResourceVO> search(ResourceQuery query) {
        // 参数兜底，避免前端漏传导致分页插件抛错
        if (query.getPageNum() == null || query.getPageNum() < 1) {
            query.setPageNum(1);
        }
        if (query.getPageSize() == null || query.getPageSize() < 1) {
            query.setPageSize(10);
        }
        if (query.getPageSize() > 100) {
            query.setPageSize(100);
        }

        // 关键词清洗：布尔模式下 MySQL 的 + - ~ * 等字符是操作符，必须由用户输入里剔除
        String raw = query.getKeyword();
        if (raw != null && !raw.isBlank()) {
            String cleaned = cleanKeyword(raw);
            // 全文索引按 2 字切分，单字走全文没意义，降级为 LIKE
            if (fulltextEnabled && cleaned.length() >= fulltextMinLength) {
                query.setFulltextKeyword(cleaned);
            }
            // 用户没指定排序时，有关键词默认按相关度排
            if (query.getSortBy() == null || query.getSortBy().isBlank()
                    || (!"hot".equals(query.getSortBy()) && !"new".equals(query.getSortBy()))) {
                query.setSortBy("relevance");
            }
        }

        Page<ResourceVO> page = new Page<>(query.getPageNum(), query.getPageSize());
        IPage<ResourceVO> result = resourceMapper.selectByQuery(page, query);

        // 搜索行为落库：失败不影响搜索结果返回
        if (raw != null && !raw.isBlank()) {
            recordSearchLog(query, result.getTotal());
        }
        return result;
    }

    @Override
    public List<String> suggest(String keyword, Integer limit) {
        if (keyword == null || keyword.isBlank()) {
            return List.of();
        }
        int size = (limit == null || limit < 1) ? 10 : Math.min(limit, 20);
        return resourceMapper.suggestTitles(cleanKeyword(keyword), size);
    }

    @Override
    public List<String> listCourseNames() {
        return resourceMapper.selectCourseNames();
    }

    @Override
    public List<String> listTeachers() {
        return resourceMapper.selectTeachers();
    }

    /**
     * 关键词清洗：只保留中英文、数字与空格，多空格合并
     * <p>
     * 目的有两个：一是剔除 MySQL 布尔模式的操作符避免语法错误，
     * 二是过滤掉纯符号输入导致无意义的全表扫描。
     */
    private String cleanKeyword(String keyword) {
        if (keyword == null) {
            return "";
        }
        return keyword.replaceAll("[^\\u4e00-\\u9fa5a-zA-Z0-9 ]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private void recordSearchLog(ResourceQuery query, long total) {
        try {
            SearchLog log = new SearchLog();
            log.setUserId(null);
            log.setKeyword(query.getKeyword());
            log.setResultCount((int) total);
            log.setFilters(query.filterSummary());
            log.setSearchTime(LocalDateTime.now());
            searchLogMapper.insert(log);
        } catch (Exception e) {
            // 日志落库失败不能影响搜索主流程
            log.warn("搜索日志写入失败，keyword={}, reason={}", query.getKeyword(), e.getMessage());
        }
    }
}
