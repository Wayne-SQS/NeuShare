package com.neushare.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.bean.copier.CopyOptions;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.dto.ResourceDTO;
import com.neushare.entity.Comment;
import com.neushare.entity.Favorite;
import com.neushare.entity.Resource;
import com.neushare.entity.ResourceLike;
import com.neushare.entity.User;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.CommentMapper;
import com.neushare.mapper.FavoriteMapper;
import com.neushare.mapper.ResourceLikeMapper;
import com.neushare.mapper.ResourceMapper;
import com.neushare.mapper.UserMapper;
import com.neushare.service.NotificationService;
import com.neushare.service.ResourceService;
import com.neushare.vo.ResourceVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 资源服务实现类
 */
@Service
public class ResourceServiceImpl extends ServiceImpl<ResourceMapper, Resource> implements ResourceService {

    @Autowired
    private ResourceMapper resourceMapper;

    @Autowired
    private ResourceLikeMapper resourceLikeMapper;

    @Autowired
    private CommentMapper commentMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @Value("${file.upload.path:uploads}")
    private String uploadPath;

    /**
     * 解析上传目录（与 FileUploadUtil / WebMvcConfig 保持同一套相对→绝对规则）
     */
    private Path resolveUploadDir() {
        Path dir = Paths.get(uploadPath);
        if (!dir.isAbsolute()) {
            dir = Paths.get(System.getProperty("user.dir")).resolve(uploadPath);
        }
        return dir.toAbsolutePath().normalize();
    }

    /**
     * 是否为外部链接（http/https）。外链不由本地 uploads 托管，无法本地校验存在性，视为存在。
     */
    private boolean isExternalLink(String contentUrl) {
        return contentUrl != null && (contentUrl.startsWith("http://") || contentUrl.startsWith("https://"));
    }

    /**
     * 资源对应的物理文件是否存在。
     * - 外链：视为存在
     * - 空 contentUrl：不存在
     * - 本地裸文件名：检查 uploads 下是否存在该文件
     */
    private boolean physicalFileExists(String contentUrl) {
        if (contentUrl == null || contentUrl.isBlank()) {
            return false;
        }
        if (isExternalLink(contentUrl)) {
            return true;
        }
        Path file = resolveUploadDir().resolve(contentUrl).normalize();
        // 防御路径穿越：归一化后仍需位于上传目录内
        if (!file.startsWith(resolveUploadDir())) {
            return false;
        }
        return Files.exists(file) && Files.isRegularFile(file);
    }

    /**
     * 回填单个 VO 的 fileExists 字段
     */
    private ResourceVO enrichFileExists(ResourceVO vo) {
        if (vo != null) {
            vo.setFileExists(physicalFileExists(vo.getContentUrl()));
        }
        return vo;
    }

    /**
     * 批量回填列表的 fileExists 字段
     */
    private void enrichFileExists(List<ResourceVO> list) {
        if (list != null) {
            list.forEach(this::enrichFileExists);
        }
    }

    @Override
    public IPage<ResourceVO> getResourcePage(Integer pageNum, Integer pageSize, Integer status, Long categoryId, String keyword, String sortBy) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        IPage<ResourceVO> result = resourceMapper.selectResourcePage(page, status, categoryId, keyword, sortBy);
        enrichFileExists(result.getRecords());
        return result;
    }

    @Override
    public ResourceVO getResourceDetail(Long id) {
        ResourceVO resourceVO = resourceMapper.selectResourceById(id);
        if (resourceVO == null) {
            throw new BusinessException("资源不存在");
        }
        return enrichFileExists(resourceVO);
    }

    @Override
    public boolean isExternalUrl(String contentUrl) {
        return isExternalLink(contentUrl);
    }

    @Override
    public File resolveDownloadFile(Long id) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        String contentUrl = resource.getContentUrl();
        if (contentUrl == null || contentUrl.isBlank()) {
            throw new BusinessException("资源未关联文件");
        }
        if (isExternalLink(contentUrl)) {
            throw new BusinessException("该资源为外部链接，请直接访问原地址");
        }
        Path dir = resolveUploadDir();
        Path file = dir.resolve(contentUrl).normalize();
        if (!file.startsWith(dir) || !Files.exists(file) || !Files.isRegularFile(file)) {
            throw new BusinessException(404, "文件不存在或已丢失");
        }
        return file.toFile();
    }

    /**
     * 删除资源关联的物理文件（仅本地文件，外链跳过）。删除失败不阻断 DB 删除，仅记录日志。
     */
    private void deletePhysicalFile(String contentUrl) {
        if (contentUrl == null || contentUrl.isBlank() || isExternalLink(contentUrl)) {
            return;
        }
        Path dir = resolveUploadDir();
        Path file = dir.resolve(contentUrl).normalize();
        if (!file.startsWith(dir)) {
            return;
        }
        try {
            Files.deleteIfExists(file);
        } catch (IOException e) {
            // 物理文件删除失败不影响主流程，避免因文件占用导致资源删不掉
            System.err.println("[ResourceService] 删除物理文件失败: " + file + " - " + e.getMessage());
        }
    }

    @Override
    public void createResource(ResourceDTO resourceDTO, Long userId) {
        Resource resource = new Resource();
        BeanUtil.copyProperties(resourceDTO, resource);
        resource.setUploadUserId(userId);
        resource.setStatus(0);
        resource.setViewCount(0);
        resource.setLikeCount(0);
        resource.setFavoriteCount(0);
        if (resource.getType() == null || resource.getType().isBlank()) {
            resource.setType("document");
        }
        // 资源必须关联物理文件或外部链接，禁止创建空资源/垃圾资源
        if (resource.getContentUrl() == null || resource.getContentUrl().isBlank()) {
            throw new BusinessException(400, "请上传资源文件或填写资源链接");
        }
        resource.setCreateTime(LocalDateTime.now());
        resource.setUpdateTime(LocalDateTime.now());
        save(resource);
        // 实时更新用户资源计数（待审核也算，校准任务只算已发布）
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, userId)
                .setSql("resource_count = resource_count + 1"));
    }

    @Override
    public void updateResource(ResourceDTO resourceDTO, Long userId, String role) {
        Resource resource = getById(resourceDTO.getId());
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 校验所有者或管理员
        if (!resource.getUploadUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权修改此资源");
        }
        // DTO 里没传的字段保持原值，避免编辑时把已有封面/文件地址清空
        BeanUtil.copyProperties(resourceDTO, resource, CopyOptions.create().setIgnoreNullValue(true));
        boolean isAdmin = "admin".equals(role);
        if (!isAdmin) {
            // 普通用户修改内容后需要重新审核，防止"审核通过 -> 改内容 -> 免审核发布"
            resource.setStatus(0);
            resource.setRejectReason(null);
        }
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    @Transactional
    public void deleteResource(Long id, Long userId, String role) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 校验所有者或管理员
        if (!resource.getUploadUserId().equals(userId) && !"admin".equals(role)) {
            throw new BusinessException("无权删除此资源");
        }
        // 级联删除：评论、收藏、点赞
        commentMapper.delete(new LambdaQueryWrapper<Comment>().eq(Comment::getResourceId, id));
        favoriteMapper.delete(new LambdaQueryWrapper<Favorite>().eq(Favorite::getResourceId, id));
        resourceLikeMapper.delete(new LambdaQueryWrapper<ResourceLike>().eq(ResourceLike::getResourceId, id));
        // 同步删除物理文件（外链跳过），避免 uploads 目录残留孤儿文件
        deletePhysicalFile(resource.getContentUrl());
        removeById(id);
        // 实时更新用户资源计数
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .gt(User::getResourceCount, 0)
                .setSql("resource_count = resource_count - 1"));
    }

    @Override
    public List<ResourceVO> getHotResources(Integer limit) {
        List<ResourceVO> list = resourceMapper.selectHotResources(limit);
        enrichFileExists(list);
        return list;
    }

    @Override
    public void incrementViewCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .setSql("view_count = view_count + 1"));
    }

    @Override
    public void auditResource(Long id, Integer status, String rejectReason) {
        Resource resource = getById(id);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 通过审核前校验物理文件存在，避免"无文件"的垃圾资源流向已发布列表
        if (status != null && status == 1
                && !isExternalLink(resource.getContentUrl())
                && !physicalFileExists(resource.getContentUrl())) {
            throw new BusinessException("资源文件不存在，无法通过审核，请重新上传");
        }
        resource.setStatus(status);
        if (status == 2 && rejectReason != null && !rejectReason.isEmpty()) {
            resource.setRejectReason(rejectReason);
        }
        resource.setUpdateTime(LocalDateTime.now());
        updateById(resource);
    }

    @Override
    public IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        IPage<ResourceVO> result = resourceMapper.selectUserResources(page, userId);
        enrichFileExists(result.getRecords());
        return result;
    }

    @Override
    public IPage<ResourceVO> getUserResources(Integer pageNum, Integer pageSize, Long userId, Integer status) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        IPage<ResourceVO> result = resourceMapper.selectUserResourcesByStatus(page, userId, status);
        enrichFileExists(result.getRecords());
        return result;
    }

    @Override
    public void incrementLikeCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .setSql("like_count = like_count + 1"));
    }

    @Override
    public void decrementLikeCount(Long id) {
        update(new LambdaUpdateWrapper<Resource>()
                .eq(Resource::getId, id)
                .gt(Resource::getLikeCount, 0)
                .setSql("like_count = like_count - 1"));
    }

    @Override
    @Transactional
    public void likeResource(Long resourceId, Long userId) {
        Resource resource = getById(resourceId);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        // 检查是否已点赞
        ResourceLike exist = resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (exist != null) {
            throw new BusinessException("已点赞该资源");
        }
        // 添加点赞记录
        ResourceLike like = new ResourceLike();
        like.setUserId(userId);
        like.setResourceId(resourceId);
        like.setCreateTime(LocalDateTime.now());
        resourceLikeMapper.insert(like);
        // 原子更新点赞数
        incrementLikeCount(resourceId);
        // 实时更新资源作者的 totalLikesReceived
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .setSql("total_likes_received = total_likes_received + 1"));
        // 通知资源上传者（如果点赞者不是上传者本人）
        if (!resource.getUploadUserId().equals(userId)) {
            User user = userMapper.selectById(userId);
            String userName = user != null ? user.getNickname() : "有人";
            notificationService.send(resource.getUploadUserId(), "like", resourceId, userId,
                    "有人点赞了你的资源", userName + " 点赞了你的资源「" + resource.getTitle() + "」。");
        }
    }

    @Override
    @Transactional
    public void unlikeResource(Long resourceId, Long userId) {
        Resource resource = getById(resourceId);
        if (resource == null) {
            throw new BusinessException("资源不存在");
        }
        ResourceLike exist = resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId);
        if (exist == null) {
            throw new BusinessException("未点赞该资源");
        }
        resourceLikeMapper.deleteById(exist.getId());
        decrementLikeCount(resourceId);
        // 实时更新资源作者的 totalLikesReceived
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, resource.getUploadUserId())
                .gt(User::getTotalLikesReceived, 0)
                .setSql("total_likes_received = total_likes_received - 1"));
    }

    @Override
    public boolean isLiked(Long resourceId, Long userId) {
        return resourceLikeMapper.selectByUserIdAndResourceId(userId, resourceId) != null;
    }

    @Override
    public IPage<ResourceVO> searchResources(Integer pageNum, Integer pageSize, String keyword, String sortBy) {
        Page<ResourceVO> page = new Page<>(pageNum, pageSize);
        IPage<ResourceVO> result = resourceMapper.searchResources(page, keyword, sortBy);
        enrichFileExists(result.getRecords());
        return result;
    }

    @Override
    public Long getTotalLikesReceived(Long userId) {
        Long total = resourceMapper.selectTotalLikesReceived(userId);
        return total != null ? total : 0L;
    }
}
