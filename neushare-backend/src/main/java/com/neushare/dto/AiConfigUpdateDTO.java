package com.neushare.dto;

import lombok.Data;

/**
 * 用户 AI API 配置更新入参
 * 约定：null = 不改动该字段；"" = 清除该 key；有值 = 保存（前后去空格）
 */
@Data
public class AiConfigUpdateDTO {

    private String deepseekKey;

    private String tavilyKey;
}
