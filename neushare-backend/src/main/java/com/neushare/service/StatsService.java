package com.neushare.service;

import com.neushare.vo.StatsOverviewVO;

/**
 * 统计服务接口
 */
public interface StatsService {
    /**
     * 获取统计概览数据（公开接口）
     */
    StatsOverviewVO getOverview();
}
