<template>
  <div :class="['skeleton-card', `skeleton-card--${variant}`]" aria-busy="true" aria-live="polite">
    <template v-if="variant === 'card'">
      <div class="skeleton skeleton-line skeleton-line--sm tag"></div>
      <div class="skeleton skeleton-line title"></div>
      <div v-for="row in rows" :key="`card-${row}`" class="skeleton skeleton-line text"></div>
      <div class="skeleton-card__footer">
        <div class="skeleton skeleton-line skeleton-line--sm footer-left"></div>
        <div class="skeleton skeleton-line skeleton-line--sm footer-right"></div>
      </div>
    </template>

    <template v-else-if="variant === 'list'">
      <div class="skeleton skeleton-block avatar"></div>
      <div class="skeleton-card__body">
        <div class="skeleton skeleton-line title"></div>
        <div v-for="row in rows" :key="`list-${row}`" class="skeleton skeleton-line text"></div>
      </div>
    </template>

    <template v-else>
      <div class="skeleton skeleton-line skeleton-line--sm eyebrow"></div>
      <div class="skeleton skeleton-line heading"></div>
      <div class="skeleton-card__meta">
        <div v-for="row in rows" :key="`detail-${row}`" class="skeleton skeleton-line skeleton-line--sm meta-item"></div>
      </div>
      <div class="skeleton-card__divider"></div>
      <div v-for="row in rows + 2" :key="`detail-text-${row}`" class="skeleton skeleton-line text"></div>
    </template>
  </div>
</template>

<script setup>
defineProps({
  rows: { type: Number, default: 3 },
  variant: {
    type: String,
    default: 'card',
    validator: (value) => ['card', 'list', 'detail'].includes(value)
  }
})
</script>

<style scoped>
.skeleton-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-5);
}

.skeleton-card--detail {
  padding: var(--space-7);
}

.skeleton-card__body {
  flex: 1;
  min-width: 0;
}

.tag {
  width: 56px;
  margin-bottom: var(--space-4);
}

.title {
  width: 72%;
  height: var(--space-4);
  margin-bottom: var(--space-4);
}

.text {
  width: 100%;
  margin-bottom: var(--space-2);
}

.text:nth-last-child(2) {
  width: 64%;
}

.skeleton-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  margin-top: var(--space-5);
  padding-top: var(--space-3);
  border-top: 1px solid var(--border-subtle);
}

.footer-left {
  width: 40%;
}

.footer-right {
  width: 24%;
}

.skeleton-card--list {
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
}

.avatar {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-sm);
  flex-shrink: 0;
}

.skeleton-card--detail .eyebrow {
  width: 80px;
  margin-bottom: var(--space-4);
}

.heading {
  width: 60%;
  height: var(--space-6);
  margin-bottom: var(--space-4);
}

.skeleton-card__meta {
  display: flex;
  gap: var(--space-4);
  flex-wrap: wrap;
}

.meta-item {
  width: 88px;
}

.skeleton-card__divider {
  height: 1px;
  background: var(--border-subtle);
  margin: var(--space-5) 0;
}
</style>
