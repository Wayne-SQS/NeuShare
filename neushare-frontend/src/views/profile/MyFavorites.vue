<template>
  <div class="my-favorites-page">
    <div class="favorites-card">
      <div class="card-header">
        <span>我的收藏</span>
      </div>

      <div class="favorite-list" v-loading="loading">
        <template v-if="favorites.length > 0">
          <div
            v-for="item in favorites"
            :key="item.id"
            class="favorite-item"
          >
            <div class="item-info" @click="goToDetail(item.id)">
              <h3 class="title">{{ item.title }}</h3>
              <p class="description">{{ item.description || '暂无描述' }}</p>
              <div class="meta">
                <span>{{ item.uploadNickname || '匿名' }}</span>
                <span class="meta-divider"></span>
                <span>{{ item.categoryName || '未分类' }}</span>
                <span class="meta-divider"></span>
                <span>{{ item.viewCount || 0 }} 浏览</span>
              </div>
            </div>
            <div class="item-actions">
              <el-button type="danger" link @click="handleRemove(item.id)">
                取消收藏
              </el-button>
            </div>
          </div>
        </template>
        <el-empty v-else description="暂无收藏" />
      </div>

      <div class="pagination" v-if="pagination.total > 0">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :total="pagination.total"
          layout="total, prev, pager, next"
          @current-change="fetchFavorites"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getFavorites, removeFavorite } from '@/api/favorite'

const router = useRouter()
const loading = ref(false)
const favorites = ref([])

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const fetchFavorites = async () => {
  loading.value = true
  try {
    const res = await getFavorites({
      pageNum: pagination.page,
      pageSize: pagination.size
    })
    favorites.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (error) {
    console.error('Failed to fetch favorites:', error)
  } finally {
    loading.value = false
  }
}

const goToDetail = (id) => {
  router.push(`/resource/${id}`)
}

const handleRemove = async (resourceId) => {
  try {
    await ElMessageBox.confirm('确定要取消收藏吗？', '提示', {
      type: 'warning'
    })
    await removeFavorite(resourceId)
    ElMessage.success('已取消收藏')
    fetchFavorites()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to remove:', error)
    }
  }
}

onMounted(() => {
  fetchFavorites()
})
</script>

<style scoped>
.favorites-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
}

.card-header {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 20px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.favorite-list {
  min-height: 300px;
}

.favorite-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 0;
  border-bottom: 1px solid var(--border-subtle);
}

.favorite-item:last-child {
  border-bottom: none;
}

.item-info {
  flex: 1;
  cursor: pointer;
  min-width: 0;
}

.item-info:hover .title {
  color: var(--accent);
}

.title {
  font-size: 16px;
  color: var(--text-primary);
  margin-bottom: 8px;
  transition: var(--transition-fast);
}

.description {
  font-size: 14px;
  color: var(--text-muted);
  margin-bottom: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.meta {
  font-size: 12px;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 10px;
}

.meta-divider {
  width: 1px;
  height: 10px;
  background: var(--border-strong);
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}
</style>
