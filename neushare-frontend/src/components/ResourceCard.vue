<template>
  <div class="resource-card" @click="handleClick">
    <div class="card-cover">
      <img
        v-if="coverUrl && !coverBroken"
        :src="coverUrl"
        :alt="resource.title"
        class="cover-img"
        loading="lazy"
        @error="coverBroken = true"
      />
      <div v-else class="cover-fallback">
        <el-icon class="cover-icon"><Picture /></el-icon>
        <span class="cover-text">{{ resource.categoryName || 'NeuShare' }}</span>
      </div>
    </div>
    <div class="card-body">
      <div class="card-header">
        <span class="category-tag">{{ resource.categoryName || '未分类' }}</span>
        <span v-if="resource.courseName" class="course-tag">{{ resource.courseName }}</span>
      </div>
      <h3 class="title" v-html="highlightedTitle"></h3>
      <div v-if="structuredTags.length" class="structured-meta">
        <span
          v-for="tag in structuredTags"
          :key="tag.text"
          class="meta-chip"
          :title="`只看「${tag.text}」的资料`"
          @click.stop="router.push({ path: '/resource', query: tag.query })"
        >{{ tag.text }}</span>
      </div>
      <p class="description">{{ resource.description || '暂无描述' }}</p>
      <div class="card-meta">
        <div class="meta-item">
          <el-icon><User /></el-icon>
          <router-link
            :to="`/user/${resource.uploadUserId}`"
            @click.stop
            class="uploader-link"
          >
            {{ resource.uploadNickname || '匿名' }}
          </router-link>
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
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { formatTime, buildStructuredTags, highlight } from '@/utils/format'

const props = defineProps({
  resource: { type: Object, required: true },
  keyword: { type: String, default: '' }
})

const router = useRouter()

const coverBroken = ref(false)
const coverUrl = computed(() => props.resource.coverUrl || '')

// 命中词高亮：format.js 里先 escapeHtml 再插 <mark>，不会开 XSS 口子
const highlightedTitle = computed(() => highlight(props.resource.title, props.keyword))
// 课程 / 教师 / 学年学期：有值才展示，点击带 query 二次筛选
const structuredTags = computed(() => buildStructuredTags(props.resource))

const handleClick = () => {
  router.push(`/resource/${props.resource.id}`)
}
</script>

<style scoped>
.resource-card {
  position: relative;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  cursor: pointer;
  overflow: hidden;
  transition: border-color var(--transition), box-shadow var(--transition);
}

.resource-card:hover {
  border-color: var(--border-strong);
  box-shadow: var(--shadow-sm);
}

.card-cover {
  width: 100%;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background: var(--bg-hover);
  flex-shrink: 0;
}

.cover-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  transition: transform var(--transition-slow);
}

.resource-card:hover .cover-img {
  transform: scale(1.04);
}

.cover-fallback {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  color: #fff;
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
}

.cover-icon {
  font-size: 28px;
  opacity: 0.9;
}

.cover-text {
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  opacity: 0.95;
}

.card-body {
  padding: var(--space-5);
  display: flex;
  flex-direction: column;
  height: 100%;
}

.card-header {
  margin-bottom: var(--space-3);
}

.category-tag {
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  color: var(--text-secondary);
  background: var(--bg-hover);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-xs);
}

.title {
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin-bottom: var(--space-2);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  letter-spacing: -0.01em;
}

.description {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  height: calc(var(--text-sm) * 1.65 * 2);
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  margin-bottom: var(--space-4);
}

.card-meta {
  display: flex;
  gap: var(--space-4);
  margin-bottom: var(--space-3);
  min-width: 0;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  color: var(--text-muted);
  min-width: 0;
}

.meta-item:first-child {
  flex: 1;
  overflow: hidden;
}

.card-footer {
  margin-top: auto;
  padding-top: var(--space-3);
  border-top: 1px solid var(--border-subtle);
}

.time {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.uploader-link {
  color: var(--text-muted);
  font-size: var(--text-xs);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.uploader-link:hover {
  color: var(--accent);
}

.course-tag {
  font-size: 11px;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.structured-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin: 2px 0 8px;
}

.meta-chip {
  font-size: 11px;
  color: var(--text-secondary);
  background: var(--bg-hover);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  padding: 2px 8px;
  cursor: pointer;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.meta-chip:hover {
  color: var(--accent);
  border-color: var(--accent);
}

:deep(mark.hl) {
  background: var(--bg-hover);
  color: var(--accent);
  padding: 0 1px;
  border-radius: 2px;
}

</style>
