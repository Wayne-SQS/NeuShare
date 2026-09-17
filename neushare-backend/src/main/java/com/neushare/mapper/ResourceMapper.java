package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.dto.ResourceQuery;
import com.neushare.entity.Resource;
import com.neushare.vo.ResourceVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 资源Mapper接口
 */
@Mapper
public interface ResourceMapper extends BaseMapper<Resource> {

    /**
     * 分页查询资源列表（包含上传者信息）
     */
    IPage<ResourceVO> selectResourcePage(Page<ResourceVO> page, @Param("status") Integer status, @Param("categoryId") Long categoryId, @Param("keyword") String keyword, @Param("sortBy") String sortBy);

    /**
     * 根据ID查询资源详情（包含上传者信息）
     */
    ResourceVO selectResourceById(@Param("id") Long id);

    /**
     * 查询热门资源
     */
    List<ResourceVO> selectHotResources(@Param("limit") Integer limit);

    /**
     * 查询用户上传的资源列表
     */
    IPage<ResourceVO> selectUserResources(Page<ResourceVO> page, @Param("userId") Long userId);

    /**
     * 按状态查询用户上传的资源列表
     */
    IPage<ResourceVO> selectUserResourcesByStatus(Page<ResourceVO> page, @Param("userId") Long userId, @Param("status") Integer status);

    /**
     * 搜索资源（支持排序：hot/new）
     */
    IPage<ResourceVO> searchResources(Page<ResourceVO> page, @Param("keyword") String keyword, @Param("sortBy") String sortBy);

    /**
     * 统一查询入口：关键词（全文检索，相关度排序）+ 结构化筛选（课程/教师/学年/学期/类型）
     * <p>
     * 关键词命中走 ngram 全文索引并按相关度打分；单字关键词自动降级为 LIKE，
     * 全文索引不可用时由 neushare.search.fulltext-enabled 控制整体降级。
     */
    IPage<ResourceVO> selectByQuery(Page<ResourceVO> page, @Param("query") ResourceQuery query);

    /**
     * 查询用户已发布资源的总获赞数（SQL SUM 聚合，避免 Java 循环）
     */
    Long selectTotalLikesReceived(@Param("userId") Long userId);

    /**
     * 搜索联想：标题候选
     */
    List<String> suggestTitles(@Param("keyword") String keyword, @Param("limit") Integer limit);

    /**
     * 结构化筛选项：已发布资源中出现过的课程名（去重）
     */
    List<String> selectCourseNames();

    /**
     * 结构化筛选项：已发布资源中出现过的教师名（去重）
     */
    List<String> selectTeachers();
}
