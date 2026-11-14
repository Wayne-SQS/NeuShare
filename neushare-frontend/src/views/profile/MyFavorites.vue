<template>
  <div class="my-favorites-page">
    <div class="panel">
      <div class="panel-head">
        <div>
          <h3 class="panel-title">我的收藏</h3>
          <p class="panel-subtitle">收藏过的资料会出现在这里</p>
        </div>
      </div>

      <div v-if="loading" class="skeleton-list">
        <SkeletonCard v-for="n in 4" :key="`skeleton-${n}`" variant="list" :rows="2" />
      </div>

      <template v-else-if="favorites.length > 0">
        <div class="favorite-list">
          <div v-for="item in favorites" :key="item.id" class="favorite-item">
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
        </div>
      </template>

      <EmptyState
        v-else
        icon="Star"
        title="暂无收藏"
        description="浏览资源时点击收藏，方便之后回看"
      >
        <el-button type="primary" @click="router.push('/resource')">去资源广场</el-button>
      </EmptyState>

      <div v-if="!loading && pagination.total > 0" class="pagination">
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
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getFavorites, removeFavorite } from '@/api/favorite'

const router = useRouter()
const loading = ref(true)
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
.panel-head {
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

.favorite-list {
  display: flex;
  flex-direction: column;
}

.favorite-item {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-4);
  padding: var(--space-4) 0;
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

.title {
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin-bottom: var(--space-2);
  transition: var(--transition-fast);
}

.item-info:hover .title {
  color: var(--accent);
}

.description {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin-bottom: var(--space-2);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.meta {
  font-size: var(--text-xs);
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.meta-divider {
  width: 1px;
  height: 10px;
  background: var(--border-strong);
}

.item-actions {
  flex-shrink: 0;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-5);
}

@media (max-width: 767px) {
  .favorite-item {
    flex-direction: column;
    gap: var(--space-2);
  }

  .description {
    white-space: normal;
  }
}
</style>
