<template>
  <div class="my-resources-page">
    <div class="panel">
      <div class="panel-head">
        <div>
          <h3 class="panel-title">我的资料</h3>
          <p class="panel-subtitle">管理你上传的学习资料</p>
        </div>
        <el-button type="primary" @click="router.push('/upload')">
          <el-icon><Plus /></el-icon>上传资料
        </el-button>
      </div>

      <div v-if="loading" class="skeleton-list">
        <SkeletonCard v-for="n in 4" :key="`skeleton-${n}`" variant="list" :rows="1" />
      </div>

      <div v-else class="table-wrap">
        <el-table :data="resources" stripe>
          <el-table-column prop="title" label="标题" min-width="220">
            <template #default="{ row }">
              <router-link :to="`/resource/${row.id}`" class="title-link">
                {{ row.title }}
              </router-link>
            </template>
          </el-table-column>
          <el-table-column prop="categoryName" label="分类" width="120" />
          <el-table-column prop="status" label="状态" width="100">
            <template #default="{ row }">
              <el-tag :type="getStatusType(row.status)" size="small">
                {{ getStatusText(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="viewCount" label="浏览" width="80" align="right" />
          <el-table-column prop="likeCount" label="点赞" width="80" align="right" />
          <el-table-column prop="favoriteCount" label="收藏" width="80" align="right" />
          <el-table-column prop="createTime" label="上传时间" width="150">
            <template #default="{ row }">
              {{ formatTime(row.createTime) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="140" fixed="right">
            <template #default="{ row }">
              <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
              <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
            </template>
          </el-table-column>

          <template #empty>
            <EmptyState
              icon="Document"
              title="还没有上传资料"
              description="上传第一份课程资料，和同学一起共享"
            >
              <el-button type="primary" @click="router.push('/upload')">上传资料</el-button>
            </EmptyState>
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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getMyResources, deleteResource } from '@/api/resource'
import { RESOURCE_STATUS_TAG_TYPE, RESOURCE_STATUS_MAP } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const router = useRouter()
const loading = ref(true)
const resources = ref([])

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const getStatusType = (status) => RESOURCE_STATUS_TAG_TYPE[status] || 'info'

const getStatusText = (status) => RESOURCE_STATUS_MAP[status] || '未知'

const fetchResources = async () => {
  loading.value = true
  try {
    const res = await getMyResources({
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

const handleEdit = (row) => {
  router.push(`/upload/${row.id}`)
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该资料吗？', '提示', {
      type: 'warning'
    })
    await deleteResource(row.id)
    ElMessage.success('删除成功')
    fetchResources()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to delete:', error)
    }
  }
}

onMounted(() => {
  fetchResources()
})
</script>

<style scoped>
.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-4);
  flex-wrap: wrap;
  margin-bottom: var(--space-5);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.panel-subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--text-secondary);
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

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-5);
}

@media (max-width: 767px) {
  .panel-head {
    flex-direction: column;
    align-items: stretch;
  }

  .panel-head .el-button {
    width: 100%;
  }
}
</style>
