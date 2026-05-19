<template>
  <div class="user-manage-page">
    <div class="user-card">
      <div class="card-header">
        <span>用户管理</span>
        <el-input
          v-model="searchKeyword"
          placeholder="搜索用户..."
          style="width: 200px"
          clearable
          @keyup.enter="handleSearch"
        >
          <template #append>
            <el-button icon="Search" @click="handleSearch" />
          </template>
        </el-input>
      </div>

      <el-table :data="users" v-loading="loading" stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名/学号" width="130" />
        <el-table-column prop="nickname" label="昵称" width="120" />
        <el-table-column prop="college" label="学院" width="120" />
        <el-table-column prop="grade" label="年级" width="80">
          <template #default="{ row }">
            {{ row.grade ? GRADE_LABELS[row.grade - 1] : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="role" label="角色" width="100">
          <template #default="{ row }">
            <el-tag :type="getRoleType(row.role)">
              {{ getRoleText(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === USER_STATUS.ENABLED ? 'success' : 'danger'">
              {{ row.status === USER_STATUS.ENABLED ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="注册时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button
              :type="row.status === USER_STATUS.ENABLED ? 'danger' : 'success'"
              size="small"
              @click="handleToggleStatus(row)"
            >
              {{ row.status === USER_STATUS.ENABLED ? '禁用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
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
import { getUserList, updateUserStatus } from '@/api/admin'
import { USER_STATUS, ROLE_MAP, ROLE_TAG_TYPE, GRADE_LABELS } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const loading = ref(false)
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

const getRoleType = (role) => ROLE_TAG_TYPE[role] || 'info'

const getRoleText = (role) => ROLE_MAP[role] || role

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.user-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.card-header > span {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}
</style>
