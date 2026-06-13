package com.neushare.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.FormCard;

import java.util.List;

/**
 * 服务卡片服务接口
 */
public interface FormCardService extends IService<FormCard> {

    /**
     * 获取当前启用的卡片（按 sort_order 排序取第一条）
     */
    FormCard getCurrentCard();

    /**
     * 获取全部启用的卡片
     */
    List<FormCard> getActiveCards();

    /**
     * 添加卡片
     */
    void addCard(FormCard card);

    /**
     * 更新卡片
     */
    void updateCard(FormCard card);

    /**
     * 删除卡片
     */
    void deleteCard(Long id);

    /**
     * 切换卡片状态
     */
    void updateStatus(Long id, Integer status);
}
