package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.dto.AiConfigUpdateDTO;
import com.neushare.service.AiConfigService;
import com.neushare.vo.AiConfigPlainVO;
import com.neushare.vo.AiConfigStatusVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户自带 AI API Key（BYOK）。
 *
 * 路径安全说明：/api/ai/config 不在 JwtInterceptor 白名单里，三个接口都要求登录。
 * 千万不要挪到 /api/user/** 下——/api/user/* 是公开白名单，会被放行。
 *
 * /internal 后缀的接口是给 neushare-ai 服务调的：AI 侧透传用户的
 * Authorization 头过来，同样走 JWT 校验，身份即用户本人，不存在服务间密钥。
 */
@RestController
@RequestMapping("/api/ai")
public class AiConfigController {

    @Autowired
    private AiConfigService aiConfigService;

    /** 设置页拉当前状态（掩码，无明文） */
    @GetMapping("/config")
    public Result<AiConfigStatusVO> getStatus(@RequestAttribute("userId") Long userId) {
        return Result.success(aiConfigService.getStatus(userId));
    }

    /** 保存 / 清除 key。null=不改，""=清除，有值=加密保存 */
    @PutMapping("/config")
    public Result<Void> updateConfig(@RequestAttribute("userId") Long userId,
                                     @RequestBody AiConfigUpdateDTO dto) {
        aiConfigService.updateConfig(userId, dto);
        return Result.success("已保存");
    }

    /** 给 neushare-ai 服务：带用户 JWT 调用，返回解密后的 key（未配置为 ""） */
    @GetMapping("/config/internal")
    public Result<AiConfigPlainVO> getPlain(@RequestAttribute("userId") Long userId) {
        return Result.success(aiConfigService.getPlainForAiService(userId));
    }
}
