USE neushare;

-- BCrypt加密后的密码 "123456"
-- 使用Spring的BCryptPasswordEncoder生成的密码
UPDATE user SET password = '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKlF1M6K';

SELECT id, username, password FROM user LIMIT 3;
