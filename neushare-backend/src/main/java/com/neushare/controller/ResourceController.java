package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.dto.ResourceDTO;
import com.neushare.dto.ResourceQuery;
import com.neushare.service.ResourceService;
import com.neushare.util.FileUploadUtil;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String courseName,
            @RequestParam(required = false) String teacher,
            @RequestParam(required = false) String schoolYear,
            @RequestParam(required = false) String term,
            @RequestParam(required = false) String type,
            HttpServletRequest request) {
        // 公开接口：非管理员只能看已发布资源，防止通过 status 参数窥探待审核/驳回内容
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        boolean isAdmin = userId != null && "admin".equals(role);
        Integer effectiveStatus = (status != null && isAdmin) ? status : 1;

        ResourceQuery query = new ResourceQuery();
        query.setPageNum(pageNum);
        query.setPageSize(pageSize);
        query.setStatus(effectiveStatus);
        query.setCategoryId(categoryId);
        query.setKeyword(keyword);
        query.setCourseName(courseName);
        query.setTeacher(teacher);
        query.setSchoolYear(schoolYear);
        query.setTerm(term);
        query.setType(type);
        // 不传 sortBy 且无关键词时按时间倒序；有关键词时 Service 内部会切成相关度排序
        query.setSortBy(sortBy == null || sortBy.isBlank() ? "new" : sortBy);

        IPage<ResourceVO> page = resourceService.search(query);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    @GetMapping("/detail/{id}")
    public Result<ResourceVO> getResourceDetail(@PathVariable Long id, HttpServletRequest request) {
        ResourceVO resourceVO = resourceService.getResourceDetail(id);
        // 公开接口：未发布资源仅上传者和管理员可查看
        if (resourceVO.getStatus() != null && resourceVO.getStatus() != 1) {
            Long userId = (Long) request.getAttribute("userId");
            String role = (String) request.getAttribute("role");
            boolean isOwner = userId != null && userId.equals(resourceVO.getUploadUserId());
            boolean isAdmin = "admin".equals(role);
            if (!isOwner && !isAdmin) {
                return Result.error(404, "资源不存在");
            }
        }
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
    public Result<Void> updateResource(HttpServletRequest request, @Valid @RequestBody ResourceDTO resourceDTO) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        resourceService.updateResource(resourceDTO, userId, role);
        return Result.success("更新成功");
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteResource(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        resourceService.deleteResource(id, userId, role);
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
            @RequestParam String keyword,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String courseName,
            @RequestParam(required = false) String teacher,
            @RequestParam(required = false) String schoolYear,
            @RequestParam(required = false) String term,
            @RequestParam(required = false) String type) {
        ResourceQuery query = new ResourceQuery();
        query.setPageNum(pageNum);
        query.setPageSize(pageSize);
        query.setKeyword(keyword);
        query.setCategoryId(categoryId);
        query.setCourseName(courseName);
        query.setTeacher(teacher);
        query.setSchoolYear(schoolYear);
        query.setTerm(term);
        query.setType(type);
        query.setStatus(1);
        // 搜索接口默认按相关度，用户可显式指定 hot / new
        query.setSortBy(sortBy == null || sortBy.isBlank() ? "relevance" : sortBy);

        IPage<ResourceVO> page = resourceService.search(query);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
    }

    /**
     * 搜索联想：根据输入返回标题候选，供前端下拉提示
     */
    @GetMapping("/suggest")
    public Result<List<String>> suggest(@RequestParam String keyword,
                                        @RequestParam(defaultValue = "10") Integer limit) {
        return Result.success(resourceService.suggest(keyword, limit));
    }

    /**
     * 结构化筛选项：当前已发布资源中出现过的课程与教师
     * <p>前端用它渲染筛选下拉，避免让用户面对空选项
     */
    @GetMapping("/filters")
    public Result<Map<String, List<String>>> filters() {
        Map<String, List<String>> data = new HashMap<>();
        data.put("courses", resourceService.listCourseNames());
        data.put("teachers", resourceService.listTeachers());
        return Result.success(data);
    }

    @PostMapping("/like/{id}")
    public Result<Void> likeResource(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        resourceService.likeResource(id, userId);
        return Result.success("点赞成功");
    }

    @DeleteMapping("/like/{id}")
    public Result<Void> unlikeResource(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        resourceService.unlikeResource(id, userId);
        return Result.success("取消点赞成功");
    }

    @GetMapping("/like/check/{id}")
    public Result<Boolean> checkLiked(HttpServletRequest request, @PathVariable Long id) {
        Long userId = (Long) request.getAttribute("userId");
        boolean liked = resourceService.isLiked(id, userId);
        return Result.success(liked);
    }
}
