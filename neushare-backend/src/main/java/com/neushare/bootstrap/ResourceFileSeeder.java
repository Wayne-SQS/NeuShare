package com.neushare.bootstrap;

import com.neushare.entity.Resource;
import com.neushare.service.ResourceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 启动时补齐种子资源引用的占位物理文件。
 *
 * 背景：init.sql / test-data-with-files.sql 中的资源 content_url 指向
 * 如 test-math-notes.pdf 之类的裸文件名，但 uploads/ 被 .gitignore 忽略，
 * 仓库不携带这些文件，导致克隆后所有种子资源"文件丢失"、无法下载/预览。
 *
 * 本组件在应用启动时扫描 resource 表，对所有非外链且物理文件缺失的记录，
 * 在 uploads 目录下生成同名占位文件（内容为资源标题 + 说明），使演示站
 * 开箱即可下载/预览。幂等：已存在的文件不会被覆盖，上传真实文件后即覆盖占位。
 */
@Component
public class ResourceFileSeeder implements ApplicationRunner {

    @Autowired
    private ResourceService resourceService;

    @Value("${file.upload.path:uploads}")
    private String uploadPath;

    @Override
    public void run(ApplicationArguments args) {
        try {
            Path dir = resolveUploadDir();
            Files.createDirectories(dir);
            List<Resource> resources = resourceService.list();
            Set<String> created = new HashSet<>();
            for (Resource r : resources) {
                String contentUrl = r.getContentUrl();
                if (contentUrl == null || contentUrl.isBlank()) {
                    continue;
                }
                // 外链不由本地托管，不生成占位
                if (contentUrl.startsWith("http://") || contentUrl.startsWith("https://")) {
                    continue;
                }
                Path file = dir.resolve(contentUrl).normalize();
                // 防御路径穿越：归一化后必须仍位于上传目录内
                if (!file.startsWith(dir)) {
                    continue;
                }
                if (Files.exists(file)) {
                    continue;
                }
                Files.write(file, buildPlaceholderContent(r).getBytes(StandardCharsets.UTF_8));
                created.add(contentUrl);
            }
            if (!created.isEmpty()) {
                System.out.println("[ResourceFileSeeder] 已补齐 " + created.size() + " 个种子资源占位文件: " + created);
            }
        } catch (Exception e) {
            // 占位文件生成失败不应阻断应用启动，仅记录日志
            System.err.println("[ResourceFileSeeder] 补齐占位文件失败（不影响应用启动）: " + e.getMessage());
        }
    }

    private Path resolveUploadDir() {
        Path dir = Paths.get(uploadPath);
        if (!dir.isAbsolute()) {
            dir = Paths.get(System.getProperty("user.dir")).resolve(uploadPath);
        }
        return dir.toAbsolutePath().normalize();
    }

    private String buildPlaceholderContent(Resource r) {
        StringBuilder sb = new StringBuilder();
        sb.append("NeuShare 演示占位文件\n");
        sb.append("========================\n");
        sb.append("标题：").append(r.getTitle() == null ? "(无标题)" : r.getTitle()).append("\n");
        sb.append("资源ID：").append(r.getId()).append("\n");
        sb.append("类型：").append(r.getType() == null ? "" : r.getType()).append("\n");
        sb.append("描述：").append(r.getDescription() == null ? "(无描述)" : r.getDescription()).append("\n");
        sb.append("来源：").append(r.getSource() == null ? "" : r.getSource()).append("\n");
        sb.append("------------------------\n");
        sb.append("说明：这是应用启动时自动生成的占位文件，用于保证演示环境下资源可下载/可预览。\n");
        sb.append("用户上传真实文件后会覆盖此占位内容。\n");
        return sb.toString();
    }
}
