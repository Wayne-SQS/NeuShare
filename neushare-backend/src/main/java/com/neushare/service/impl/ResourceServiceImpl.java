package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.ResourceDTO;
import com.neushare.entity.Resource;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.ResourceMapper;
import com.neushare.service.ResourceService;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 资源服务实现类
 */
@Service
public class ResourceServiceImpl extends ServiceImpl<ResourceMapper, Resource> implements ResourceService {

    @Autowired
    private ResourceMapper resourceMapper;

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
    public void updateResource(ResourceDTO resourceDTO) {
        Resource resource = getById(resourceDTO.getId());
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        BeanUtil.copyProperties(resourceDTO, resource);
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    public void deleteResource(Long id) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        removeById(id);
    }

    @Override
    public List<ResourceVO> getHotResources(Integer limit) {
        return resourceMapper.selectHotResources(limit);
    }

    @Override
    public void incrementViewCount(Long id) {
        Resource resource = getById(id);
        if (resource != null) {
            resource.setViewCount(resource.getViewCount() + 1);
            updateById(resource);
        }
    }

    @Override
    public void auditResource(Long id, Integer status) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        resource.setStatus(status);
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    public IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        return resourceMapper.selectUserResources(page, userId);
    }

    @Override
    public void incrementLikeCount(Long id) {
        Resource resource = getById(id);
        if (resource != null) {
            resource.setLikeCount(resource.getLikeCount() + 1);
            updateById(resource);
        }
    }

    @Override
    public void decrementLikeCount(Long id) {
        Resource resource = getById(id);
        if (resource != null && resource.getLikeCount() > 0) {
            resource.setLikeCount(resource.getLikeCount() - 1);
            updateById(resource);
        }
    }
}
