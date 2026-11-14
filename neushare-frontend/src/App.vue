<template>
  <div class="app-container">
    <Header />
    <main class="main-content">
      <router-view />
    </main>
    <Footer />
    <!-- 全局 AI 悬浮窗：登录后常驻，边看资料边问 AI，不打断当前页 -->
    <AiFloatingWindow />
  </div>
</template>

<script setup>
import Header from '@/components/Header.vue'
import Footer from '@/components/Footer.vue'
import AiFloatingWindow from '@/components/AiFloatingWindow.vue'
</script>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.main-content {
  flex: 1;
}
</style>
