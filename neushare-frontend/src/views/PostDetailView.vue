<template>
  <div class="post-detail container container--narrow">
    <el-button link class="back-btn" @click="router.back()">
      <el-icon><ArrowLeft /></el-icon> 返回
    </el-button>

    <div v-if="loading" class="state-panel">
      <SkeletonCard variant="detail" :rows="4" />
    </div>

    <div v-else-if="!post" class="state-panel">
      <EmptyState icon="DocumentDelete" title="帖子不存在或已被删除" />
    </div>

    <template v-else>
      <article class="post-article panel">
        <h1 class="post-title">{{ post.title }}</h1>
        <div class="post-meta">
          <div class="author-row">
            <el-avatar :size="32" :src="post.authorAvatarUrl">{{ initials }}</el-avatar>
            <div class="author-info">
              <span class="author-name">{{ post.authorNickname || '匿名' }}</span>
              <span class="author-college" v-if="post.authorCollege">{{ post.authorCollege }}</span>
            </div>
          </div>
          <div class="post-counts">
            <span><el-icon><View /></el-icon>{{ post.viewCount || 0 }} 浏览</span>
            <span><el-icon><Star /></el-icon>{{ post.likeCount || 0 }} 点赞</span>
            <span><el-icon><ChatDotRound /></el-icon>{{ post.commentCount || 0 }} 评论</span>
            <span class="time">{{ formatTime(post.createTime) }}</span>
          </div>
        </div>

        <div v-if="tags.length" class="post-tags">
          <span v-for="t in tags" :key="t" class="tag">{{ t }}</span>
        </div>

        <div v-if="images.length" class="post-images">
          <img
            v-for="(img, i) in images"
            :key="i"
            :src="buildFullUrl(img)"
            class="post-img"
            @error="onImgError($event)"
          />
        </div>

        <div class="post-content">{{ post.content }}</div>
      </article>

      <section class="comments panel">
        <h3 class="section-title">评论 ({{ totalComments }})</h3>

        <div class="comment-form">
          <template v-if="userStore.isLoggedIn">
            <div v-if="replyingTo" class="reply-tip">
              回复 @{{ replyingTo.nickname }}
              <el-button link type="primary" size="small" @click="replyingTo = null">取消</el-button>
            </div>
            <el-input
              v-model="commentText"
              type="textarea"
              :rows="3"
              :placeholder="replyingTo ? '写下你的回复…' : '写下你的评论…'"
              resize="none"
            />
            <div class="comment-form__actions">
              <el-button type="primary" :loading="submitting" @click="submitComment">发表</el-button>
            </div>
          </template>
          <div v-else class="login-tip">
            <router-link :to="{ path: '/login', query: { redirect: $route.fullPath } }">登录</router-link>
            后参与评论
          </div>
        </div>

        <div v-if="commentsLoading" class="comments-loading">加载评论中…</div>
        <div v-else-if="!comments.length" class="comments-empty">还没有评论，来说两句吧</div>
        <div v-else class="comment-list">
          <CommentItem
            v-for="c in comments"
            :key="c.id"
            :comment="c"
            @reply="onReply"
          />
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import CommentItem from '@/components/CommentItem.vue'
import { getPostDetail, getPostComments, addPostComment } from '@/api/post'
import { useUserStore } from '@/store/modules/user'
import { formatTime, getInitial } from '@/utils/format'
import { buildFullUrl } from '@/utils/url'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const loading = ref(true)
const commentsLoading = ref(false)
const submitting = ref(false)
const post = ref(null)
const comments = ref([])
const commentText = ref('')
const replyingTo = ref(null)

const tags = computed(() => parseArr(post.value?.tags))
const images = computed(() => parseArr(post.value?.imageUrls))
const initials = computed(() => getInitial(post.value?.authorNickname || '匿'))

const totalComments = computed(() => {
  let n = 0
  const walk = (list) => list.forEach((c) => { n++; if (c.children) walk(c.children) })
  walk(comments.value)
  return n
})

function parseArr(raw) {
  if (!raw) return []
  try {
    const a = JSON.parse(raw)
    return Array.isArray(a) ? a : []
  } catch (e) {
    return []
  }
}

function onImgError(e) {
  e.target.style.display = 'none'
}

async function fetchPost() {
  loading.value = true
  try {
    const res = await getPostDetail(route.params.id)
    post.value = res.data
  } catch (e) {
    ElMessage.error(e?.message || '加载失败')
    post.value = null
  } finally {
    loading.value = false
  }
}

async function fetchComments() {
  commentsLoading.value = true
  try {
    const res = await getPostComments(route.params.id)
    comments.value = res.data || []
  } catch (e) {
    comments.value = []
  } finally {
    commentsLoading.value = false
  }
}

function onReply(c) {
  replyingTo.value = c
}

async function submitComment() {
  const content = commentText.value.trim()
  if (!content) return
  submitting.value = true
  try {
    await addPostComment(route.params.id, content, replyingTo.value?.id)
    ElMessage.success('评论成功')
    commentText.value = ''
    replyingTo.value = null
    fetchComments()
  } catch (e) {
    ElMessage.error(e?.message || '评论失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchPost()
  fetchComments()
})
</script>

<style scoped>
.post-detail {
  padding-top: var(--section-gap-md);
  padding-bottom: var(--section-gap-md);
}

.back-btn {
  margin-bottom: var(--space-4);
  padding-left: 0;
}

.post-article {
  margin-bottom: var(--space-5);
}

.post-title {
  font-size: var(--heading-1);
  font-weight: var(--font-bold);
  margin-bottom: var(--space-4);
  line-height: 1.3;
}

.post-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--space-3);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
  margin-bottom: var(--space-4);
}

.author-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.author-info {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.author-name {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--text-primary);
}

.author-college {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.post-counts {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  font-size: var(--text-xs);
  color: var(--text-muted);
  flex-wrap: wrap;
}

.post-counts span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.post-tags {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
  margin-bottom: var(--space-4);
}

.tag {
  font-size: var(--text-xs);
  color: var(--accent);
  background: var(--info-bg);
  padding: 2px 10px;
  border-radius: var(--radius-xs);
}

.post-images {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
}

.post-img {
  max-width: 100%;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-subtle);
}

.post-content {
  font-size: var(--text-base);
  color: var(--text-primary);
  line-height: var(--leading-relaxed);
  white-space: pre-wrap;
  word-break: break-word;
}

.section-title {
  font-size: var(--heading-3);
  font-weight: var(--font-semibold);
  margin-bottom: var(--space-4);
}

.comment-form {
  margin-bottom: var(--space-5);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.reply-tip {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin-bottom: var(--space-2);
}

.comment-form__actions {
  margin-top: var(--space-2);
  display: flex;
  justify-content: flex-end;
}

.login-tip {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  padding: var(--space-3);
  text-align: center;
  background: var(--bg-deep);
  border-radius: var(--radius-sm);
}

.comments-loading,
.comments-empty {
  text-align: center;
  color: var(--text-muted);
  font-size: var(--text-sm);
  padding: var(--space-6) 0;
}
</style>
