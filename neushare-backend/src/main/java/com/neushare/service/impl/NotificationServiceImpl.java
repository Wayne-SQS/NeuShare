package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Notification;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.NotificationMapper;
import com.neushare.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class NotificationServiceImpl extends ServiceImpl<NotificationMapper, Notification> implements NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Override
    public void send(Long userId, String type, Long resourceId, Long fromUserId, String title, String content) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setResourceId(resourceId);
        notification.setFromUserId(fromUserId);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setIsRead(0);
        notification.setCreateTime(LocalDateTime.now());
        save(notification);
    }

    @Override
    public IPage<Notification> getUserNotifications(Integer pageNum, Integer pageSize, Long userId) {
        Page<Notification> page = new Page<>(pageNum, pageSize);
        return notificationMapper.selectByUserId(page, userId);
    }

    @Override
    public int getUnreadCount(Long userId) {
        return notificationMapper.countUnread(userId);
    }

    @Override
    public void markAsRead(Long id, Long userId) {
        Notification notification = getById(id);
        if (notification == null || !notification.getUserId().equals(userId)) {
            throw new BusinessException("通知不存在");
        }
        notification.setIsRead(1);
        updateById(notification);
    }

    @Override
    public void markAllAsRead(Long userId) {
        update(new LambdaUpdateWrapper<Notification>()
                .eq(Notification::getUserId, userId)
                .eq(Notification::getIsRead, 0)
                .set(Notification::getIsRead, 1));
    }
}
