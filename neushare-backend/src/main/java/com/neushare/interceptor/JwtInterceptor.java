package com.neushare.interceptor;

import com.neushare.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * JWT拦截器
 */
@Component
public class JwtInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // 放行OPTIONS请求
        if ("OPTIONS".equals(request.getMethod())) {
            return true;
        }

        // 获取Token
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        // 验证Token
        if (token == null || !jwtUtil.validateToken(token)) {
            response.setStatus(401);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":401,\"message\":\"未登录或登录已过期\",\"data\":null}");
            return false;
        }

        // 将用户信息存入请求属性
        request.setAttribute("userId", jwtUtil.getUserIdFromToken(token));
        request.setAttribute("username", jwtUtil.getUsernameFromToken(token));
        String role = jwtUtil.getRoleFromToken(token);
        request.setAttribute("role", role);

        // 管理员接口校验
        if (request.getRequestURI().startsWith("/api/admin/") && !"admin".equals(role)) {
            response.setStatus(403);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":403,\"message\":\"无访问权限\",\"data\":null}");
            return false;
        }

        return true;
    }
}
