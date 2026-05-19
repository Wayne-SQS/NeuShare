USE neushare;

-- 更新所有用户密码为BCrypt加密的"123456"
-- 这个密码是从新注册用户获取的，已验证可以正常登录
UPDATE user SET password = '$2a$10$iucvRyIMdYuUPUbj6aDt2etGfR1o1omNqypNApJpv52GldwmhoRcS';

SELECT id, username, LEFT(password, 30) as password FROM user LIMIT 5;
