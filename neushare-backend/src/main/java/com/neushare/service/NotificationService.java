package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Notification;
import com.neushare.vo.NotificationVO;

/**
 * 通知服务接口
 */
public interface NotificationService extends IService<Notification> {

    /** 发送通知 */
    void send(Long userId, String type, Long resourceId, Long fromUserId, String title, String content);

    /** 查询用户通知分页（含触发者信息，支持按类型筛选） */
    IPage<NotificationVO> getUserNotifications(Integer pageNum, Integer pageSize, Long userId, String type);

    /** 获取未读数量 */
    int getUnreadCount(Long userId);

    /** 标记为已读 */
    void markAsRead(Long id, Long userId);

    /** 标记全部已读 */
    void markAllAsRead(Long userId);

    /** 删除单条通知 */
    void deleteNotification(Long id, Long userId);
}
