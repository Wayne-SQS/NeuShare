<template>
  <div class="profile-layout">
    <div class="profile-container">
      <Sidebar />
      <div class="profile-content">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script setup>
import Sidebar from '@/components/Sidebar.vue'
</script>

<style scoped>
.profile-layout {
  min-height: 100%;
  padding: 28px 0;
}

.profile-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 28px;
  display: flex;
  gap: 24px;
}

.profile-content {
  flex: 1;
  min-width: 0;
}
</style>
