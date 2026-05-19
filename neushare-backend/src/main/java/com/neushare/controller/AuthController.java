package com.neushare.controller;

import com.neushare.common.Result;
import com.neushare.dto.LoginDTO;
import com.neushare.dto.RegisterDTO;
import com.neushare.dto.UpdateUserDTO;
import com.neushare.entity.User;
import com.neushare.service.UserService;
import com.neushare.util.Md5Util;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.HashMap;
import java.util.Map;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@Valid @RequestBody LoginDTO loginDTO) {
        String token = userService.login(loginDTO);
        User user = userService.getByUsername(loginDTO.getUsername());
        UserVO userVO = userService.getUserVOById(user.getId());
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("user", userVO);
        return Result.success("登录成功", result);
    }

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<Void> register(@Valid @RequestBody RegisterDTO registerDTO) {
        userService.register(registerDTO);
        return Result.success("注册成功");
    }

    /**
     * 获取当前用户信息
     */
    @GetMapping("/info")
    public Result<UserVO> getUserInfo(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        UserVO userVO = userService.getUserVOById(userId);
        return Result.success(userVO);
    }

    /**
     * 更新用户信息
     */
    @PutMapping("/info")
    public Result<Void> updateUserInfo(HttpServletRequest request, @RequestBody UpdateUserDTO dto) {
        Long userId = (Long) request.getAttribute("userId");
        User existUser = userService.getById(userId);
        if (existUser == null) {
            return Result.error("用户不存在");
        }
        if (dto.getNickname() != null) {
            existUser.setNickname(dto.getNickname());
        }
        if (dto.getAvatarUrl() != null) {
            existUser.setAvatarUrl(dto.getAvatarUrl());
        }
        if (dto.getCollege() != null) {
            existUser.setCollege(dto.getCollege());
        }
        if (dto.getGrade() != null) {
            existUser.setGrade(dto.getGrade());
        }
        userService.updateById(existUser);
        return Result.success("更新成功");
    }

    /**
     * 修改密码
     */
    @PutMapping("/password")
    public Result<Void> updatePassword(HttpServletRequest request, @RequestParam String oldPassword, @RequestParam String newPassword) {
        Long userId = (Long) request.getAttribute("userId");
        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }
        // 验证旧密码
        if (!Md5Util.verify(oldPassword, user.getPassword())) {
            return Result.error("旧密码错误");
        }
        // 更新密码
        user.setPassword(Md5Util.encrypt(newPassword));
        userService.updateById(user);
        return Result.success("密码修改成功");
    }
}
