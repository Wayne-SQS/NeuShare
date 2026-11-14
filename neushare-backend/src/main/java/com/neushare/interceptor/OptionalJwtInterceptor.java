package com.neushare.interceptor;

import com.neushare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 可选登录拦截器
 *
 * 用于公开接口：无论是否携带 Token 都放行，但若携带了有效 Token，
 * 则把 userId / username / role 写入请求属性。
 *
 * 这样 /api/resource/list、/api/resource/detail/** 这类公开接口内部
 * 才能判断"当前访问者是不是资源所有者或管理员"，否则 request 属性
 * 恒为 null，所有"仅本人可见"的判断都会失效。
 */
@Component
public class OptionalJwtInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if ("OPTIONS".equals(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        if (token != null && !token.isEmpty() && jwtUtil.validateToken(token)) {
            request.setAttribute("userId", jwtUtil.getUserIdFromToken(token));
            request.setAttribute("username", jwtUtil.getUsernameFromToken(token));
            request.setAttribute("role", jwtUtil.getRoleFromToken(token));
        }
        return true;
    }
}
