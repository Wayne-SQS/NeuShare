package com.neushare.interceptor;

import com.neushare.util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * 可选登录拦截器测试：确保公开接口在带/不带 Token 时都不会被拦截，
 * 且只有有效 Token 才会写入 userId / role。
 */
class OptionalJwtInterceptorTest {

    private OptionalJwtInterceptor interceptor;
    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = mock(JwtUtil.class);
        interceptor = new OptionalJwtInterceptor();
        ReflectionTestUtils.setField(interceptor, "jwtUtil", jwtUtil);
    }

    @Test
    void shouldPassWithoutTokenAndSetNothing() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/resource/list");
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean allowed = interceptor.preHandle(request, response, new Object());

        assertTrue(allowed);
        assertNull(request.getAttribute("userId"));
        assertNull(request.getAttribute("role"));
    }

    @Test
    void shouldResolveIdentityWithValidToken() throws Exception {
        String token = "valid-token";
        when(jwtUtil.validateToken(token)).thenReturn(true);
        when(jwtUtil.getUserIdFromToken(token)).thenReturn(7L);
        when(jwtUtil.getUsernameFromToken(token)).thenReturn("alice");
        when(jwtUtil.getRoleFromToken(token)).thenReturn("admin");

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/resource/detail/1");
        request.addHeader("Authorization", "Bearer " + token);
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean allowed = interceptor.preHandle(request, response, new Object());

        assertTrue(allowed);
        assertEquals(7L, request.getAttribute("userId"));
        assertEquals("alice", request.getAttribute("username"));
        assertEquals("admin", request.getAttribute("role"));
    }

    @Test
    void shouldPassButIgnoreInvalidToken() throws Exception {
        String token = "broken-token";
        when(jwtUtil.validateToken(token)).thenReturn(false);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/post/list");
        request.addHeader("Authorization", "Bearer " + token);
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean allowed = interceptor.preHandle(request, response, new Object());

        assertTrue(allowed);
        assertNull(request.getAttribute("userId"));
    }

    @Test
    void shouldPassOptionsPreflight() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("OPTIONS", "/api/resource/list");
        MockHttpServletResponse response = new MockHttpServletResponse();

        assertTrue(interceptor.preHandle(request, response, new Object()));
    }
}
