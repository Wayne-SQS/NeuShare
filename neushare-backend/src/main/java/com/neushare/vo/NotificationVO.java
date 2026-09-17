package com.neushare.vo;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class NotificationVO {
    private Long id;
    private Long userId;
    private Long fromUserId;
    private String type;
    private String title;
    private String content;
    private Long resourceId;
    private Integer isRead;
    private LocalDateTime createTime;

    // 触发者信息
    private String fromUsername;
    private String fromNickname;
    private String fromAvatarUrl;
}
