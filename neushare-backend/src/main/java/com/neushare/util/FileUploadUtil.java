package com.neushare.util;

import com.neushare.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Component
public class FileUploadUtil {

    /**
     * 允许上传的扩展名。上传目录会被静态映射为 /files/**，
     * 因此必须禁止 html/js/svg 等可执行脚本的类型，避免同源 XSS。
     */
    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<>(Arrays.asList(
            "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "txt", "md", "csv",
            "zip", "rar", "7z", "tar", "gz", "epub", "caj",
            "png", "jpg", "jpeg", "gif", "webp", "bmp",
            "mp3", "wav", "mp4", "avi", "mov"
    ));

    @Value("${file.upload.path:uploads}")
    private String uploadPath;

    public String upload(MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new BusinessException(400, "文件为空");
        }
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String ext = extension.startsWith(".") ? extension.substring(1).toLowerCase(Locale.ROOT) : "";
        if (ext.isEmpty() || !ALLOWED_EXTENSIONS.contains(ext)) {
            throw new BusinessException(400, "不支持的文件类型：" + (ext.isEmpty() ? "无扩展名" : ext));
        }
        String filename = UUID.randomUUID().toString() + "." + ext;
        Path dir = Paths.get(uploadPath);
        if (!dir.isAbsolute()) {
            dir = Paths.get(System.getProperty("user.dir")).resolve(uploadPath);
        }
        if (!Files.exists(dir)) {
            Files.createDirectories(dir);
        }
        File dest = dir.resolve(filename).toFile();
        file.transferTo(dest);
        return filename;
    }
}
