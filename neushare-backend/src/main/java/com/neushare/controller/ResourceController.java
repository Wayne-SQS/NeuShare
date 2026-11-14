package com.neushare.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.neushare.common.PageResult;
import com.neushare.common.Result;
import com.neushare.dto.ResourceDTO;
import com.neushare.service.ResourceService;
import com.neushare.util.FileUploadUtil;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
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
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "new") String sortBy,
            HttpServletRequest request) {
        // 公开接口：非管理员只能看已发布资源，防止通过 status 参数窥探待审核/驳回内容
        Long userId = (Long) request.getAttribute("userId");
        String role = (String) request.getAttribute("role");
        boolean isAdmin = userId != null && "admin".equals(role);
        Integer effectiveStatus = (status != null && isAdmin) ? status : 1;
        IPage<ResourceVO> page = resourceService.getResourcePage(pageNum, pageSize, effectiveStatus, categoryId, keyword, sortBy);
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

    /**
     * 下载资源文件。
     * - 外链资源：302 跳转到原地址，不占用后端带宽
     * - 本地文件：以 attachment 形式流式输出，文件名取「资源标题 + 原扩展名」
     * - 未发布资源仅上传者/管理员可下载（与详情页权限一致）
     */
    @GetMapping("/download/{id}")
    public ResponseEntity<InputStreamResource> downloadResource(@PathVariable Long id,
                                                                HttpServletRequest request) throws FileNotFoundException {
        ResourceVO vo = resourceService.getResourceDetail(id);
        // 权限：未发布资源仅上传者/管理员可下载
        if (vo.getStatus() != null && vo.getStatus() != 1) {
            Long userId = (Long) request.getAttribute("userId");
            String role = (String) request.getAttribute("role");
            boolean isOwner = userId != null && userId.equals(vo.getUploadUserId());
            boolean isAdmin = "admin".equals(role);
            if (!isOwner && !isAdmin) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        }
        // 外链直接 302 跳转到原地址
        if (resourceService.isExternalUrl(vo.getContentUrl())) {
            return ResponseEntity.status(HttpStatus.FOUND).location(URI.create(vo.getContentUrl())).build();
        }
        // 文件缺失时 resolveDownloadFile 抛业务异常，由全局异常处理转成 JSON 错误
        File file = resourceService.resolveDownloadFile(id);
        String filename = buildDownloadFilename(vo.getTitle(), file.getName());
        InputStreamResource body = new InputStreamResource(new FileInputStream(file));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodeRfc5987(filename))
                .contentLength(file.length())
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(body);
    }

    /**
     * 构造下载文件名：优先用资源标题，扩展名沿用物理文件原名，
     * 并去掉 Windows 文件名非法字符，避免标题里的特殊字符破坏扩展名。
     */
    private String buildDownloadFilename(String title, String physicalName) {
        String base = (title == null || title.isBlank()) ? "resource" : title.trim();
        base = base.replaceAll("[\\\\/:*?\"<>|]", "_");
        String ext = "";
        int dot = physicalName.lastIndexOf('.');
        if (dot >= 0) {
            ext = physicalName.substring(dot);
        }
        return base + ext;
    }

    /**
     * 按 RFC 5987 编码文件名，兼容中文文件名下载
     */
    private String encodeRfc5987(String filename) {
        return URLEncoder.encode(filename, StandardCharsets.UTF_8).replace("+", "%20");
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
            @RequestParam(defaultValue = "new") String sortBy) {
        IPage<ResourceVO> page = resourceService.searchResources(pageNum, pageSize, keyword, sortBy);
        PageResult<ResourceVO> pageResult = new PageResult<>(page.getCurrent(), page.getSize(), page.getTotal(), page.getRecords());
        return Result.success(pageResult);
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
