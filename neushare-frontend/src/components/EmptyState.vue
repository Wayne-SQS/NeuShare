<template>
  <div class="empty-state">
    <div v-if="icon" class="empty-state__icon">
      <slot name="icon">
        <el-icon :size="28"><component :is="icon" /></el-icon>
      </slot>
    </div>
    <h3 class="empty-state__title">{{ title }}</h3>
    <p v-if="description || $slots.description" class="empty-state__desc">
      <slot name="description">{{ description }}</slot>
    </p>
    <div v-if="$slots.default" class="empty-state__actions">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, default: '暂无数据' },
  description: { type: String, default: '' },
  icon: { type: String, default: '' }
})
</script>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: var(--space-12) var(--space-4);
}

.empty-state__icon {
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius);
  background: var(--bg-hover);
  color: var(--text-muted);
  margin-bottom: var(--space-4);
}

.empty-state__title {
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}

.empty-state__desc {
  margin-top: var(--space-2);
  max-width: 360px;
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
}

.empty-state__actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  margin-top: var(--space-5);
}

@media (max-width: 767px) {
  .empty-state {
    padding: var(--space-10) var(--space-3);
  }
}
</style>
