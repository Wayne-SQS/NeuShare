package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.entity.FormCard;
import com.neushare.service.FormCardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 服务卡片公开控制器 — 供鸿蒙App调用
 */
@RestController
@RequestMapping("/api/form-card")
public class FormCardController {

    @Autowired
    private FormCardService formCardService;

    /**
     * 获取当前推荐卡片（公开接口，无需登录）
     * 鸿蒙服务卡片通过此接口获取数据
     */
    @GetMapping("/current")
    public Result<Map<String, Object>> getCurrentCard() {
        FormCard card = formCardService.getCurrentCard();
        if (card == null) {
            Map<String, Object> fallback = new HashMap<>();
            fallback.put("resourceTitle", "暂无推荐");
            fallback.put("resourceId", 0);
            fallback.put("resourceType", "book");
            fallback.put("contentUrl", "");
            return Result.success(fallback);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("resourceTitle", card.getTitle());
        data.put("resourceId", card.getResourceId());
        data.put("resourceType", card.getResourceType() != null ? card.getResourceType() : "book");
        data.put("contentUrl", card.getContentUrl() != null ? card.getContentUrl() : "");
        return Result.success(data);
    }
}
