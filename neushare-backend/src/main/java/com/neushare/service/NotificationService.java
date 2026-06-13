package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Notification;

/**
 * 通知服务接口
 */
public interface NotificationService extends IService<Notification> {

    /** 发送通知 */
    void send(Long userId, String type, Long resourceId, Long fromUserId, String title, String content);

    /** 查询用户通知分页 */
    IPage<Notification> getUserNotifications(Integer pageNum, Integer pageSize, Long userId);

    /** 获取未读数量 */
    int getUnreadCount(Long userId);

    /** 标记为已读 */
    void markAsRead(Long id, Long userId);

    /** 标记全部已读 */
    void markAllAsRead(Long userId);
}
