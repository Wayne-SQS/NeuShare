package com.neushare.vo;

import lombok.Data;

@Data
public class UserProfileVO {

    private Long id;
    private String username;
    private String role;
    private String nickname;
    private String avatarUrl;
    private String college;
    private Integer grade;
    private Integer status;

    private Long resourceCount;
    private Long followerCount;
    private Long followingCount;
}
