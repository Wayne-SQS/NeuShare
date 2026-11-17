package com.neushare.vo;

import lombok.Data;

/**
 * AI 配置状态（给前端设置页看）
 * 只给掩码和有无标记，绝不回传明文 key。
 */
@Data
public class AiConfigStatusVO {

    private Boolean hasDeepseekKey;

    /** 掩码形式，如 sk-1****9f3a；未配置为 "" */
    private String deepseekKeyMasked;

    private Boolean hasTavilyKey;

    private String tavilyKeyMasked;
}
