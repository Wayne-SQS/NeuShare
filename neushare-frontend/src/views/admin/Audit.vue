<template>
  <div class="audit-page">
    <div class="page-head">
      <div class="page-head__text">
        <span class="breadcrumb">管理后台 / 资料审核</span>
        <h1 class="page-title">资料审核</h1>
        <p class="page-subtitle">审核待发布的资料，通过后将公开展示</p>
      </div>
      <div class="page-head__actions">
        <el-tag type="warning" effect="plain">待审核 {{ pagination.total }}</el-tag>
      </div>
    </div>

    <div class="panel">
      <div v-if="loading" class="skeleton-list">
        <SkeletonCard v-for="n in 5" :key="`skeleton-${n}`" variant="list" :rows="1" />
      </div>

      <div v-else class="table-wrap">
        <el-table :data="resources" stripe>
          <el-table-column prop="title" label="标题" min-width="200">
            <template #default="{ row }">
              <router-link :to="`/resource/${row.id}`" class="title-link">
                {{ row.title }}
              </router-link>
            </template>
          </el-table-column>
          <el-table-column prop="uploadNickname" label="上传者" width="120" />
          <el-table-column prop="categoryName" label="分类" width="120" />
          <el-table-column prop="description" label="描述" min-width="220">
            <template #default="{ row }">
              <span class="description-text">{{ row.description || '暂无描述' }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="createTime" label="上传时间" width="150">
            <template #default="{ row }">
              {{ formatTime(row.createTime) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="160" fixed="right">
            <template #default="{ row }">
              <el-button type="success" link @click="handleAudit(row, RESOURCE_STATUS.PUBLISHED)">
                通过
              </el-button>
              <el-button type="danger" link @click="handleAudit(row, RESOURCE_STATUS.REJECTED)">
                驳回
              </el-button>
            </template>
          </el-table-column>

          <template #empty>
            <EmptyState
              icon="DocumentChecked"
              title="没有待审核的资料"
              description="新的资料提交后会出现在这里"
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
          @current-change="fetchResources"
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
import { getPendingResources, auditResource } from '@/api/admin'
import { RESOURCE_STATUS } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const loading = ref(true)
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
.audit-page {
  display: flex;
  flex-direction: column;
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

.title-link {
  color: var(--text-primary);
  font-weight: var(--font-medium);
}

.title-link:hover {
  color: var(--accent);
}

.description-text {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  color: var(--text-secondary);
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-5);
}
</style>
