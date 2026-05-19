package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.dto.ResourceDTO;
import com.neushare.entity.Resource;
import com.neushare.vo.ResourceVO;

import java.util.List;

/**
 * 资源服务接口
 */
public interface ResourceService extends IService<Resource> {

    /**
     * 分页查询资源列表
     */
    IPage<ResourceVO> getResourcePage(Integer pageNum, Integer pageSize, Integer status, Long categoryId, String keyword);

    /**
     * 获取资源详情
     */
    ResourceVO getResourceDetail(Long id);

    /**
     * 创建资源
     */
    void createResource(ResourceDTO resourceDTO, Long userId);

    /**
     * 更新资源
     */
    void updateResource(ResourceDTO resourceDTO);

    /**
     * 删除资源
     */
    void deleteResource(Long id);

    /**
     * 获取热门资源
     */
    List<ResourceVO> getHotResources(Integer limit);

    /**
     * 增加浏览次数
     */
    void incrementViewCount(Long id);

    /**
     * 审核资源
     */
    void auditResource(Long id, Integer status);

    /**
     * 获取用户上传的资源
     */
    IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId);

    /**
     * 增加点赞数
     */
    void incrementLikeCount(Long id);

    /**
     * 减少点赞数
     */
    void decrementLikeCount(Long id);
}
