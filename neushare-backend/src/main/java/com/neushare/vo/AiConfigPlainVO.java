package com.neushare.vo;

import lombok.Data;

/**
 * AI 配置明文（仅给 neushare-ai 服务用）
 * 前提：调用方持用户有效 JWT（JwtInterceptor 已校验），
 * 返回的是用户自己填的 key，用户拿回自己的 key 不算泄露。
 */
@Data
public class AiConfigPlainVO {

    private Long userId;

    /** 未配置返回 ""，AI 侧据此降级到平台 key */
    private String deepseekKey;

    private String tavilyKey;
}
