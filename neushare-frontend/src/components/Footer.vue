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
  border-top: 1px solid var(--border-default);
  background: var(--bg-base);
  margin-top: auto;
}

.footer-container {
  max-width: var(--container-max);
  margin: 0 auto;
  padding: var(--space-9) var(--space-6) var(--space-7);
  display: flex;
  justify-content: space-between;
  gap: var(--space-10);
}

.footer-brand {
  max-width: 280px;
}

.footer-logo {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.logo-mark {
  width: 28px;
  height: 28px;
  border-radius: var(--radius-sm);
  background: var(--accent);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-inverse);
}

.logo-text {
  font-size: var(--text-lg);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.footer-desc {
  color: var(--text-muted);
  font-size: var(--text-sm);
  line-height: var(--leading-normal);
}

.footer-links {
  display: flex;
  gap: var(--space-10);
}

.link-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.link-title {
  color: var(--text-primary);
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  margin-bottom: var(--space-1);
  letter-spacing: 0.06em;
}

.link-group a {
  color: var(--text-secondary);
  font-size: var(--text-sm);
  transition: var(--transition-fast);
}

.link-group a:hover {
  color: var(--accent);
}

.footer-bottom {
  border-top: 1px solid var(--border-subtle);
  padding: var(--space-5) var(--space-6);
  text-align: center;
  color: var(--text-muted);
  font-size: var(--text-xs);
}

@media (max-width: 767px) {
  .footer-container {
    flex-direction: column;
    gap: var(--space-7);
    padding: var(--space-8) var(--space-4) var(--space-6);
  }

  .footer-links {
    gap: var(--space-10);
  }
}
</style>
