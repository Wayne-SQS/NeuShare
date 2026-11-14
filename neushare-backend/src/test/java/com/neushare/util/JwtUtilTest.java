package com.neushare.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * JwtUtil 单元测试：不启动 Spring 上下文，直接注入 @Value 字段。
 */
class JwtUtilTest {

    private static final String SECRET = "neushare-unit-test-secret-key-0123456789abcdef";
    private static final long ONE_HOUR = 3_600_000L;

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        ReflectionTestUtils.setField(jwtUtil, "secret", SECRET);
        ReflectionTestUtils.setField(jwtUtil, "expiration", ONE_HOUR);
    }

    @Test
    void generateToken_thenClaimsRoundTrip() {
        String token = jwtUtil.generateToken(42L, "wayne", "admin");

        assertEquals(42L, jwtUtil.getUserIdFromToken(token));
        assertEquals("wayne", jwtUtil.getUsernameFromToken(token));
        assertEquals("admin", jwtUtil.getRoleFromToken(token));
        assertTrue(jwtUtil.validateToken(token));
        assertFalse(jwtUtil.isTokenExpired(token));
    }

    @Test
    void validateToken_rejectsTamperedOrMalformedToken() {
        String token = jwtUtil.generateToken(1L, "student", "user");

        assertFalse(jwtUtil.validateToken(token + "x"));
        assertFalse(jwtUtil.validateToken("not-a-jwt"));
        assertFalse(jwtUtil.validateToken(""));
    }

    @Test
    void isTokenExpired_trueWhenExpirationAlreadyPassed() {
        ReflectionTestUtils.setField(jwtUtil, "expiration", -1_000L);

        String expired = jwtUtil.generateToken(7L, "expired", "user");

        assertTrue(jwtUtil.isTokenExpired(expired));
        assertFalse(jwtUtil.validateToken(expired));
    }
}
