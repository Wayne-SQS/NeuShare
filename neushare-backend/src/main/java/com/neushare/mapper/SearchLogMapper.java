package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.SearchLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 搜索日志Mapper
 */
@Mapper
public interface SearchLogMapper extends BaseMapper<SearchLog> {
}
