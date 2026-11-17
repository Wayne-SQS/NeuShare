package com.neushare.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.dto.AiConfigUpdateDTO;
import com.neushare.entity.UserAiApiConfig;
import com.neushare.vo.AiConfigPlainVO;
import com.neushare.vo.AiConfigStatusVO;

public interface AiConfigService extends IService<UserAiApiConfig> {

    /** 给前端设置页：掩码 + 有无标记，不回明文 */
    AiConfigStatusVO getStatus(Long userId);

    /** null=不改，""=清除，有值=加密保存 */
    void updateConfig(Long userId, AiConfigUpdateDTO dto);

    /** 给 neushare-ai 服务：解密后的明文，未配置为 "" */
    AiConfigPlainVO getPlainForAiService(Long userId);
}
