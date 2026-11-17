package com.neushare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户自带 AI API Key（BYOK）
 * 只存密文：明文 key 永远不落库、不进日志。
 */
@Data
@TableName("ai_user_api_config")
public class UserAiApiConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID（user.id），唯一
     */
    @TableField("user_id")
    private Long userId;

    /**
     * DeepSeek API key 密文（AES-256-GCM，Base64；null=未配置）
     */
    @TableField("deepseek_key_enc")
    private String deepseekKeyEnc;

    /**
     * Tavily API key 密文（AES-256-GCM，Base64；null=未配置）
     */
    @TableField("tavily_key_enc")
    private String tavilyKeyEnc;

    @TableField("create_time")
    private LocalDateTime createTime;

    @TableField("update_time")
    private LocalDateTime updateTime;
}
