package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neushare.dto.ResourceDTO;
import com.neushare.entity.Comment;
import com.neushare.entity.Favorite;
import com.neushare.entity.Resource;
import com.neushare.entity.ResourceLike;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.CommentMapper;
import com.neushare.mapper.FavoriteMapper;
import com.neushare.mapper.ResourceLikeMapper;
import com.neushare.mapper.ResourceMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.NotificationService;
import com.neushare.service.ResourceService;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 资源服务实现类
 */
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

    @Override
    public IPage<ResourceVO> getResourcePage(Integer pageNum, Integer pageSize, Integer status, Long categoryId, String keyword) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.selectResourcePage(page, status, categoryId, keyword);
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
        if (resource.getType() == null) {
            resource.setType("document");
        }
        if (resource.getContentUrl() == null) {
            resource.setContentUrl("");
        }
        resource.setCreateTime(LocalDateTime.now());
        resource.setUpdateTime(LocalDateTime.now());
        save(resource);
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
}
