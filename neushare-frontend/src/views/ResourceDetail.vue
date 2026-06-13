<template>
  <div class="resource-detail-page" v-loading="loading">
    <div class="page-container" v-if="resource">
      <div class="resource-header">
        <div class="resource-info">
          <el-tag class="category-tag">{{ resource.categoryName || '未分类' }}</el-tag>
          <h1 class="title">{{ resource.title }}</h1>
          <div class="meta">
            <span class="meta-item">
              <el-icon><User /></el-icon>
              <router-link :to="`/user/${resource.uploadUserId}`" class="uploader-link">
                {{ resource.uploadNickname || '匿名' }}
              </router-link>
            </span>
            <span class="meta-divider"></span>
            <span class="meta-item">
              <el-icon><Clock /></el-icon>
              {{ formatTime(resource.createTime) }}
            </span>
            <span class="meta-divider"></span>
            <span class="meta-item">
              <el-icon><View /></el-icon>
              {{ resource.viewCount || 0 }} 次浏览
            </span>
            <span class="meta-divider"></span>
            <span class="meta-item">
              <el-icon><Star /></el-icon>
              {{ resource.favoriteCount || 0 }} 次收藏
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
      </div>

      <div class="content-card">
        <div class="card-label">资料描述</div>
        <div class="description">
          {{ resource.description || '暂无描述' }}
        </div>
        <div class="file-info" v-if="resource.contentUrl">
          <el-icon><Document /></el-icon>
          <span>{{ resource.contentUrl }}</span>
        </div>
      </div>

      <div class="comment-card">
        <div class="card-label">评论 ({{ totalComments }})</div>

        <div class="comment-form" v-if="userStore.isLoggedIn">
          <el-input
            v-model="commentForm.content"
            type="textarea"
            :rows="3"
            placeholder="写下你的评论..."
            maxlength="500"
            show-word-limit
          />
          <el-button type="primary" :loading="submitting" class="submit-btn" @click="submitComment">
            发表评论
          </el-button>
        </div>
        <div v-else class="login-tip">
          <router-link to="/login">登录</router-link> 后参与评论
        </div>

        <div class="comment-list">
          <div v-for="comment in comments" :key="comment.id" class="comment-item">
            <div class="comment-avatar" v-if="!comment.deleted">
              <el-avatar :size="40" :src="comment.avatarUrl">
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
              <div class="comment-replies" v-if="comment.children && comment.children.length > 0">
                <div v-for="reply in comment.children" :key="reply.id" class="reply-item">
                  <el-avatar :size="28" :src="reply.avatarUrl" v-if="!reply.deleted">
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
              <div class="comment-actions" v-if="userStore.isLoggedIn && !comment.deleted">
                <el-button type="primary" link size="small" @click="handleReply(comment)">回复</el-button>
              </div>
            </div>
          </div>
          <el-empty v-if="comments.length === 0" description="暂无评论" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/modules/user'
import { getResourceDetail, likeResource, unlikeResource } from '@/api/resource'
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
  } catch (error) {
    console.error('Failed to fetch resource:', error)
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
  min-height: 100%;
  padding: 28px 0;
}

.page-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 28px;
}

/* Header */
.resource-header {
  background: var(--bg-surface);
  padding: 32px;
  border-radius: var(--radius-lg);
  margin-bottom: 20px;
  border: 1px solid var(--border-subtle);
}

.resource-info {
  margin-bottom: 24px;
}

.category-tag {
  margin-bottom: 14px;
  background: rgba(200, 164, 78, 0.12);
  border: none;
  color: var(--accent);
  font-weight: 500;
}

.title {
  font-size: 26px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 18px;
  letter-spacing: -0.02em;
  line-height: 1.3;
}

.meta {
  display: flex;
  gap: 16px;
  color: var(--text-muted);
  font-size: 14px;
  align-items: center;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 5px;
}

.meta-divider {
  width: 1px;
  height: 14px;
  background: var(--border-strong);
}

.resource-actions {
  display: flex;
  gap: 12px;
}

.action-btn {
  background: var(--bg-elevated) !important;
  border: 1px solid var(--border-default) !important;
  color: var(--text-secondary) !important;
  display: flex !important;
  align-items: center !important;
  gap: 6px !important;
  padding: 10px 20px !important;
}

.action-btn:hover {
  border-color: var(--border-accent) !important;
  color: var(--accent-light) !important;
}

.action-btn--active {
  border-color: var(--accent) !important;
  color: var(--accent) !important;
  background: rgba(200, 164, 78, 0.08) !important;
}

/* Content & Comment cards */
.content-card,
.comment-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  margin-bottom: 20px;
  border: 1px solid var(--border-subtle);
}

.card-label {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 18px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.description {
  line-height: 1.75;
  color: var(--text-secondary);
  margin-bottom: 20px;
  font-size: 15px;
}

.file-info {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: var(--bg-elevated);
  border-radius: var(--radius-sm);
  color: var(--text-muted);
  font-size: 13px;
  border: 1px solid var(--border-subtle);
}

/* Comments */
.comment-form {
  margin-bottom: 24px;
}

.comment-form .el-textarea {
  margin-bottom: 12px;
}

.submit-btn {
  margin-top: 8px;
}

.login-tip {
  text-align: center;
  padding: 20px;
  color: var(--text-muted);
  font-size: 14px;
}

.login-tip a {
  color: var(--accent);
}

.comment-list {
  margin-top: 20px;
}

.comment-item {
  display: flex;
  gap: 14px;
  padding: 18px 0;
  border-bottom: 1px solid var(--border-subtle);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-content {
  flex: 1;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.username {
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
}

.time {
  color: var(--text-muted);
  font-size: 12px;
}

.comment-text {
  color: var(--text-secondary);
  line-height: 1.6;
  font-size: 14px;
}

.comment-deleted {
  color: #C0C4CC;
  font-style: italic;
  font-size: 14px;
}

.reply-deleted {
  color: #C0C4CC;
  font-style: italic;
  font-size: 13px;
}

.comment-replies {
  margin-top: 14px;
  padding-left: 16px;
  border-left: 2px solid var(--border-default);
}

.reply-item {
  display: flex;
  gap: 8px;
  padding: 10px 0;
}

.reply-content {
  flex: 1;
  font-size: 13px;
}

.reply-nickname {
  font-weight: 600;
  color: var(--text-primary);
  margin-right: 8px;
}

.reply-text {
  color: var(--text-secondary);
}

.reply-time {
  color: var(--text-muted);
  font-size: 12px;
  margin-left: 8px;
}

.comment-actions {
  margin-top: 6px;
}

.uploader-link {
  color: var(--text-muted);
  text-decoration: none;
}

.uploader-link:hover {
  color: var(--accent);
}
</style>
