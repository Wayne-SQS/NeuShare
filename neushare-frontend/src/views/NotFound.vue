<template>
  <div class="not-found-page">
    <div class="not-found-content">
      <span class="error-code">404</span>
      <h1 class="error-title">页面不存在</h1>
      <p class="error-desc">抱歉，您访问的页面不存在或已被移除</p>
      <div class="error-actions">
        <el-button type="primary" @click="$router.push('/')">返回首页</el-button>
        <el-button @click="$router.back()">返回上页</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>

<style scoped>
.not-found-page {
  min-height: calc(100vh - var(--header-height));
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-10) var(--space-4);
  background: var(--bg-base);
}

.not-found-content {
  text-align: center;
  max-width: 420px;
}

.error-code {
  display: block;
  font-size: var(--text-mega);
  font-weight: var(--font-bold);
  color: var(--border-subtle);
  line-height: 1;
  margin-bottom: var(--space-4);
  letter-spacing: -0.04em;
}

.error-title {
  font-size: var(--heading-1);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  margin-bottom: var(--space-2);
}

.error-desc {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin-bottom: var(--space-7);
}

.error-actions {
  display: flex;
  gap: var(--space-3);
  justify-content: center;
}

@media (max-width: 767px) {
  .error-code {
    font-size: calc(var(--text-mega) * 0.75);
  }

  .error-actions {
    flex-direction: column;
  }

  .error-actions .el-button {
    width: 100%;
    margin-left: 0;
  }
}
</style>
