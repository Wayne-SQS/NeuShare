package com.neushare.vo;

import lombok.Data;

/**
 * 用户信息视图对象
 */
@Data
public class UserVO {

    /**
     * 用户ID
     */
    private Long id;

    /**
     * 用户名
     */
    private String username;

    /**
     * 角色
     */
    private String role;

    /**
     * 昵称
     */
    private String nickname;

    /**
     * 头像URL
     */
    private String avatarUrl;

    /**
     * 学院
     */
    private String college;

    /**
     * 年级
     */
    private Integer grade;

    /**
     * 状态
     */
    private Integer status;
}
