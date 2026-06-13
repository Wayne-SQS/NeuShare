package com.neushare.dto;

import lombok.Data;

import jakarta.validation.constraints.NotBlank;

/**
 * 注册请求DTO
 */
@Data
public class RegisterDTO {

    /**
     * 用户名
     */
    @NotBlank(message = "用户名不能为空")
    private String username;

    /**
     * 密码
     */
    @NotBlank(message = "密码不能为空")
    private String password;

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
     * 年级(1-4)
     */
    private Integer grade;
}
