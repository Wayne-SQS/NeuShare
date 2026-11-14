<template>
  <div class="profile-layout">
    <div class="container profile-container">
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
  padding: var(--section-gap-md) 0 var(--section-gap-lg);
}

.profile-container {
  display: flex;
  align-items: flex-start;
  gap: var(--space-6);
}

.profile-content {
  flex: 1;
  min-width: 0;
}

@media (max-width: 767px) {
  .profile-layout {
    padding: var(--space-5) 0 var(--section-gap-md);
  }

  .profile-container {
    flex-direction: column;
    gap: var(--space-4);
  }

  .profile-content {
    width: 100%;
  }
}
</style>
