package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
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
    IPage<ResourceVO> selectResourcePage(Page<ResourceVO> page, @Param("status") Integer status, @Param("categoryId") Long categoryId, @Param("keyword") String keyword);

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
}
