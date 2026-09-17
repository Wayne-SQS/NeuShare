package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.dto.ResourceDTO;
import com.neushare.dto.ResourceQuery;
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
    IPage<ResourceVO> getResourcePage(Integer pageNum, Integer pageSize, Integer status, Long categoryId, String keyword, String sortBy);

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

    /**
     * 获取用户收到的总点赞数
     */
    Long getTotalLikesReceived(Long userId);

    /**
     * 统一查询入口：关键词（全文检索 + 相关度排序）与结构化筛选（课程/教师/学年/学期/类型）
     *
     * @param query 查询条件，方法内部会做关键词清洗与全文降级判断
     */
    IPage<ResourceVO> search(ResourceQuery query);

    /**
     * 搜索联想：根据输入返回标题候选
     */
    List<String> suggest(String keyword, Integer limit);

    /**
     * 结构化筛选项：课程名列表
     */
    List<String> listCourseNames();

    /**
     * 结构化筛选项：教师名列表
     */
    List<String> listTeachers();
}
