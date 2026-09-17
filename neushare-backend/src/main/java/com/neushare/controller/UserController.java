package com.neushare.controller;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.entity.User;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.service.ResourceService;
import com.neushare.service.UserService;
import com.neushare.vo.ResourceVO;
import com.neushare.vo.UserProfileVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private ResourceService resourceService;

    @GetMapping("/{id}")
    public Result<UserProfileVO> getUserProfile(@PathVariable Long id) {
        User user = userService.getById(id);
        if (user == null || user.getStatus() == 0) {
            return Result.error("用户不存在或已被禁用");
        }
        UserProfileVO vo = new UserProfileVO();
        BeanUtil.copyProperties(user, vo);
        return Result.success(vo);
    }

    @GetMapping("/{id}/resources")
    public Result<PageResult<ResourceVO>> getUserResources(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        User user = userService.getById(id);
        if (user == null || user.getStatus() == 0) {
            return Result.error("用户不存在或已被禁用");
        }
        IPage<ResourceVO> page = resourceService.getUserResources(pageNum, pageSize, id, 1);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }
}
