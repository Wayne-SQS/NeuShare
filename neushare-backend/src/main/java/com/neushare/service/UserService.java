package com.neushare.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.dto.LoginDTO;
import com.neushare.dto.RegisterDTO;
import com.neushare.entity.User;
import com.neushare.vo.UserVO;

/**
 * 用户服务接口
 */
public interface UserService extends IService<User> {

    /**
     * 用户登录，校验通过返回 User
     */
    User login(LoginDTO loginDTO);

    /**
     * 用户注册
     */
    void register(RegisterDTO registerDTO);

    /**
     * 根据用户名查询用户
     */
    User getByUsername(String username);

    /**
     * 获取用户信息
     */
    UserVO getUserVOById(Long id);

    /**
     * 更新用户状态
     */
    void updateStatus(Long id, Integer status);

    /**
     * 级联删除用户（资源、评论、收藏、关注、点赞）
     */
    void deleteUserCascade(Long id);
}
