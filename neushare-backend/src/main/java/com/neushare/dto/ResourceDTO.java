package com.neushare.dto;

import lombok.Data;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 资源请求DTO
 */
@Data
public class ResourceDTO {

    /**
     * 资源ID（更新时使用）
     */
    private Long id;

    /**
     * 资源标题
     */
    @NotBlank(message = "标题不能为空")
    private String title;

    /**
     * 分类ID
     */
    @NotNull(message = "分类不能为空")
    private Long categoryId;

    /**
     * 资源类型
     */
    private String type;

    /**
     * 资源内容URL
     */
    private String contentUrl;

    /**
     * 资源描述
     */
    private String description;

    /**
     * 封面图URL
     */
    private String coverUrl;

    /**
     * 来源网站
     */
    private String source;
}
