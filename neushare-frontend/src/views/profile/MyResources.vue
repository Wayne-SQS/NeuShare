<template>
  <div class="my-resources-page">
    <div class="resources-card">
      <div class="card-header">
        <span>我的资料</span>
        <el-button type="primary" @click="router.push('/upload')">
          <el-icon><Plus /></el-icon>上传资料
        </el-button>
      </div>

      <el-table :data="resources" v-loading="loading" stripe>
        <el-table-column prop="title" label="标题" min-width="200">
          <template #default="{ row }">
            <router-link :to="`/resource/${row.id}`" class="title-link">
              {{ row.title }}
            </router-link>
          </template>
        </el-table-column>
        <el-table-column prop="categoryName" label="分类" width="120" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="viewCount" label="浏览" width="80" />
        <el-table-column prop="likeCount" label="点赞" width="80" />
        <el-table-column prop="favoriteCount" label="收藏" width="80" />
        <el-table-column prop="createTime" label="上传时间" width="160">
          <template #default="{ row }">
            {{ formatTime(row.createTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getMyResources, deleteResource } from '@/api/resource'
import { RESOURCE_STATUS_TAG_TYPE, RESOURCE_STATUS_MAP } from '@/utils/constants'
import { formatTime } from '@/utils/format'

const router = useRouter()
const loading = ref(false)
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
.resources-card {
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

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}
</style>
