package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.FormCard;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.FormCardMapper;
import com.neushare.service.FormCardService;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 服务卡片服务实现
 */
@Service
public class FormCardServiceImpl extends ServiceImpl<FormCardMapper, FormCard> implements FormCardService {

    @Override
    public FormCard getCurrentCard() {
        List<FormCard> cards = list(new LambdaQueryWrapper<FormCard>()
                .eq(FormCard::getStatus, 1)
                .orderByAsc(FormCard::getSortOrder)
                .last("LIMIT 1"));
        return cards.isEmpty() ? null : cards.get(0);
    }

    @Override
    public List<FormCard> getActiveCards() {
        return list(new LambdaQueryWrapper<FormCard>()
                .eq(FormCard::getStatus, 1)
                .orderByAsc(FormCard::getSortOrder));
    }

    @Override
    public void addCard(FormCard card) {
        card.setCreateTime(LocalDateTime.now());
        card.setUpdateTime(LocalDateTime.now());
        if (card.getStatus() == null) {
            card.setStatus(1);
        }
        if (card.getSortOrder() == null) {
            card.setSortOrder(0);
        }
        if (card.getResourceType() == null) {
            card.setResourceType("book");
        }
        save(card);
    }

    @Override
    public void updateCard(FormCard card) {
        FormCard exist = getById(card.getId());
        if (exist == null) {
            throw new BusinessException("卡片不存在");
        }
        card.setUpdateTime(LocalDateTime.now());
        updateById(card);
    }

    @Override
    public void deleteCard(Long id) {
        FormCard card = getById(id);
        if (card == null) {
            throw new BusinessException("卡片不存在");
        }
        removeById(id);
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        FormCard card = getById(id);
        if (card == null) {
            throw new BusinessException("卡片不存在");
        }
        card.setStatus(status);
        card.setUpdateTime(LocalDateTime.now());
        updateById(card);
    }
}
