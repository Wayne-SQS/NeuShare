<template>
  <div class="resource-detail-page" v-loading="loading">
    <div class="page-container" v-if="resource">
      <nav class="breadcrumb">
        <router-link to="/">首页</router-link><span>/</span>
        <router-link to="/resource">资源广场</router-link><span>/</span>
        <span>{{ resource.categoryName || '资料' }}</span><span>/</span>
        <span>资料详情</span>
      </nav>

      <div class="detail-layout">
        <div class="content-card">
          <span class="detail-pill">{{ resource.categoryName || '未分类' }}<i v-if="resource.courseName"> · {{ resource.courseName }}</i></span>
          <h1 class="detail-title">{{ resource.title }}</h1>

          <!-- 结构化归属信息（V5/V6）：一眼确认「是不是我这门课的」，也可点进二次筛选 -->
          <div class="structured-bar" v-if="structuredTags.length">
            <router-link
              v-for="tag in structuredTags"
              :key="tag.text"
              class="structured-chip"
              :to="{ path: '/resource', query: tag.query }"
            >
              <el-icon><Collection /></el-icon>
              {{ tag.text }}
            </router-link>
          </div>

          <div class="detail-meta">
            <el-avatar :size="24" :src="resource.avatarUrl">{{ getInitial(resource.uploadNickname) }}</el-avatar>
            <router-link :to="`/user/${resource.uploadUserId}`" class="detail-author">{{ resource.uploadNickname || '匿名' }}</router-link>
            <span>{{ formatTime(resource.createTime) }} 上传</span>
            <span class="meta-sep">·</span>
            <span>{{ resource.viewCount || 0 }} 次浏览</span>
            <span class="meta-sep">·</span>
            <span>{{ resource.favoriteCount || 0 }} 人收藏</span>
          </div>

          <p class="detail-desc">{{ resource.description || '暂无描述' }}</p>

          <div class="file-strip" v-if="resource.contentUrl">
            <span class="file-strip__icon"><el-icon :size="20"><Document /></el-icon></span>
            <div class="file-strip__info">
              <strong>{{ fileName }}</strong>
              <span>{{ fileExt }} · 点击右侧按钮下载</span>
            </div>
            <a :href="resource.contentUrl" target="_blank" rel="noopener noreferrer" class="download-btn">下载资料</a>
          </div>

          <div class="detail-actions">
            <button type="button" :class="['detail-action', { 'detail-action--on': isLiked }]" @click="handleLike">
              <el-icon><StarFilled v-if="isLiked" /><Star v-else /></el-icon>点赞 {{ resource.likeCount || 0 }}
            </button>
            <button type="button" :class="['detail-action', { 'detail-action--on': isFavorited }]" @click="handleFavorite">
              <el-icon><Star v-if="isFavorited" /><Collection v-else /></el-icon>{{ isFavorited ? '已收藏' : '收藏' }} {{ resource.favoriteCount || 0 }}
            </button>
            <button type="button" class="detail-action" @click="handleShare">分享链接</button>
          </div>

          <div class="detail-tags">
            <span>标签</span>
            <em>{{ resource.categoryName || '未分类' }}</em>
            <em v-if="resource.courseName">{{ resource.courseName }}</em>
          </div>
        </div>

        <aside class="detail-aside">
          <div class="aside-card uploader-card">
            <h3>关于上传者</h3>
            <div class="uploader-row">
              <el-avatar :size="40" :src="resource.avatarUrl">{{ getInitial(resource.uploadNickname) }}</el-avatar>
              <div>
                <strong>{{ resource.uploadNickname || '匿名' }}</strong>
                <span>NeuShare 共建者</span>
              </div>
            </div>
            <router-link :to="`/user/${resource.uploadUserId}`" class="aside-btn">查看 TA 的主页</router-link>
          </div>

          <div class="aside-card related-card">
            <h3>同分类资料</h3>
            <p>还想找 {{ resource.categoryName || '同类' }} 的资料？去资源广场按分类继续浏览。</p>
            <router-link :to="{ path: '/resource', query: resource.categoryId ? { categoryId: resource.categoryId } : {} }" class="aside-link">
              查看同分类资料 <el-icon><ArrowRight /></el-icon>
            </router-link>
          </div>
        </aside>
      </div>

      <div class="comment-card">
        <h2>评论 <span>{{ totalComments }}</span></h2>

        <div class="comment-form" v-if="userStore.isLoggedIn">
          <el-input
            v-model="commentForm.content"
            type="textarea"
            :rows="3"
            placeholder="写下你的想法，或针对资料内容提问…"
            maxlength="500"
            show-word-limit
          />
          <el-button type="primary" :loading="submitting" class="submit-btn" @click="submitComment">发表评论</el-button>
        </div>
        <div v-else class="login-tip"><router-link to="/login">登录</router-link> 后参与评论</div>

        <div class="comment-list">
          <div v-for="comment in comments" :key="comment.id" class="comment-item">
            <div class="comment-avatar" v-if="!comment.deleted">
              <el-avatar :size="36" :src="comment.avatarUrl">{{ getInitial(comment.nickname) }}</el-avatar>
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
                <div class="comment-actions" v-if="userStore.isLoggedIn">
                  <button type="button" @click="handleReply(comment)">回复</button>
                </div>
              </template>
              <div class="comment-replies" v-if="comment.children && comment.children.length > 0">
                <div v-for="reply in comment.children" :key="reply.id" class="reply-item">
                  <el-avatar :size="26" :src="reply.avatarUrl" v-if="!reply.deleted">{{ getInitial(reply.nickname) }}</el-avatar>
                  <div class="reply-content">
                    <template v-if="reply.deleted"><span class="reply-deleted">该评论已被删除</span></template>
                    <template v-else>
                      <span class="reply-nickname">{{ reply.nickname }}</span>
                      <span class="reply-text">{{ reply.content }}</span>
                      <span class="reply-time">{{ formatTime(reply.createTime) }}</span>
                    </template>
                  </div>
                </div>
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
import { getResourceDetail, likeResource, unlikeResource, checkLiked } from '@/api/resource'
import { getComments, addComment } from '@/api/comment'
import { addFavorite, removeFavorite, checkFavorite } from '@/api/favorite'
import { formatTime, getInitial, buildStructuredTags } from '@/utils/format'

const route = useRoute()
const userStore = useUserStore()

const loading = ref(true)
const resource = ref(null)
const comments = ref([])
const isLiked = ref(false)
const isFavorited = ref(false)
const submitting = ref(false)
const replyingTo = ref(null)

const commentForm = reactive({ content: '' })
const resourceId = computed(() => route.params.id)

// 课程 / 教师 / 学年学期，点击即按该维度筛选同类资料（V5/V6）
const structuredTags = computed(() => buildStructuredTags(resource.value))

const fileName = computed(() => {
  const url = resource.value?.contentUrl || ''
  try { return decodeURIComponent(url.split('/').pop() || '') } catch (e) { return url.split('/').pop() || '' }
})
const fileExt = computed(() => (fileName.value.split('.').pop() || 'FILE').toUpperCase())

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
    if (userStore.token) {
      try {
        const likeRes = await checkLiked(resourceId.value)
        if (likeRes.code === 200) isLiked.value = likeRes.data
      } catch (e) { /* 未登录或接口报错，忽略 */ }
    }
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
  await Promise.all([fetchResource(), fetchComments(), checkFavoriteStatus()])
  loading.value = false
}

watch(resourceId, () => { loadAllData() })

const handleLike = async () => {
  if (!userStore.isLoggedIn) { ElMessage.warning('请先登录'); return }
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
  if (!userStore.isLoggedIn) { ElMessage.warning('请先登录'); return }
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

const handleShare = async () => {
  try {
    await navigator.clipboard.writeText(window.location.href)
    ElMessage.success('链接已复制')
  } catch (e) {
    ElMessage.warning('复制失败，请手动复制地址栏链接')
  }
}

const handleReply = (comment) => {
  replyingTo.value = comment
  commentForm.content = `@${comment.nickname} `
}

const submitComment = async () => {
  if (!commentForm.content.trim()) { ElMessage.warning('请输入评论内容'); return }
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

onMounted(async () => { await loadAllData() })
</script>

<style scoped>
.resource-detail-page { min-height: 100%; padding: 28px 0 64px; }
.page-container { max-width: 1160px; margin: 0 auto; padding: 0 28px; }

.breadcrumb {
  display: flex; align-items: center; gap: 8px;
  font-size: 12px; color: var(--text-muted); margin-bottom: 22px;
}
.breadcrumb a { color: var(--text-muted); text-decoration: none; }
.breadcrumb a:hover { color: var(--accent); }

.detail-layout { display: grid; grid-template-columns: 1fr 260px; gap: 22px; align-items: start; }

.content-card, .comment-card, .aside-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.content-card { padding: 30px 32px; }

.detail-pill {
  display: inline-block; padding: 5px 13px; border-radius: var(--radius-full);
  background: rgba(var(--accent-rgb), 0.10); color: var(--accent);
  font-size: 12px; font-weight: 600;
}
.detail-pill i { font-style: normal; opacity: 0.8; }

.detail-title {
  margin: 18px 0 16px; font-size: 28px; line-height: 1.35;
  font-weight: 700; letter-spacing: -0.025em; color: var(--text-primary);
}

.detail-meta {
  display: flex; align-items: center; flex-wrap: wrap; gap: 8px;
  font-size: 12px; color: var(--text-muted);
}
.detail-author { color: var(--text-secondary); font-weight: 600; text-decoration: none; }
.detail-author:hover { color: var(--accent); }
.meta-sep { opacity: 0.6; }

.detail-desc {
  margin: 24px 0; font-size: 14px; line-height: 1.9;
  color: var(--text-secondary); white-space: pre-wrap;
}

.file-strip {
  display: flex; align-items: center; gap: 14px;
  padding: 14px 16px; border-radius: var(--radius);
  background: var(--bg-elevated); border: 1px solid var(--border-default);
}
.file-strip__icon {
  width: 38px; height: 38px; flex-shrink: 0; display: flex;
  align-items: center; justify-content: center;
  border-radius: var(--radius-sm); background: rgba(var(--accent-rgb), 0.10); color: var(--accent);
}
.file-strip__info { flex: 1; display: flex; flex-direction: column; min-width: 0; }
.file-strip__info strong { font-size: 13px; color: var(--text-primary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.file-strip__info span { font-size: 11px; color: var(--text-muted); }
.download-btn {
  flex-shrink: 0; padding: 9px 18px; border-radius: var(--radius-sm);
  background: var(--accent); color: var(--text-inverse);
  font-size: 13px; font-weight: 600; text-decoration: none;
}
.download-btn:hover { background: var(--accent-light); }

.detail-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 20px; }
.detail-action {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px; border-radius: var(--radius-sm);
  border: 1px solid var(--border-default); background: var(--bg-elevated);
  color: var(--text-secondary); font-size: 13px; cursor: pointer;
  transition: var(--transition-fast);
}
.detail-action:hover { border-color: var(--border-accent); color: var(--accent); }
.detail-action--on { border-color: var(--accent); color: var(--accent); background: rgba(var(--accent-rgb), 0.08); }

.detail-tags {
  display: flex; align-items: center; flex-wrap: wrap; gap: 8px;
  margin-top: 20px; padding-top: 16px; border-top: 1px solid var(--border-subtle);
  font-size: 12px; color: var(--text-muted);
}
.detail-tags em {
  font-style: normal; padding: 4px 10px; border-radius: var(--radius-full);
  background: var(--bg-hover); color: var(--text-secondary);
}

.structured-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.structured-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--text-secondary);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  text-decoration: none;
  transition: var(--transition);
}

.structured-chip:hover {
  color: var(--accent);
  border-color: var(--border-accent);
}

.detail-aside { display: flex; flex-direction: column; gap: 18px; }
.aside-card { padding: 20px; }
.aside-card h3 { font-size: 14px; font-weight: 600; color: var(--text-primary); margin-bottom: 16px; }
.uploader-row { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; }
.uploader-row div { display: flex; flex-direction: column; }
.uploader-row strong { font-size: 14px; color: var(--text-primary); }
.uploader-row span { font-size: 12px; color: var(--text-muted); }
.aside-btn {
  display: block; text-align: center; padding: 10px; border-radius: var(--radius-sm);
  background: var(--accent); color: var(--text-inverse);
  font-size: 13px; font-weight: 600; text-decoration: none;
}
.aside-btn:hover { background: var(--accent-light); }
.related-card p { font-size: 13px; line-height: 1.7; color: var(--text-secondary); }
.aside-link {
  display: inline-flex; align-items: center; gap: 5px;
  margin-top: 14px; font-size: 13px; font-weight: 600;
  color: var(--accent); text-decoration: none;
}

.comment-card { margin-top: 22px; padding: 28px 32px; }
.comment-card h2 { font-size: 18px; font-weight: 700; color: var(--text-primary); margin-bottom: 20px; }
.comment-card h2 span { font-family: var(--font-mono); color: var(--accent); margin-left: 4px; }
.comment-form { margin-bottom: 24px; }
.comment-form .el-textarea { margin-bottom: 12px; }
.login-tip { text-align: center; padding: 20px; color: var(--text-muted); font-size: 14px; }
.login-tip a { color: var(--accent); }

.comment-list { margin-top: 12px; }
.comment-item { display: flex; gap: 14px; padding: 18px 0; border-bottom: 1px solid var(--border-subtle); }
.comment-item:last-child { border-bottom: none; }
.comment-content { flex: 1; min-width: 0; }
.comment-header { display: flex; justify-content: space-between; margin-bottom: 8px; }
.username { font-weight: 600; color: var(--text-primary); font-size: 14px; }
.time { color: var(--text-muted); font-size: 12px; }
.comment-text { color: var(--text-secondary); line-height: 1.7; font-size: 14px; }
.comment-deleted, .reply-deleted { color: var(--text-muted); font-style: italic; font-size: 13px; }
.comment-replies { margin-top: 14px; padding-left: 16px; border-left: 2px solid var(--border-default); }
.reply-item { display: flex; gap: 8px; padding: 10px 0; }
.reply-content { flex: 1; font-size: 13px; }
.reply-nickname { font-weight: 600; color: var(--text-primary); margin-right: 8px; }
.reply-text { color: var(--text-secondary); }
.reply-time { color: var(--text-muted); font-size: 12px; margin-left: 8px; }
.comment-actions { margin-top: 8px; }
.comment-actions button {
  border: none; background: transparent; padding: 0;
  color: var(--accent); font-size: 12px; cursor: pointer;
}

@media (max-width: 900px) {
  .detail-layout { grid-template-columns: 1fr; }
  .detail-aside { flex-direction: row; }
  .aside-card { flex: 1; }
}
@media (max-width: 640px) {
  .content-card, .comment-card { padding: 22px 18px; }
  .detail-title { font-size: 22px; }
  .detail-aside { flex-direction: column; }
  .file-strip { flex-wrap: wrap; }
}
</style>
