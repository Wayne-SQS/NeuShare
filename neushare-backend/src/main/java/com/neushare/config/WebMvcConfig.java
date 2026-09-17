package com.neushare.config;

import com.neushare.interceptor.JwtInterceptor;
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

    @Autowired
    private JwtInterceptor jwtInterceptor;

    @Value("${file.upload.path:uploads}")
    private String uploadPath;

    /**
     * 添加拦截器
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns(
                        "/api/auth/login",
                        "/api/auth/register",
                        "/api/resource/list",
                        "/api/resource/hot",
                        "/api/resource/detail/**",
                        "/api/resource/search",
                        "/api/banner/list",
                        "/api/comment/list/**",
                        "/api/category/list",
                        "/api/form-card/current",
                        "/api/stats/overview",
                        "/api/user/*/resources",
                        "/api/user/*",
                        "/api/post/list",
                        "/api/post/hot",
                        "/api/post/detail/**",
                        "/api/post/comment/list/**",
                        "/files/**",
                        "/error"
                );
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
