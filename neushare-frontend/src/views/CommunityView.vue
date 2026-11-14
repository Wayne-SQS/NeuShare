<template>
  <div class="community-page container">
    <div class="page-head">
      <div class="page-head__text">
        <span class="breadcrumb">NeuShare / 学习社区</span>
        <h1 class="page-title">学习社区</h1>
        <p class="page-subtitle">分享课程笔记、考研经验，与同学交流讨论</p>
      </div>
      <div class="page-head__actions">
        <el-input
          v-model="keyword"
          placeholder="搜索帖子…"
          clearable
          style="width: 220px"
          @keyup.enter="reload"
          @clear="reload"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button v-if="userStore.isLoggedIn" type="primary" @click="router.push('/post/create')">
          <el-icon><EditPen /></el-icon> 发帖
        </el-button>
      </div>
    </div>

    <!-- 标签筛选 -->
    <div class="tag-bar">
      <button
        v-for="t in tags"
        :key="t"
        class="tag-chip"
        :class="{ active: activeTag === (t === '全部' ? '' : t) }"
        @click="pickTag(t)"
      >
        {{ t }}
      </button>
      <div class="sort-bar">
        <el-radio-group v-model="sortBy" size="small" @change="reload">
          <el-radio-button label="new">最新</el-radio-button>
          <el-radio-button label="hot">热门</el-radio-button>
        </el-radio-group>
      </div>
    </div>

    <div v-loading="loading" class="post-list">
      <div v-if="!loading && !posts.length" class="empty-tip">
        <EmptyState icon="ChatDotSquare" title="还没有帖子" description="来发布第一篇吧" />
      </div>

      <article
        v-for="p in posts"
        :key="p.id"
        class="post-card"
        @click="goDetail(p.id)"
      >
        <div class="post-card__main">
          <div class="post-card__title">
            <el-tag v-if="p.isRecommended" type="danger" size="small" effect="dark" class="rec-tag">精选</el-tag>
            <span>{{ p.title }}</span>
          </div>
          <p class="post-card__excerpt">{{ excerpt(p.content) }}</p>
          <div class="post-card__tags">
            <span v-for="t in parseTags(p.tags)" :key="t" class="mini-tag">{{ t }}</span>
          </div>
        </div>
        <div class="post-card__meta">
          <div class="author">
            <el-avatar :size="24" :src="p.authorAvatarUrl">{{ initials(p.authorNickname) }}</el-avatar>
            <span class="author-name">{{ p.authorNickname || '匿名' }}</span>
            <span v-if="p.authorCollege" class="author-college">{{ p.authorCollege }}</span>
          </div>
          <div class="counts">
            <span><el-icon><View /></el-icon>{{ p.viewCount || 0 }}</span>
            <span><el-icon><Star /></el-icon>{{ p.likeCount || 0 }}</span>
            <span><el-icon><ChatDotRound /></el-icon>{{ p.commentCount || 0 }}</span>
            <span class="time">{{ formatTime(p.createTime) }}</span>
          </div>
        </div>
      </article>
    </div>

    <div class="pager">
      <el-pagination
        v-if="pagination.total > 0"
        background
        :current-page="pagination.page"
        :page-size="pagination.size"
        :total="pagination.total"
        layout="total, prev, pager, next"
        @current-change="onPage"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import EmptyState from '@/components/EmptyState.vue'
import { getPostList } from '@/api/post'
import { useUserStore } from '@/store/modules/user'
import { formatTime, getInitial } from '@/utils/format'

const router = useRouter()
const userStore = useUserStore()

const tags = ['全部', '考研', '课程笔记', '求助', '经验分享', 'AI', '408', '保研']
const activeTag = ref('')
const keyword = ref('')
const sortBy = ref('new')
const posts = ref([])
const loading = ref(false)
const pagination = ref({ page: 1, size: 10, total: 0 })

function parseTags(raw) {
  if (!raw) return []
  try {
    const arr = JSON.parse(raw)
    return Array.isArray(arr) ? arr : []
  } catch (e) {
    return []
  }
}

function excerpt(content) {
  if (!content) return ''
  return String(content).replace(/[#*`>\-]/g, '').replace(/\s+/g, ' ').slice(0, 140)
}

function initials(name) {
  return getInitial(name || '匿')
}

function pickTag(t) {
  activeTag.value = t === '全部' ? '' : t
  pagination.value.page = 1
  reload()
}

function onPage(p) {
  pagination.value.page = p
  reload()
}

function goDetail(id) {
  router.push(`/post/${id}`)
}

async function reload() {
  loading.value = true
  try {
    const res = await getPostList({
      pageNum: pagination.value.page,
      pageSize: pagination.value.size,
      tag: activeTag.value || undefined,
      keyword: keyword.value.trim() || undefined,
      sortBy: sortBy.value
    })
    posts.value = res.data?.records || []
    pagination.value.total = res.data?.total || 0
  } catch (e) {
    ElMessage.error(e?.message || '加载帖子失败')
    posts.value = []
  } finally {
    loading.value = false
  }
}

onMounted(reload)
</script>

<style scoped>
.community-page {
  padding-top: var(--section-gap-md);
  padding-bottom: var(--section-gap-md);
}

.tag-bar {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  margin-bottom: var(--space-5);
}

.tag-chip {
  padding: var(--space-1) var(--space-3);
  border: 1px solid var(--border-default);
  background: var(--bg-surface);
  color: var(--text-secondary);
  border-radius: var(--radius-full);
  font-size: var(--text-sm);
  cursor: pointer;
  transition: var(--transition-fast);
  font-family: inherit;
}

.tag-chip:hover {
  border-color: var(--accent);
  color: var(--accent);
}

.tag-chip.active {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

.sort-bar {
  margin-left: auto;
}

.post-list {
  min-height: 300px;
}

.post-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-5);
  margin-bottom: var(--space-3);
  cursor: pointer;
  transition: var(--transition-fast);
}

.post-card:hover {
  border-color: var(--accent);
  box-shadow: var(--shadow);
  transform: translateY(-1px);
}

.post-card__title {
  font-size: var(--heading-3);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-2);
}

.rec-tag {
  flex-shrink: 0;
}

.post-card__excerpt {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  margin-bottom: var(--space-3);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.post-card__tags {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
  margin-bottom: var(--space-3);
}

.mini-tag {
  font-size: var(--text-xs);
  color: var(--accent);
  background: var(--info-bg);
  padding: 1px 8px;
  border-radius: var(--radius-xs);
}

.post-card__meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--space-2);
  padding-top: var(--space-3);
  border-top: 1px solid var(--border-subtle);
}

.author {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.author-name {
  font-size: var(--text-sm);
  color: var(--text-primary);
  font-weight: var(--font-medium);
}

.author-college {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.counts {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.counts span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.counts .time {
  color: var(--text-muted);
}

.pager {
  display: flex;
  justify-content: center;
  margin-top: var(--space-6);
}

.empty-tip {
  padding: var(--space-10) 0;
}

@media (max-width: 767px) {
  .page-head__actions {
    width: 100%;
  }
  .sort-bar {
    margin-left: 0;
    width: 100%;
  }
}
</style>
