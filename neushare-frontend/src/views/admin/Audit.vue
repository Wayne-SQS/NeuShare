<template>
  <div class="audit-page">
    <div class="audit-card">
      <div class="card-header">
        <span>资料审核</span>
        <el-tag type="warning">待审核: {{ pagination.total }}</el-tag>
      </div>

      <el-table :data="resources" v-loading="loading" stripe>
        <el-table-column prop="title" label="标题" min-width="200">
          <template #default="{ row }">
            <router-link :to="`/resource/${row.id}`" class="title-link">
              {{ row.title }}
            </router-link>
          </template>
        </el-table-column>
        <el-table-column prop="uploadNickname" label="上传者" width="120" />
        <el-table-column prop="categoryName" label="分类" width="120" />
        <el-table-column prop="description" label="描述" min-width="200">
          <template #default="{ row }">
            <span class="description-text">{{ row.description || '暂无描述' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="上传时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="success" size="small" @click="handleAudit(row, RESOURCE_STATUS.PUBLISHED)">
              通过
            </el-button>
            <el-button type="danger" size="small" @click="handleAudit(row, RESOURCE_STATUS.REJECTED)">
              驳回
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
          @current-change="fetchResources"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getPendingResources, auditResource } from '@/api/admin'
import { RESOURCE_STATUS } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const loading = ref(false)
const resources = ref([])

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const fetchResources = async () => {
  loading.value = true
  try {
    const res = await getPendingResources({
      pageNum: pagination.page,
      pageSize: pagination.size
    })
    resources.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (error) {
    console.error('Failed to fetch resources:', error)
  } finally {
    loading.value = false
  }
}

const handleAudit = async (row, status) => {
  const actionText = status === RESOURCE_STATUS.PUBLISHED ? '通过' : '驳回'
  try {
    await ElMessageBox.confirm(`确定要${actionText}该资料吗？`, '提示', {
      type: status === RESOURCE_STATUS.PUBLISHED ? 'success' : 'warning'
    })
    await auditResource(row.id, status)
    ElMessage.success(status === RESOURCE_STATUS.PUBLISHED ? '审核通过' : '已驳回')
    fetchResources()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to audit:', error)
    }
  }
}

onMounted(() => {
  fetchResources()
})
</script>

<style scoped>
.audit-card {
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

.title-link {
  color: var(--accent);
  text-decoration: none;
}

.title-link:hover {
  color: var(--accent-light);
}

.description-text {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}
</style>
