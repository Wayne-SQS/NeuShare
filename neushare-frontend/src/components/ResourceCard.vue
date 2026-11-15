<template>
  <article class="resource-card" :class="`resource-card--tone-${tone}`" @click="handleClick">
    <div class="card-cover">
      <div class="card-cover__sheen"></div>
      <el-icon :size="40" class="card-cover__icon">
        <Document v-if="tone === 1" />
        <Collection v-else-if="tone === 2" />
        <Reading v-else-if="tone === 3" />
        <DataAnalysis v-else />
      </el-icon>
      <span class="card-cover__corner">{{ String(resource.id || '').slice(-2).padStart(2, '0') }}</span>
    </div>
    <div class="card-body">
      <div class="card-tags">
        <span class="card-tag">{{ resource.categoryName || '未分类' }}</span>
        <span v-if="resource.courseName" class="card-course">{{ resource.courseName }}</span>
      </div>
      <h3 class="card-title">{{ resource.title }}</h3>
      <div class="card-meta">
        <span class="card-author">{{ resource.uploadNickname || '匿名' }}</span>
        <span class="card-dot">·</span>
        <span>{{ resource.viewCount || 0 }} 浏览</span>
        <span class="card-dot">·</span>
        <span>{{ resource.favoriteCount ?? resource.likeCount ?? 0 }} 收藏</span>
      </div>
    </div>
  </article>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'

const props = defineProps({
  resource: { type: Object, required: true }
})

const router = useRouter()

// 四色渐变按 id 轮转；深色主题下由 theme-v3.css 统一翻成灰阶
const tone = computed(() => ((Number(props.resource.id) || 0) % 4) + 1)

const handleClick = () => {
  router.push(`/resource/${props.resource.id}`)
}
</script>

<style scoped>
.resource-card {
  display: flex;
  flex-direction: column;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius);
  overflow: hidden;
  cursor: pointer;
  transition: var(--transition);
}

.resource-card:hover {
  border-color: var(--border-accent);
  box-shadow: var(--shadow-md);
  transform: translateY(-3px);
}

.card-cover {
  position: relative;
  height: 118px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  overflow: hidden;
}

.resource-card--tone-1 .card-cover { background: var(--grad-card-1); }
.resource-card--tone-2 .card-cover { background: var(--grad-card-2); }
.resource-card--tone-3 .card-cover { background: var(--grad-card-3); }
.resource-card--tone-4 .card-cover { background: var(--grad-card-4); }

.card-cover__sheen {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(var(--surface-rgb), 0.16) 0%, transparent 70%);
}

.card-cover__icon {
  position: relative;
  color: var(--card-glyph);
  opacity: 0.92;
}

.card-cover__corner {
  position: absolute;
  top: 12px;
  right: 14px;
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 0.08em;
  color: var(--card-glyph);
  opacity: 0.6;
}

.card-body {
  padding: 16px 18px 18px;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.card-tags {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 9px;
  min-height: 20px;
}

.card-tag {
  font-size: 11px;
  font-weight: 600;
  color: var(--accent);
  background: rgba(var(--accent-rgb), 0.10);
  padding: 3px 9px;
  border-radius: var(--radius-full);
}

.card-course {
  font-size: 11px;
  color: var(--text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-title {
  font-size: 14px;
  font-weight: 600;
  line-height: 1.5;
  color: var(--text-primary);
  margin: 0 0 12px;
  min-height: 42px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: auto;
  font-size: 12px;
  color: var(--text-muted);
}

.card-author {
  color: var(--text-secondary);
  max-width: 88px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-dot {
  opacity: 0.6;
}
</style>
