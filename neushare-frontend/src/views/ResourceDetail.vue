<template>
  <div class="resource-detail-page">
    <div class="container container--narrow">
      <div v-if="loading" class="detail-skeleton">
        <SkeletonCard variant="detail" :rows="3" />
        <SkeletonCard variant="detail" :rows="4" />
      </div>

      <div v-else-if="!resource" class="state-panel">
        <EmptyState
          icon="DocumentDelete"
          title="资料不存在或已下架"
          description="该资料可能已被删除，或链接地址有误"
        >
          <el-button type="primary" @click="$router.push('/resource')">返回资源广场</el-button>
        </EmptyState>
      </div>

      <template v-else>
        <header class="resource-header">
          <div class="resource-info">
            <div class="header-top">
              <el-tag class="category-tag" size="small" effect="plain">
                {{ resource.categoryName || '未分类' }}
              </el-tag>
              <span class="upload-time">{{ formatTime(resource.createTime) }}</span>
            </div>
            <h1 class="title">{{ resource.title }}</h1>
            <div class="meta">
              <router-link :to="`/user/${resource.uploadUserId}`" class="uploader">
                <el-icon><User /></el-icon>
                <span>{{ resource.uploadNickname || '匿名' }}</span>
              </router-link>
              <span class="meta-item">
                <el-icon><View /></el-icon>
                <span>{{ resource.viewCount || 0 }} 次浏览</span>
              </span>
              <span class="meta-item">
                <el-icon><Star /></el-icon>
                <span>{{ resource.favoriteCount || 0 }} 次收藏</span>
              </span>
            </div>
          </div>

          <div class="resource-actions">
            <el-button
              :class="['action-btn', { 'action-btn--active': isLiked }]"
              @click="handleLike"
            >
              <el-icon><StarFilled v-if="isLiked" /><Star v-else /></el-icon>
              <span>{{ resource.likeCount || 0 }}</span>
            </el-button>
            <el-button
              :class="['action-btn', { 'action-btn--active': isFavorited }]"
              @click="handleFavorite"
            >
              <el-icon><CollectionTag v-if="isFavorited" /><Collection v-else /></el-icon>
              <span>{{ isFavorited ? '已收藏' : '收藏' }}</span>
            </el-button>
          </div>
        </header>

        <section class="content-card">
          <h3 class="card-label">资料描述</h3>
          <p class="description">{{ resource.description || '暂无描述' }}</p>
          <div v-if="resource.contentUrl" class="file-info">
            <el-icon><Document /></el-icon>
            <span>{{ resource.contentUrl }}</span>
          </div>
        </section>

        <section class="comment-card">
          <div class="comment-head">
            <h3 class="card-label">评论</h3>
            <span class="comment-count">{{ totalComments }}</span>
          </div>

          <div v-if="userStore.isLoggedIn" class="comment-form">
            <el-input
              v-model="commentForm.content"
              type="textarea"
              :rows="3"
              placeholder="写下你的评论..."
              maxlength="500"
              show-word-limit
            />
            <div class="comment-form__actions">
              <el-button type="primary" :loading="submitting" @click="submitComment">
                发表评论
              </el-button>
            </div>
          </div>
          <div v-else class="login-tip">
            <router-link to="/login">登录</router-link> 后参与评论
          </div>

          <div class="comment-list">
            <div v-for="comment in comments" :key="comment.id" class="comment-item">
              <div v-if="!comment.deleted" class="comment-avatar">
                <el-avatar :size="36" :src="comment.avatarUrl">
                  {{ getInitial(comment.nickname) }}
                </el-avatar>
              </div>
              <div class="comment-content">
                <template v-if="comment.deleted">
                  <div class="comment-deleted">该评论已被删除</div>
                </template>
                <template v-else>
                  <div class="comment-header">
                    <span class="username">{{ comment.nickname }}</span>
                    <span class="time">{{ formatTime(comment.createTime) }}</span>
                  </div>
                  <div class="comment-text">{{ comment.content }}</div>
                </template>
                <div v-if="comment.children && comment.children.length > 0" class="comment-replies">
                  <div v-for="reply in comment.children" :key="reply.id" class="reply-item">
                    <el-avatar v-if="!reply.deleted" :size="24" :src="reply.avatarUrl">
                      {{ getInitial(reply.nickname) }}
                    </el-avatar>
                    <div class="reply-content">
                      <template v-if="reply.deleted">
                        <span class="reply-deleted">该评论已被删除</span>
                      </template>
                      <template v-else>
                        <span class="reply-nickname">{{ reply.nickname }}</span>
                        <span class="reply-text">{{ reply.content }}</span>
                        <span class="reply-time">{{ formatTime(reply.createTime) }}</span>
                      </template>
                    </div>
                  </div>
                </div>
                <div v-if="userStore.isLoggedIn && !comment.deleted" class="comment-actions">
                  <el-button type="primary" link size="small" @click="handleReply(comment)">回复</el-button>
                </div>
              </div>
            </div>

            <EmptyState
              v-if="comments.length === 0"
              icon="ChatDotRound"
              title="暂无评论"
              description="成为第一个留下学习心得的人"
            />
          </div>
        </section>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/modules/user'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getResourceDetail, likeResource, unlikeResource, checkLiked } from '@/api/resource'
import { getComments, addComment } from '@/api/comment'
import { addFavorite, removeFavorite, checkFavorite } from '@/api/favorite'
import { formatTime, getInitial } from '@/utils/format'

const route = useRoute()
const userStore = useUserStore()

const loading = ref(true)
const resource = ref(null)
const comments = ref([])
const isLiked = ref(false)
const isFavorited = ref(false)
const submitting = ref(false)
const replyingTo = ref(null)

const commentForm = reactive({
  content: ''
})

const resourceId = computed(() => route.params.id)

const totalComments = computed(() => {
  let count = 0
  comments.value.forEach(c => {
    count++
    if (c.children) count += c.children.length
  })
  return count
})

const fetchResource = async () => {
  try {
    const res = await getResourceDetail(resourceId.value)
    resource.value = res.data
    // 在获取资源详情成功后检查点赞状态
    if (userStore.token) {
      try {
        const likeRes = await checkLiked(resourceId.value)
        if (likeRes.code === 200) {
          isLiked.value = likeRes.data
        }
      } catch (e) {
        // 未登录或接口报错，忽略
      }
    }
  } catch (error) {
    console.error('Failed to fetch resource:', error)
    resource.value = null
  }
}

const fetchComments = async () => {
  try {
    const res = await getComments(resourceId.value)
    comments.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch comments:', error)
  }
}

const checkFavoriteStatus = async () => {
  if (!userStore.isLoggedIn) return
  try {
    const res = await checkFavorite(resourceId.value)
    isFavorited.value = res.data?.isFavorite || false
  } catch (error) {
    console.error('Failed to check favorite:', error)
  }
}

const loadAllData = async () => {
  loading.value = true
  isLiked.value = false
  isFavorited.value = false
  await Promise.all([
    fetchResource(),
    fetchComments(),
    checkFavoriteStatus()
  ])
  loading.value = false
}

watch(resourceId, () => {
  loadAllData()
})

const handleLike = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  try {
    if (isLiked.value) {
      await unlikeResource(resourceId.value)
      resource.value.likeCount = (resource.value.likeCount || 0) - 1
      ElMessage.success('取消点赞')
    } else {
      await likeResource(resourceId.value)
      resource.value.likeCount = (resource.value.likeCount || 0) + 1
      ElMessage.success('点赞成功')
    }
    isLiked.value = !isLiked.value
  } catch (error) {
    console.error('Failed to like:', error)
  }
}

const handleFavorite = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  try {
    if (isFavorited.value) {
      await removeFavorite(resourceId.value)
      ElMessage.success('已取消收藏')
    } else {
      await addFavorite(resourceId.value)
      ElMessage.success('收藏成功')
    }
    isFavorited.value = !isFavorited.value
  } catch (error) {
    console.error('Failed to favorite:', error)
  }
}

const handleReply = (comment) => {
  replyingTo.value = comment
  commentForm.content = `@${comment.nickname} `
}

const submitComment = async () => {
  if (!commentForm.content.trim()) {
    ElMessage.warning('请输入评论内容')
    return
  }
  submitting.value = true
  try {
    const parentId = replyingTo.value ? replyingTo.value.id : null
    await addComment(resourceId.value, commentForm.content, parentId)
    ElMessage.success('评论成功')
    commentForm.content = ''
    replyingTo.value = null
    fetchComments()
  } catch (error) {
    console.error('Failed to submit comment:', error)
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  await loadAllData()
})
</script>

<style scoped>
.resource-detail-page {
  padding: var(--section-gap-md) 0 var(--section-gap-lg);
}

.container--narrow {
  max-width: var(--container-narrow);
}

.detail-skeleton {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.state-panel {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
}

/* Header: 标题 / 作者统计 / 操作 */
.resource-header {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-7);
  margin-bottom: var(--space-4);
}

.header-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  margin-bottom: var(--space-3);
}

.category-tag {
  color: var(--text-secondary);
  border-color: var(--border-default);
  background: var(--bg-deep);
}

.upload-time {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.title {
  font-size: var(--heading-1);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  margin-bottom: var(--space-4);
  letter-spacing: -0.02em;
  line-height: 1.3;
}

.meta {
  display: flex;
  align-items: center;
  gap: var(--space-5);
  flex-wrap: wrap;
  color: var(--text-secondary);
  font-size: var(--text-sm);
}

.meta-item,
.uploader {
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.uploader {
  color: var(--text-secondary);
}

.uploader:hover {
  color: var(--accent);
}

.resource-actions {
  display: flex;
  gap: var(--space-3);
  margin-top: var(--space-5);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.action-btn {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  color: var(--text-secondary);
}

.action-btn:hover {
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.action-btn--active {
  border-color: var(--accent);
  color: var(--accent);
  background: var(--info-bg);
}

/* Content / comments */
.content-card,
.comment-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-6);
  margin-bottom: var(--space-4);
}

.card-label {
  font-size: var(--heading-3);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin-bottom: var(--space-4);
}

.description {
  line-height: var(--leading-relaxed);
  color: var(--text-secondary);
  margin-bottom: var(--space-5);
  font-size: var(--text-base);
  white-space: pre-wrap;
}

.file-info {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  background: var(--bg-deep);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  border: 1px solid var(--border-subtle);
  word-break: break-all;
}

.comment-head {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
}

.comment-head .card-label {
  margin-bottom: 0;
}

.comment-count {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  background: var(--bg-hover);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-full);
}

.comment-form {
  margin-bottom: var(--space-5);
}

.comment-form__actions {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-3);
}

.login-tip {
  text-align: center;
  padding: var(--space-5);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  background: var(--bg-deep);
  border-radius: var(--radius-sm);
  margin-bottom: var(--space-5);
}

.comment-list {
  border-top: 1px solid var(--border-subtle);
}

.comment-item {
  display: flex;
  gap: var(--space-3);
  padding: var(--space-5) 0;
  border-bottom: 1px solid var(--border-subtle);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-content {
  flex: 1;
  min-width: 0;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
  margin-bottom: var(--space-2);
}

.username {
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  font-size: var(--text-sm);
}

.time {
  color: var(--text-muted);
  font-size: var(--text-xs);
}

.comment-text {
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  font-size: var(--text-sm);
}

.comment-deleted {
  color: var(--text-muted);
  font-style: italic;
  font-size: var(--text-sm);
}

.reply-deleted {
  color: var(--text-muted);
  font-style: italic;
  font-size: var(--text-xs);
}

.comment-replies {
  margin-top: var(--space-3);
  padding-left: var(--space-4);
  border-left: 2px solid var(--border-default);
}

.reply-item {
  display: flex;
  gap: var(--space-2);
  padding: var(--space-2) 0;
}

.reply-content {
  flex: 1;
  font-size: var(--text-sm);
  min-width: 0;
}

.reply-nickname {
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin-right: var(--space-2);
}

.reply-text {
  color: var(--text-secondary);
}

.reply-time {
  color: var(--text-muted);
  font-size: var(--text-xs);
  margin-left: var(--space-2);
}

.comment-actions {
  margin-top: var(--space-2);
}

@media (max-width: 767px) {
  .resource-detail-page {
    padding: var(--space-5) 0 var(--section-gap-md);
  }

  .resource-header,
  .content-card,
  .comment-card {
    padding: var(--space-5);
  }

  .title {
    font-size: var(--text-2xl);
  }

  .meta {
    gap: var(--space-3);
  }
}
</style>
