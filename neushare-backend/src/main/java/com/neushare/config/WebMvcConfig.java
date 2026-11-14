package com.neushare.config;

import com.neushare.interceptor.JwtInterceptor;
import com.neushare.interceptor.OptionalJwtInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

/**
 * Web MVC配置
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    /**
     * 完全公开、无需识别访问者身份的路径
     */
    private static final String[] PUBLIC_PATHS = {
            "/api/auth/login",
            "/api/auth/register",
            "/api/banner/list",
            "/api/category/list",
            "/api/form-card/current",
            "/api/stats/overview",
            "/api/resource/hot",
            "/api/post/hot",
            "/files/**",
            "/error"
    };

    /**
     * 公开但需要识别访问者身份的路径：带了有效 Token 就解析出 userId/role，
     * 没带也放行。资源/帖子的"所有者可查看未发布内容"依赖这里写入的属性。
     */
    private static final String[] OPTIONAL_AUTH_PATHS = {
            "/api/resource/list",
            "/api/resource/detail/**",
            "/api/resource/search",
            "/api/post/list",
            "/api/post/detail/**",
            "/api/comment/list/**",
            "/api/post/comment/list/**",
            "/api/user/*",
            "/api/user/*/resources"
    };

    @Autowired
    private JwtInterceptor jwtInterceptor;

    @Autowired
    private OptionalJwtInterceptor optionalJwtInterceptor;

    @Value("${file.upload.path:uploads}")
    private String uploadPath;

    /**
     * 添加拦截器
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 可选登录：先于强制登录执行，只做身份解析，不做拦截
        registry.addInterceptor(optionalJwtInterceptor)
                .addPathPatterns(OPTIONAL_AUTH_PATHS)
                .order(0);

        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns(PUBLIC_PATHS)
                .excludePathPatterns(OPTIONAL_AUTH_PATHS)
                .order(1);
    }

    /**
     * 静态资源映射：将 uploads 目录映射为 /files/** 路径，支持文件下载
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        java.nio.file.Path dir = java.nio.file.Paths.get(uploadPath);
        if (!dir.isAbsolute()) {
            dir = java.nio.file.Paths.get(System.getProperty("user.dir")).resolve(uploadPath);
        }
        String location = "file:" + dir.toAbsolutePath().normalize() + File.separator;
        registry.addResourceHandler("/files/**")
                .addResourceLocations(location);
    }
}
