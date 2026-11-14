<template>
  <div class="resource-list-page">
    <div class="container">
      <div class="page-head">
        <div class="page-head__text">
          <span class="breadcrumb">首页 / 资源广场</span>
          <h1 class="page-title">资源广场</h1>
        </div>
      </div>

      <div class="toolbar">
        <el-select
          v-model="filterForm.categoryId"
          placeholder="全部分类"
          clearable
          class="toolbar__select"
          @change="handleSearch"
        >
          <el-option
            v-for="category in categories"
            :key="category.id"
            :label="category.name"
            :value="category.id"
          />
        </el-select>

        <el-input
          v-model="filterForm.keyword"
          placeholder="搜索资料标题或描述"
          clearable
          class="toolbar__input"
          prefix-icon="Search"
          @keyup.enter="handleSearch"
          @clear="handleSearch"
        />

        <el-button type="primary" @click="handleSearch">搜索</el-button>

        <span v-if="!loading && !error" class="toolbar__count">
          共 {{ pagination.total }} 份资料
        </span>
      </div>

      <div v-if="loading" class="grid-auto">
        <SkeletonCard v-for="n in 6" :key="`skeleton-${n}`" :rows="2" />
      </div>

      <div v-else-if="error" class="state-panel">
        <EmptyState
          icon="Warning"
          title="资料加载失败"
          description="网络或服务暂时不可用，请稍后重试"
        >
          <el-button type="primary" @click="fetchResources">重新加载</el-button>
        </EmptyState>
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
            :page-sizes="[12, 24, 36, 48]"
            :total="pagination.total"
            layout="total, sizes, prev, pager, next, jumper"
            @size-change="handlePageChange"
            @current-change="handlePageChange"
          />
        </div>
      </div>

      <div v-else class="state-panel">
        <EmptyState
          icon="Search"
          title="没有找到相关资料"
          description="换个关键词或分类再试试"
        >
          <el-button @click="resetFilter">清除筛选条件</el-button>
        </EmptyState>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getResourceList, getCategories } from '@/api/resource'

const route = useRoute()
const loading = ref(true)
const error = ref(false)
const resources = ref([])
const categories = ref([])

const filterForm = reactive({
  categoryId: '',
  keyword: ''
})

const pagination = reactive({
  page: 1,
  size: 12,
  total: 0
})

const initFromQuery = () => {
  if (route.query.keyword) {
    filterForm.keyword = route.query.keyword
  }
  if (route.query.categoryId) {
    filterForm.categoryId = Number(route.query.categoryId)
  }
}

const fetchCategories = async () => {
  try {
    const res = await getCategories()
    categories.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch categories:', error)
  }
}

const fetchResources = async () => {
  loading.value = true
  error.value = false
  try {
    const res = await getResourceList({
      pageNum: pagination.page,
      pageSize: pagination.size,
      categoryId: filterForm.categoryId || undefined,
      keyword: filterForm.keyword || undefined
    })
    resources.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (err) {
    console.error('Failed to fetch resources:', err)
    resources.value = []
    pagination.total = 0
    error.value = true
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchResources()
}

const resetFilter = () => {
  filterForm.categoryId = ''
  filterForm.keyword = ''
  handleSearch()
}

const handlePageChange = () => {
  fetchResources()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(() => {
  initFromQuery()
  Promise.all([fetchCategories(), fetchResources()])
})
</script>

<style scoped>
.resource-list-page {
  padding: var(--section-gap-md) 0 var(--section-gap-lg);
}

.toolbar {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-wrap: wrap;
  padding: var(--space-3) var(--space-4);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  margin-bottom: var(--space-6);
}

.toolbar__select {
  width: 168px;
}

.toolbar__input {
  flex: 1;
  min-width: 200px;
  max-width: 360px;
}

.toolbar__count {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--text-secondary);
  white-space: nowrap;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: var(--space-7);
}

.state-panel {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
}

@media (max-width: 767px) {
  .resource-list-page {
    padding: var(--space-5) 0 var(--section-gap-md);
  }

  .toolbar {
    padding: var(--space-3);
    gap: var(--space-2);
  }

  .toolbar__select {
    width: 100%;
  }

  .toolbar__input {
    flex: 1 1 100%;
    max-width: none;
  }

  .toolbar__count {
    margin-left: 0;
    width: 100%;
  }
}
</style>
