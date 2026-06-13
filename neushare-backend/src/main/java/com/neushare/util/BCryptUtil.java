package com.neushare.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * BCrypt 密码工具类（原 Md5Util，已重命名）
 */
public class BCryptUtil {

    private static final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public static String encrypt(String password) {
        return encoder.encode(password);
    }

    public static boolean verify(String password, String encryptedPassword) {
        return encoder.matches(password, encryptedPassword);
    }
}
