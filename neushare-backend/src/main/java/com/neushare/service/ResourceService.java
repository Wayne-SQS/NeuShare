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
    void updateResource(ResourceDTO resourceDTO, Long userId, String role);

    /**
     * 删除资源
     */
    void deleteResource(Long id, Long userId, String role);

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
    void auditResource(Long id, Integer status, String rejectReason);

    /**
     * 获取用户上传的资源
     */
    IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId);

    /**
     * 按状态获取用户上传的资源
     */
    IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId, Integer status);

    /**
     * 增加点赞数
     */
    void incrementLikeCount(Long id);

    /**
     * 减少点赞数
     */
    void decrementLikeCount(Long id);

    /**
     * 点赞（记录用户+防刷）
     */
    void likeResource(Long resourceId, Long userId);

    /**
     * 取消点赞
     */
    void unlikeResource(Long resourceId, Long userId);

    /**
     * 检查用户是否已点赞
     */
    boolean isLiked(Long resourceId, Long userId);

    /**
     * 搜索资源（支持排序）
     */
    IPage<ResourceVO> searchResources(Integer pageNum, Integer pageSize, String keyword, String sortBy);
}
