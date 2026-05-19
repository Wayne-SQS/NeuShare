package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.LoginDTO;
import com.neushare.dto.RegisterDTO;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.UserMapper;
import com.neushare.service.UserService;
import com.neushare.util.JwtUtil;
import com.neushare.util.Md5Util;
import com.neushare.vo.UserVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 用户服务实现类
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    public User login(LoginDTO loginDTO) {
        User user = getByUsername(loginDTO.getUsername());
        if (user == null || !Md5Util.verify(loginDTO.getPassword(), user.getPassword())) {
            throw new BusinessException("用户名或密码错误");
        }
        if (user.getStatus() == 0) {
            throw new BusinessException("账号已被禁用");
        }
        return user;
    }

    @Override
    public void register(RegisterDTO registerDTO) {
        // 检查用户名是否存在
        User existUser = getByUsername(registerDTO.getUsername());
        if (existUser != null) {
            throw new BusinessException("用户名已存在");
        }
        // 创建用户
        User user = new User();
        user.setUsername(registerDTO.getUsername());
        user.setPassword(Md5Util.encrypt(registerDTO.getPassword()));
        user.setNickname(registerDTO.getNickname() != null ? registerDTO.getNickname() : registerDTO.getUsername());
        user.setAvatarUrl(registerDTO.getAvatarUrl());
        user.setCollege(registerDTO.getCollege());
        user.setGrade(registerDTO.getGrade());
        user.setRole("student");
        user.setStatus(1);
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());
        save(user);
    }

    @Override
    public User getByUsername(String username) {
        return getOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
    }

    @Override
    public UserVO getUserVOById(Long id) {
        User user = getById(id);
        if (user == null) {
            return null;
        }
        UserVO userVO = new UserVO();
        BeanUtil.copyProperties(user, userVO);
        return userVO;
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        User user = getById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        update(new LambdaUpdateWrapper<User>()
                .eq(User::getId, id)
                .set(User::getStatus, status)
                .set(User::getUpdateTime, LocalDateTime.now()));
    }
}
