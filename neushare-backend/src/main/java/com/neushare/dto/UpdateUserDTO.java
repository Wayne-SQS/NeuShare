package com.neushare.dto;

import lombok.Data;

@Data
public class UpdateUserDTO {

    private String nickname;

    private String avatarUrl;

    private String college;

    private Integer grade;
}
