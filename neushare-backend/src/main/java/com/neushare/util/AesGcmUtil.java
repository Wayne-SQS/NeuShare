package com.neushare.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * AES-256-GCM 加解密工具：用于用户自带 AI API Key 的落库加密。
 *
 * 存储格式：Base64( 12字节随机nonce + 密文 + 16字节GCM认证标签 )
 * 主密钥：不直接用配置原文，先 SHA-256 派生成 256 位 key，长短无所谓。
 *
 * 约束：主密钥来自 ai.key-encrypt-secret，换密钥等于全部密文作废，
 * 生产环境必须改默认值，且换密钥前要全量重加密。
 */
@Component
public class AesGcmUtil {

    private static final int NONCE_LEN = 12;
    private static final int TAG_BITS = 128;

    private final SecretKey key;
    private final SecureRandom random = new SecureRandom();

    public AesGcmUtil(@Value("${ai.key-encrypt-secret}") String secret) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(secret.getBytes(StandardCharsets.UTF_8));
            this.key = new SecretKeySpec(digest, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("初始化 AES 主密钥失败", e);
        }
    }

    /** 明文 → Base64 密文。 */
    public String encrypt(String plain) {
        try {
            byte[] nonce = new byte[NONCE_LEN];
            random.nextBytes(nonce);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, nonce));
            byte[] encrypted = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = new byte[NONCE_LEN + encrypted.length];
            System.arraycopy(nonce, 0, out, 0, NONCE_LEN);
            System.arraycopy(encrypted, 0, out, NONCE_LEN, encrypted.length);
            return Base64.getEncoder().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("加密失败", e);
        }
    }

    /** Base64 密文 → 明文。密文损坏或密钥不匹配会抛异常。 */
    public String decrypt(String encoded) {
        try {
            byte[] all = Base64.getDecoder().decode(encoded);
            if (all.length <= NONCE_LEN) {
                throw new IllegalArgumentException("密文长度异常");
            }
            byte[] nonce = new byte[NONCE_LEN];
            System.arraycopy(all, 0, nonce, 0, NONCE_LEN);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, nonce));
            byte[] plain = cipher.doFinal(all, NONCE_LEN, all.length - NONCE_LEN);
            return new String(plain, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("解密失败（密钥是否更换过？）", e);
        }
    }
}
