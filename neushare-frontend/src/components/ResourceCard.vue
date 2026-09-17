<template>
  <div class="resource-card" @click="handleClick">
    <div class="card-accent"></div>
    <div class="card-body">
      <div class="card-header">
        <span class="category-tag">{{ resource.categoryName || '未分类' }}</span>
      </div>
      <h3 class="title" v-html="highlightedTitle"></h3>

      <!-- 结构化归属信息：既是结果可信度的信号，也是二次筛选的入口 -->
      <div class="structured-meta" v-if="structuredTags.length">
        <span
          v-for="tag in structuredTags"
          :key="tag.text"
          class="meta-chip"
          :title="`只看「${tag.text}」的资料`"
          @click.stop="router.push({ path: '/resource', query: tag.query })"
        >
          {{ tag.text }}
        </span>
      </div>

      <p class="description" v-html="highlightedDescription"></p>
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
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { formatTime, highlight, buildStructuredTags } from '@/utils/format'

const props = defineProps({
  resource: { type: Object, required: true },
  // 关键词，用于高亮命中词；列表页搜索时传入
  keyword: { type: String, default: '' }
})

const router = useRouter()

const handleClick = () => {
  router.push(`/resource/${props.resource.id}`)
}

const highlightedTitle = computed(() => highlight(props.resource.title, props.keyword))

const highlightedDescription = computed(() =>
  highlight(props.resource.description || '暂无描述', props.keyword)
)

// 课程 / 教师 / 学年学期：有值才展示，避免卡片里出现一堆"未填写"
const structuredTags = computed(() => buildStructuredTags(props.resource))
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
  background: rgba(37, 99, 235, 0.08);
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

.structured-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 10px;
}

.meta-chip {
  font-size: 11px;
  color: var(--text-secondary);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  padding: 2px 8px;
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: var(--transition);
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.meta-chip:hover {
  color: var(--accent);
  border-color: var(--border-accent);
}

/* 搜索结果高亮：不用纯黄底，和靛蓝/极简双主题都能搭 */
:deep(mark.hl) {
  background: rgba(37, 99, 235, 0.16);
  color: var(--accent);
  padding: 0 1px;
  border-radius: 2px;
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

.uploader-link {
  color: var(--text-muted);
  text-decoration: none;
  font-size: 12px;
}

.uploader-link:hover {
  color: var(--accent);
}
</style>
