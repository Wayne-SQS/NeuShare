package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.AiConfigUpdateDTO;
import com.neushare.entity.UserAiApiConfig;
import com.neushare.mapper.UserAiApiConfigMapper;
import com.neushare.service.AiConfigService;
import com.neushare.util.AesGcmUtil;
import com.neushare.vo.AiConfigPlainVO;
import com.neushare.vo.AiConfigStatusVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AiConfigServiceImpl extends ServiceImpl<UserAiApiConfigMapper, UserAiApiConfig>
        implements AiConfigService {

    @Autowired
    private AesGcmUtil aesGcmUtil;

    @Override
    public AiConfigStatusVO getStatus(Long userId) {
        UserAiApiConfig config = getByUserId(userId);
        AiConfigStatusVO vo = new AiConfigStatusVO();
        String ds = config == null ? null : config.getDeepseekKeyEnc();
        String tv = config == null ? null : config.getTavilyKeyEnc();
        vo.setHasDeepseekKey(ds != null && !ds.isEmpty());
        vo.setDeepseekKeyMasked(ds == null || ds.isEmpty() ? "" : mask(aesGcmUtil.decrypt(ds)));
        vo.setHasTavilyKey(tv != null && !tv.isEmpty());
        vo.setTavilyKeyMasked(tv == null || tv.isEmpty() ? "" : mask(aesGcmUtil.decrypt(tv)));
        return vo;
    }

    @Override
    public void updateConfig(Long userId, AiConfigUpdateDTO dto) {
        UserAiApiConfig config = getByUserId(userId);
        if (config == null) {
            config = new UserAiApiConfig();
            config.setUserId(userId);
        }
        if (dto.getDeepseekKey() != null) {
            String trimmed = dto.getDeepseekKey().trim();
            config.setDeepseekKeyEnc(trimmed.isEmpty() ? null : aesGcmUtil.encrypt(trimmed));
        }
        if (dto.getTavilyKey() != null) {
            String trimmed = dto.getTavilyKey().trim();
            config.setTavilyKeyEnc(trimmed.isEmpty() ? null : aesGcmUtil.encrypt(trimmed));
        }
        if (config.getId() == null) {
            save(config);
            return;
        }
        // 不能用 saveOrUpdate：MyBatis-Plus 默认忽略 null 字段，
        // 传 "" 清除 key 时 null 不会写库，表现为「清不掉」。这里显式 set。
        LambdaUpdateWrapper<UserAiApiConfig> wrapper = new LambdaUpdateWrapper<UserAiApiConfig>()
                .eq(UserAiApiConfig::getId, config.getId());
        boolean changed = false;
        if (dto.getDeepseekKey() != null) {
            wrapper.set(UserAiApiConfig::getDeepseekKeyEnc, config.getDeepseekKeyEnc());
            changed = true;
        }
        if (dto.getTavilyKey() != null) {
            wrapper.set(UserAiApiConfig::getTavilyKeyEnc, config.getTavilyKeyEnc());
            changed = true;
        }
        if (changed) {
            update(wrapper);
        }
    }

    @Override
    public AiConfigPlainVO getPlainForAiService(Long userId) {
        UserAiApiConfig config = getByUserId(userId);
        AiConfigPlainVO vo = new AiConfigPlainVO();
        vo.setUserId(userId);
        vo.setDeepseekKey(config == null || config.getDeepseekKeyEnc() == null
                ? "" : aesGcmUtil.decrypt(config.getDeepseekKeyEnc()));
        vo.setTavilyKey(config == null || config.getTavilyKeyEnc() == null
                ? "" : aesGcmUtil.decrypt(config.getTavilyKeyEnc()));
        return vo;
    }

    /**
     * 表主键是自增 id，业务上按 user_id 唯一查询。
     */
    private UserAiApiConfig getByUserId(Long userId) {
        return getOne(new LambdaQueryWrapper<UserAiApiConfig>()
                .eq(UserAiApiConfig::getUserId, userId), false);
    }

    /**
     * 掩码：保留前 4 后 4，中间以 **** 代替；太短就整体掩码。
     */
    private String mask(String plain) {
        if (plain.length() <= 8) {
            return "****";
        }
        return plain.substring(0, 4) + "****" + plain.substring(plain.length() - 4);
    }
}
