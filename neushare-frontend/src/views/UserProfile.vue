<template>
  <div class="user-profile-page">
    <div class="page-container">
      <!-- Profile Header -->
      <div class="profile-header card animate-slide-up" v-loading="profileLoading">
        <template v-if="profile">
          <div class="profile-top">
            <div class="avatar-section">
              <el-avatar :size="88" :src="profile.avatarUrl" class="profile-avatar">
                {{ getInitial(profile.nickname) }}
              </el-avatar>
            </div>
            <div class="info-section">
              <div class="name-row">
                <h2 class="nickname">{{ profile.nickname }}</h2>
                <el-tag
                  :type="ROLE_TAG_TYPE[profile.role] || 'info'"
                  size="small"
                  class="role-tag"
                >
                  {{ ROLE_MAP[profile.role] || profile.role }}
                </el-tag>
              </div>
              <div class="meta-row">
                <span class="username">@{{ profile.username }}</span>
                <span class="divider">|</span>
                <span v-if="profile.college">{{ profile.college }}</span>
                <span v-if="profile.grade" class="grade">
                  {{ GRADE_LABELS[profile.grade] || profile.grade + '年级' }}
                </span>
              </div>
            </div>
            <div class="action-section" v-if="userStore.isLoggedIn && userStore.userId !== userId">
              <el-button
                :type="isFollowing ? 'default' : 'primary'"
                :loading="followLoading"
                @click="handleFollow"
                class="follow-btn"
              >
                {{ isFollowing ? '已关注' : '+ 关注' }}
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
        </template>
        <el-empty v-else-if="!profileLoading" description="用户不存在或已被禁用" />
      </div>

      <!-- Resource Section -->
      <div class="resource-section" v-if="profile">
        <h3 class="section-title">TA 发布的资料</h3>
        <div class="resource-list" v-loading="resourcesLoading">
          <template v-if="resources.length > 0">
            <div class="resource-grid">
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
          </template>
          <el-empty v-else description="TA 还没有发布过资料" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import ResourceCard from '@/components/ResourceCard.vue'
import { getUserProfile, getUserResources } from '@/api/user'
import { followUser, unfollowUser, checkFollow } from '@/api/follow'
import { getInitial } from '@/utils/format'
import { ROLE_MAP, ROLE_TAG_TYPE, GRADE_LABELS } from '@/utils/constants'
import { ElMessage } from 'element-plus'

const route = useRoute()
const userStore = useUserStore()

const userId = ref(Number(route.params.id))

const profile = ref(null)
const profileLoading = ref(false)
const resources = ref([])
const resourcesLoading = ref(false)
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
  min-height: 100%;
  padding: 28px 0;
}

.page-container {
  max-width: 960px;
  margin: 0 auto;
  padding: 0 28px;
}

.profile-header {
  padding: 36px;
  border-radius: var(--radius-lg);
  margin-bottom: 32px;
  min-height: 180px;
}

.profile-top {
  display: flex;
  align-items: flex-start;
  gap: 24px;
}

.avatar-section {
  flex-shrink: 0;
}

.profile-avatar {
  border: 3px solid var(--border-subtle);
  font-size: 36px;
  font-weight: 600;
  color: var(--accent);
  background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
}

.info-section {
  flex: 1;
  min-width: 0;
  padding-top: 6px;
}

.name-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.nickname {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
}

.role-tag {
  font-weight: 500;
}

.meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--text-secondary);
  font-size: 14px;
  flex-wrap: wrap;
}

.username {
  font-family: var(--font-mono);
  font-size: 13px;
  color: var(--text-muted);
}

.divider {
  color: var(--border-strong);
}

.action-section {
  flex-shrink: 0;
  padding-top: 18px;
}

.follow-btn {
  border-radius: var(--radius-full);
  padding: 8px 28px;
  font-weight: 600;
  font-size: 14px;
}

.stats-row {
  display: flex;
  gap: 40px;
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--border-subtle);
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-num {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--text-primary);
}

.stat-label {
  font-size: 13px;
  color: var(--text-muted);
}

.resource-section {
  margin-top: 8px;
}

.section-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 20px;
  padding-left: 4px;
}

.resource-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 36px;
  padding: 20px 0;
}

@media (max-width: 900px) {
  .resource-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .profile-top {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }
  .name-row {
    justify-content: center;
  }
  .meta-row {
    justify-content: center;
  }
  .stats-row {
    justify-content: center;
  }
  .resource-grid {
    grid-template-columns: 1fr;
  }
}
</style>
