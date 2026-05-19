<template>
  <div class="resource-card" @click="handleClick">
    <div class="card-accent"></div>
    <div class="card-body">
      <div class="card-header">
        <span class="category-tag">{{ resource.categoryName || '未分类' }}</span>
      </div>
      <h3 class="title">{{ resource.title }}</h3>
      <p class="description">{{ resource.description || '暂无描述' }}</p>
      <div class="card-meta">
        <div class="meta-item">
          <el-icon><User /></el-icon>
          <span>{{ resource.uploadNickname || '匿名' }}</span>
        </div>
        <div class="meta-item">
          <el-icon><View /></el-icon>
          <span>{{ resource.viewCount || 0 }}</span>
        </div>
        <div class="meta-item">
          <el-icon><Star /></el-icon>
          <span>{{ resource.likeCount || 0 }}</span>
        </div>
      </div>
      <div class="card-footer">
        <span class="time">{{ formatTime(resource.createTime) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { formatTime } from '@/utils/format'

const props = defineProps({
  resource: { type: Object, required: true }
})

const router = useRouter()

const handleClick = () => {
  router.push(`/resource/${props.resource.id}`)
}
</script>

<style scoped>
.resource-card {
  position: relative;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius);
  cursor: pointer;
  overflow: hidden;
  transition: var(--transition);
}

.resource-card:hover {
  border-color: var(--border-accent);
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.resource-card:hover .card-accent {
  opacity: 1;
}

.card-accent {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, var(--accent), transparent);
  opacity: 0;
  transition: opacity var(--transition);
}

.card-body {
  padding: 20px;
}

.card-header {
  margin-bottom: 10px;
}

.category-tag {
  font-size: 11px;
  font-weight: 600;
  color: var(--accent);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  background: rgba(200, 164, 78, 0.1);
  padding: 3px 8px;
  border-radius: var(--radius-xs);
}

.title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  letter-spacing: -0.01em;
}

.description {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.55;
  height: 40px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  margin-bottom: 14px;
}

.card-meta {
  display: flex;
  gap: 16px;
  margin-bottom: 12px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--text-muted);
}

.card-footer {
  padding-top: 12px;
  border-top: 1px solid var(--border-subtle);
}

.time {
  font-size: 12px;
  color: var(--text-muted);
}
</style>
