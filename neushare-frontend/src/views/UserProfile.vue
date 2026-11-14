<template>
  <div class="user-profile-page">
    <div class="container">
      <div v-if="profileLoading">
        <SkeletonCard variant="list" :rows="2" class="profile-skeleton" />
      </div>

      <div v-else-if="!profile" class="state-panel">
        <EmptyState
          icon="UserFilled"
          title="用户不存在"
          description="该用户可能已被禁用或删除"
        >
          <el-button type="primary" @click="$router.push('/')">返回首页</el-button>
        </EmptyState>
      </div>

      <template v-else>
        <header class="profile-header">
          <div class="profile-top">
            <div class="avatar-section">
              <el-avatar :size="80" :src="profile.avatarUrl" class="profile-avatar">
                {{ getInitial(profile.nickname) }}
              </el-avatar>
            </div>
            <div class="info-section">
              <div class="name-row">
                <h2 class="nickname">{{ profile.nickname }}</h2>
                <el-tag
                  :type="ROLE_TAG_TYPE[profile.role] || 'info'"
                  size="small"
                  effect="plain"
                  class="role-tag"
                >
                  {{ ROLE_MAP[profile.role] || profile.role }}
                </el-tag>
              </div>
              <div class="meta-row">
                <span class="username">@{{ profile.username }}</span>
                <span v-if="profile.college" class="divider"></span>
                <span v-if="profile.college">{{ profile.college }}</span>
                <span v-if="profile.grade" class="divider"></span>
                <span v-if="profile.grade">
                  {{ GRADE_LABELS[profile.grade - 1] || profile.grade + '年级' }}
                </span>
              </div>
            </div>
            <div v-if="userStore.isLoggedIn && userStore.userId !== userId" class="action-section">
              <el-button
                :type="isFollowing ? 'default' : 'primary'"
                :loading="followLoading"
                @click="handleFollow"
              >
                {{ isFollowing ? '已关注' : '关注' }}
              </el-button>
            </div>
          </div>

          <div class="stats-row">
            <div class="stat-item">
              <span class="stat-num">{{ profile.resourceCount || 0 }}</span>
              <span class="stat-label">资料</span>
            </div>
            <div class="stat-item">
              <span class="stat-num">{{ profile.followerCount || 0 }}</span>
              <span class="stat-label">粉丝</span>
            </div>
            <div class="stat-item">
              <span class="stat-num">{{ profile.followingCount || 0 }}</span>
              <span class="stat-label">关注</span>
            </div>
          </div>
        </header>

        <section class="resource-section">
          <div class="section-header">
            <h2 class="section-title">TA 发布的资料</h2>
            <span class="section-count">共 {{ pagination.total }} 份</span>
          </div>

          <div v-if="resourcesLoading" class="grid-auto">
            <SkeletonCard v-for="n in 3" :key="`skeleton-${n}`" :rows="2" />
          </div>
          <div v-else-if="resources.length > 0">
            <div class="grid-auto">
              <ResourceCard
                v-for="resource in resources"
                :key="resource.id"
                :resource="resource"
              />
            </div>
            <div class="pagination">
              <el-pagination
                v-model:current-page="pagination.page"
                v-model:page-size="pagination.size"
                :page-sizes="[12, 24, 36]"
                :total="pagination.total"
                layout="total, sizes, prev, pager, next, jumper"
                @size-change="fetchResources"
                @current-change="fetchResources"
              />
            </div>
          </div>
          <div v-else class="state-panel">
            <EmptyState
              icon="Document"
              title="TA 还没有发布过资料"
              description="关注该用户，第一时间获取更新"
            />
          </div>
        </section>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import ResourceCard from '@/components/ResourceCard.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getUserProfile, getUserResources } from '@/api/user'
import { followUser, unfollowUser, checkFollow } from '@/api/follow'
import { getInitial } from '@/utils/format'
import { ROLE_MAP, ROLE_TAG_TYPE, GRADE_LABELS } from '@/utils/constants'
import { ElMessage } from 'element-plus'

const route = useRoute()
const userStore = useUserStore()

const userId = ref(Number(route.params.id))

const profile = ref(null)
const profileLoading = ref(true)
const resources = ref([])
const resourcesLoading = ref(true)
const isFollowing = ref(false)
const followLoading = ref(false)

const pagination = reactive({
  page: 1,
  size: 12,
  total: 0
})

const fetchProfile = async () => {
  profileLoading.value = true
  try {
    const res = await getUserProfile(userId.value)
    profile.value = res.data
    if (userStore.isLoggedIn && userStore.userId !== userId.value) {
      fetchFollowStatus()
    }
  } catch {
    profile.value = null
  } finally {
    profileLoading.value = false
  }
}

const fetchFollowStatus = async () => {
  try {
    const res = await checkFollow(userId.value)
    isFollowing.value = res.data?.isFollowing || false
  } catch {
    isFollowing.value = false
  }
}

const fetchResources = async () => {
  resourcesLoading.value = true
  try {
    const res = await getUserResources(userId.value, {
      pageNum: pagination.page,
      pageSize: pagination.size
    })
    resources.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch {
    resources.value = []
  } finally {
    resourcesLoading.value = false
  }
}

const handleFollow = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  followLoading.value = true
  try {
    if (isFollowing.value) {
      await unfollowUser(userId.value)
      isFollowing.value = false
    } else {
      await followUser(userId.value)
      isFollowing.value = true
      ElMessage.success('关注成功')
    }
  } catch {
    // error handled by interceptor
  } finally {
    followLoading.value = false
  }
}

watch(() => route.params.id, (newId) => {
  userId.value = Number(newId)
  pagination.page = 1
  profile.value = null
  resources.value = []
  fetchProfile()
  fetchResources()
})

onMounted(() => {
  fetchProfile()
  fetchResources()
})
</script>

<style scoped>
.user-profile-page {
  padding: var(--section-gap-md) 0 var(--section-gap-lg);
}

.profile-skeleton {
  padding: var(--space-7);
}

.state-panel {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
}

.profile-header {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-7);
  margin-bottom: var(--space-7);
}

.profile-top {
  display: flex;
  align-items: flex-start;
  gap: var(--space-5);
}

.avatar-section {
  flex-shrink: 0;
}

.profile-avatar {
  border: 1px solid var(--border-default);
  font-size: var(--text-3xl);
  font-weight: var(--font-semibold);
  color: var(--accent);
  background: var(--bg-deep);
}

.info-section {
  flex: 1;
  min-width: 0;
}

.name-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-2);
  flex-wrap: wrap;
}

.nickname {
  font-size: var(--heading-2);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin: 0;
  letter-spacing: -0.02em;
}

.role-tag {
  font-weight: var(--font-medium);
}

.meta-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  flex-wrap: wrap;
}

.username {
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.divider {
  width: 1px;
  height: 12px;
  background: var(--border-strong);
}

.action-section {
  flex-shrink: 0;
}

.stats-row {
  display: flex;
  gap: var(--space-9);
  margin-top: var(--space-5);
  padding-top: var(--space-5);
  border-top: 1px solid var(--border-subtle);
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.stat-num {
  font-size: var(--text-xl);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  line-height: 1.2;
}

.stat-label {
  font-size: var(--text-xs);
  color: var(--text-secondary);
}

.resource-section {
  margin-top: var(--space-2);
}

.section-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
}

.section-title {
  font-size: var(--heading-3);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}

.section-count {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-6);
}

@media (max-width: 767px) {
  .user-profile-page {
    padding: var(--space-5) 0 var(--section-gap-md);
  }

  .profile-header {
    padding: var(--space-5);
  }

  .profile-top {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-4);
  }

  .stats-row {
    gap: var(--space-7);
    margin-top: var(--space-4);
    padding-top: var(--space-4);
  }

  .nickname {
    font-size: var(--text-xl);
  }
}
</style>
