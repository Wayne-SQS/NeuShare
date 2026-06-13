package com.neushare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 服务卡片推荐实体
 */
@Data
@TableName("form_card")
public class FormCard implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 卡片展示标题 */
    @TableField("title")
    private String title;

    /** 资源类型: video/book/software/tutorial */
    @TableField("resource_type")
    private String resourceType;

    /** 关联资源ID */
    @TableField("resource_id")
    private Long resourceId;

    /** 资源内容URL */
    @TableField("content_url")
    private String contentUrl;

    /** 排序(越小越靠前) */
    @TableField("sort_order")
    private Integer sortOrder;

    /** 状态: 0-禁用 1-启用 */
    @TableField("status")
    private Integer status;

    /** 创建时间 */
    @TableField("create_time")
    private LocalDateTime createTime;

    /** 更新时间 */
    @TableField("update_time")
    private LocalDateTime updateTime;
}
