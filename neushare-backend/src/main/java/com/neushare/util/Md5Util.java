package com.neushare.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class Md5Util {

    private static final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public static String encrypt(String password) {
        return encoder.encode(password);
    }

    public static boolean verify(String password, String encryptedPassword) {
        return encoder.matches(password, encryptedPassword);
    }
}
