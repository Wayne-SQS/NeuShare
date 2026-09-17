package com.neushare.dto;

import lombok.Data;

/**
 * 资源查询条件
 *
 * <p>把散落在 Controller 方法签名上的筛选参数收拢成一个对象，
 * 避免每加一个筛选维度就要改一遍 Service / Mapper 的签名。
 */
@Data
public class ResourceQuery {

    /** 页码，从 1 开始 */
    private Integer pageNum = 1;

    /** 每页条数 */
    private Integer pageSize = 10;

    /** 资源状态：0-待审核 1-已发布 2-已驳回 */
    private Integer status;

    /** 分类ID */
    private Long categoryId;

    /** 关键词（原始输入） */
    private String keyword;

    /**
     * 清洗后用于全文检索的关键词
     * <p>
     * 由 Service 层根据开关与词长计算：为空表示本次不走全文索引，降级为 LIKE。
     * 布尔模式下会剔除 MySQL 的特殊操作符，避免用户输入导致语法错误。
     */
    private String fulltextKeyword;

    /**
     * 排序方式：
     * <ul>
     *   <li>relevance - 按匹配相关度（有关键词时的默认行为）</li>
     *   <li>hot - 按浏览 + 点赞</li>
     *   <li>new - 按创建时间倒序（默认）</li>
     * </ul>
     */
    private String sortBy = "new";

    /** 课程名称（结构化筛选，精确匹配） */
    private String courseName;

    /** 授课教师（结构化筛选，精确匹配） */
    private String teacher;

    /** 学年，如 2024-2025（结构化筛选） */
    private String schoolYear;

    /** 学期：spring / summer / autumn / winter */
    private String term;

    /** 资源类型：document / video / image / other */
    private String type;

    /** 上传者ID */
    private Long uploadUserId;

    /**
     * 是否启用了结构化筛选（用于搜索日志里记录筛选摘要）
     */
    public boolean hasStructuredFilter() {
        return courseName != null || teacher != null || schoolYear != null
                || term != null || type != null || categoryId != null;
    }

    /**
     * 筛选条件摘要，写入搜索日志
     */
    public String filterSummary() {
        StringBuilder sb = new StringBuilder();
        append(sb, "category", categoryId);
        append(sb, "course", courseName);
        append(sb, "teacher", teacher);
        append(sb, "year", schoolYear);
        append(sb, "term", term);
        append(sb, "type", type);
        return sb.length() == 0 ? null : sb.toString();
    }

    private void append(StringBuilder sb, String key, Object value) {
        if (value == null) {
            return;
        }
        if (sb.length() > 0) {
            sb.append(",");
        }
        sb.append(key).append("=").append(value);
    }
}
