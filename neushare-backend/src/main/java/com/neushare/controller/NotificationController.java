package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.entity.Notification;
import com.neushare.service.NotificationService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notification")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    /** 获取当前用户通知列表 */
    @GetMapping("/list")
    public Result<PageResult<Notification>> getNotifications(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<Notification> page = notificationService.getUserNotifications(pageNum, pageSize, userId);
        PageResult<Notification> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    /** 获取未读数量 */
    @GetMapping("/unread")
    public Result<Integer> getUnreadCount(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        int count = notificationService.getUnreadCount(userId);
        return Result.success(count);
    }

    /** 标记为已读 */
    @PutMapping("/read/{id}")
    public Result<Void> markAsRead(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        notificationService.markAsRead(id, userId);
        return Result.success("已读");
    }

    /** 全部已读 */
    @PutMapping("/read-all")
    public Result<Void> markAllAsRead(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        notificationService.markAllAsRead(userId);
        return Result.success("全部已读");
    }
}
