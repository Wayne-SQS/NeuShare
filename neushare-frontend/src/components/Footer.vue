<template>
  <footer class="footer">
    <div class="footer-container">
      <div class="footer-brand">
        <div class="footer-logo">
          <div class="logo-mark">
            <el-icon :size="16"><Reading /></el-icon>
          </div>
          <span class="logo-text">NeuShare</span>
        </div>
        <p class="footer-desc">为东北大学学子打造的专属学习资料分享平台</p>
      </div>

      <div class="footer-links">
        <div class="link-group">
          <span class="link-title">导航</span>
          <router-link to="/">首页</router-link>
          <router-link to="/resource">资源广场</router-link>
          <router-link to="/upload">上传资料</router-link>
        </div>
        <div class="link-group">
          <span class="link-title">个人</span>
          <router-link to="/profile/info">个人中心</router-link>
          <router-link to="/profile/resources">我的资料</router-link>
          <router-link to="/profile/favorites">我的收藏</router-link>
        </div>
      </div>
    </div>

    <div class="footer-bottom">
      <span>&copy; {{ new Date().getFullYear() }} NeuShare. All rights reserved.</span>
    </div>
  </footer>
</template>

<script setup>
</script>

<style scoped>
.footer {
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-base);
  margin-top: auto;
}

.footer-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 48px 28px 36px;
  display: flex;
  justify-content: space-between;
  gap: 60px;
}

.footer-brand {
  max-width: 280px;
}

.footer-logo {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.logo-mark {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: linear-gradient(135deg, var(--accent), var(--accent-dim));
  display: flex;
  align-items: center;
  justify-content: center;
  color: #0d1117;
}

.logo-text {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.03em;
}

.footer-desc {
  color: var(--text-muted);
  font-size: 13px;
  line-height: 1.6;
}

.footer-links {
  display: flex;
  gap: 64px;
}

.link-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.link-title {
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 4px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.link-group a {
  color: var(--text-muted);
  font-size: 14px;
  transition: var(--transition-fast);
}

.link-group a:hover {
  color: var(--accent-light);
}

.footer-bottom {
  border-top: 1px solid var(--border-subtle);
  padding: 20px 28px;
  text-align: center;
  color: var(--text-muted);
  font-size: 13px;
}

@media (max-width: 640px) {
  .footer-container {
    flex-direction: column;
    gap: 32px;
  }
  .footer-links {
    gap: 40px;
  }
}
</style>
