package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.service.StatsService;
import com.neushare.vo.StatsOverviewVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 统计控制器（公开接口）
 */
@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
public class StatsController {

    private final StatsService statsService;

    /**
     * 获取平台统计概览（分类分布、类型分布、来源分布、热门排行、趋势数据）
     */
    @GetMapping("/overview")
    public Result<StatsOverviewVO> overview() {
        return Result.success(statsService.getOverview());
    }
}
