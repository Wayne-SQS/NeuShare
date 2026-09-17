package com.neushare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 搜索日志
 *
 * <p>记录用户搜了什么、命中多少。核心用途是发现「零结果」的高频词 —— 那正是平台缺的内容，
 * 直接指导运营补什么资料，比拍脑袋决定优先级靠谱。
 */
@Data
@TableName("search_log")
public class SearchLog implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 用户ID，未登录搜索为空 */
    @TableField("user_id")
    private Long userId;

    /** 搜索关键词 */
    @TableField("keyword")
    private String keyword;

    /** 命中结果数 */
    @TableField("result_count")
    private Integer resultCount;

    /** 结构化筛选条件摘要 */
    @TableField("filters")
    private String filters;

    /** 搜索时间 */
    @TableField("search_time")
    private LocalDateTime searchTime;
}
