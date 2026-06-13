package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.Notification;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface NotificationMapper extends BaseMapper<Notification> {

    /** 查用户通知分页 */
    IPage<Notification> selectByUserId(Page<Notification> page, @Param("userId") Long userId);

    /** 查未读数量 */
    int countUnread(@Param("userId") Long userId);
}
