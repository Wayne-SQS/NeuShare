package com.neushare.config;

import com.neushare.interceptor.JwtInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC配置
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Autowired
    private JwtInterceptor jwtInterceptor;

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
                        "/api/user/**",
                        "/error"
                );
    }
}
