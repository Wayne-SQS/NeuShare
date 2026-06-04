package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.dto.ResourceDTO;
import com.neushare.service.ResourceService;
import com.neushare.util.FileUploadUtil;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/resource")
public class ResourceController {

    @Autowired
    private ResourceService resourceService;

    @Autowired
    private FileUploadUtil fileUploadUtil;

    @GetMapping("/list")
    public Result<PageResult<ResourceVO>> getResourceList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String keyword) {
        IPage<ResourceVO> page = resourceService.getResourcePage(pageNum, pageSize, status, categoryId, keyword);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/detail/{id}")
    public Result<ResourceVO> getResourceDetail(@PathVariable Long id) {
        ResourceVO resourceVO = resourceService.getResourceDetail(id);
        resourceService.incrementViewCount(id);
        return Result.success(resourceVO);
    }

    @GetMapping("/hot")
    public Result<List<ResourceVO>> getHotResources(@RequestParam(defaultValue = "10") Integer limit) {
        List<ResourceVO> hotResources = resourceService.getHotResources(limit);
        return Result.success(hotResources);
    }

    @PostMapping("/create")
    public Result<Void> createResource(HttpServletRequest request,
                                       @Valid ResourceDTO resourceDTO,
                                       @RequestParam(required = false) MultipartFile file) throws IOException {
        Long userId = (Long) request.getAttribute("userId");
        if (file != null && !file.isEmpty()) {
            String filename = fileUploadUtil.upload(file);
            resourceDTO.setContentUrl(filename);
        }
        resourceService.createResource(resourceDTO, userId);
        return Result.success("创建成功，等待审核");
    }

    @PutMapping("/update")
    public Result<Void> updateResource(@Valid @RequestBody ResourceDTO resourceDTO) {
        resourceService.updateResource(resourceDTO);
        return Result.success("更新成功");
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteResource(@PathVariable Long id) {
        resourceService.deleteResource(id);
        return Result.success("删除成功");
    }

    @GetMapping("/user")
    public Result<PageResult<ResourceVO>> getUserResources(
            HttpServletRequest request,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        Long userId = (Long) request.getAttribute("userId");
        IPage<ResourceVO> page = resourceService.getUserResources(pageNum, pageSize, userId);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/search")
    public Result<PageResult<ResourceVO>> searchResources(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam String keyword) {
        IPage<ResourceVO> page = resourceService.getResourcePage(pageNum, pageSize, 1, null, keyword);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @PostMapping("/like/{id}")
    public Result<Void> likeResource(@PathVariable Long id) {
        resourceService.incrementLikeCount(id);
        return Result.success("点赞成功");
    }

    @DeleteMapping("/like/{id}")
    public Result<Void> unlikeResource(@PathVariable Long id) {
        resourceService.decrementLikeCount(id);
        return Result.success("取消点赞成功");
    }
}
