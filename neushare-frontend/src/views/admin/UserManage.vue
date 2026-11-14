<template>
  <div class="user-manage-page">
    <div class="page-head">
      <div class="page-head__text">
        <span class="breadcrumb">管理后台 / 用户管理</span>
        <h1 class="page-title">用户管理</h1>
        <p class="page-subtitle">查看用户信息，调整账号状态</p>
      </div>
      <div class="page-head__actions">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索用户"
          clearable
          prefix-icon="Search"
          class="search-input"
          @keyup.enter="handleSearch"
          @clear="handleSearch"
        />
        <el-button type="primary" @click="handleSearch">搜索</el-button>
      </div>
    </div>

    <div class="panel">
      <div v-if="loading" class="skeleton-list">
        <SkeletonCard v-for="n in 5" :key="`skeleton-${n}`" variant="list" :rows="1" />
      </div>

      <div v-else class="table-wrap">
        <el-table :data="users" stripe>
          <el-table-column prop="id" label="ID" width="80" />
          <el-table-column prop="username" label="用户名/学号" width="140" />
          <el-table-column prop="nickname" label="昵称" width="130" />
          <el-table-column prop="college" label="学院" width="130" />
          <el-table-column prop="grade" label="年级" width="90">
            <template #default="{ row }">
              {{ row.grade ? GRADE_LABELS[row.grade - 1] : '-' }}
            </template>
          </el-table-column>
          <el-table-column prop="role" label="角色" width="110">
            <template #default="{ row }">
              <el-tag :type="ROLE_TAG_TYPE[row.role] || 'info'" size="small" effect="plain">
                {{ ROLE_MAP[row.role] || row.role }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="100">
            <template #default="{ row }">
              <el-tag
                :type="row.status === USER_STATUS.ENABLED ? 'success' : 'danger'"
                size="small"
                effect="plain"
              >
                {{ row.status === USER_STATUS.ENABLED ? '正常' : '禁用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="createTime" label="注册时间" width="150">
            <template #default="{ row }">
              {{ formatTime(row.createTime) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button
                :type="row.status === USER_STATUS.ENABLED ? 'danger' : 'success'"
                link
                @click="handleToggleStatus(row)"
              >
                {{ row.status === USER_STATUS.ENABLED ? '禁用' : '启用' }}
              </el-button>
            </template>
          </el-table-column>

          <template #empty>
            <EmptyState
              icon="User"
              title="没有找到用户"
              description="换个关键词再试试"
            />
          </template>
        </el-table>
      </div>

      <div v-if="!loading && pagination.total > 0" class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :total="pagination.total"
          layout="total, prev, pager, next"
          @current-change="fetchUsers"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getUserList, updateUserStatus } from '@/api/admin'
import { USER_STATUS, ROLE_MAP, ROLE_TAG_TYPE, GRADE_LABELS } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const loading = ref(true)
const users = ref([])
const searchKeyword = ref('')

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const fetchUsers = async () => {
  loading.value = true
  try {
    const res = await getUserList({
      pageNum: pagination.page,
      pageSize: pagination.size,
      keyword: searchKeyword.value || undefined
    })
    users.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (error) {
    console.error('Failed to fetch users:', error)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchUsers()
}

const handleToggleStatus = async (row) => {
  const newStatus = row.status === USER_STATUS.ENABLED ? USER_STATUS.DISABLED : USER_STATUS.ENABLED
  const actionText = newStatus === USER_STATUS.DISABLED ? '禁用' : '启用'

  try {
    await ElMessageBox.confirm(`确定要${actionText}该用户吗？`, '提示', {
      type: 'warning'
    })
    await updateUserStatus(row.id, newStatus)
    ElMessage.success(`${actionText}成功`)
    fetchUsers()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to update status:', error)
    }
  }
}

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.user-manage-page {
  display: flex;
  flex-direction: column;
}

.search-input {
  width: 240px;
}

.skeleton-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.table-wrap {
  width: 100%;
  overflow-x: auto;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-5);
}

@media (max-width: 767px) {
  .page-head__actions {
    width: 100%;
  }

  .search-input {
    flex: 1;
    width: auto;
    min-width: 0;
  }
}
</style>
