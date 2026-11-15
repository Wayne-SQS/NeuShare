<template>
  <div class="resource-list-page">
    <div class="page-container">
      <nav class="breadcrumb">
        <router-link to="/">首页</router-link><span>/</span>
        <router-link to="/resource">资源广场</router-link><span>/</span>
        <span>全部资料</span>
      </nav>

      <header class="page-head">
        <div>
          <h1>资源广场</h1>
          <p>按分类、课程与关键词检索；支持按热度、最新与收藏数排序。</p>
        </div>
        <span class="page-count">共 {{ pagination.total }} 份已审核资料</span>
      </header>

      <div class="toolbar">
        <el-input v-model="filterForm.keyword" placeholder="搜索课程名或资料标题" clearable @keyup.enter="handleSearch">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="filterForm.categoryId" placeholder="全部分类" clearable class="toolbar-select" @change="handleSearch">
          <el-option v-for="category in categories" :key="category.id" :label="category.name" :value="category.id" />
        </el-select>
        <el-select v-model="sortBy" class="toolbar-select toolbar-select--sort">
          <el-option label="按热度" value="hot" />
          <el-option label="按最新" value="latest" />
          <el-option label="按收藏" value="favorites" />
        </el-select>
        <button class="view-toggle" type="button" :title="viewMode === 'grid' ? '切换列表视图' : '切换网格视图'" @click="toggleView">
          <el-icon><Grid /></el-icon>
        </button>
        <span class="toolbar-count">已筛选 {{ pagination.total }} 条</span>
        <button class="reset-btn" type="button" @click="resetFilters">重置</button>
      </div>

      <div class="content-layout">
        <aside class="category-panel">
          <h3>资料分类</h3>
          <button
            type="button"
            :class="['category-item', { 'category-item--active': !filterForm.categoryId }]"
            @click="selectCategory('')"
          >
            <span>全部资料</span><em>{{ pagination.total }}</em>
          </button>
          <button
            v-for="category in categories"
            :key="category.id"
            type="button"
            :class="['category-item', { 'category-item--active': filterForm.categoryId === category.id }]"
            @click="selectCategory(category.id)"
          >
            <span>{{ category.name }}</span>
          </button>
        </aside>

        <div class="resource-list" v-loading="loading">
          <template v-if="sortedResources.length > 0">
            <div :class="['resource-grid', `resource-grid--${viewMode}`]">
              <ResourceCard v-for="resource in sortedResources" :key="resource.id" :resource="resource" />
            </div>
            <div class="pagination">
              <el-pagination
                v-model:current-page="pagination.page"
                v-model:page-size="pagination.size"
                :page-sizes="[12, 24, 36, 48]"
                :total="pagination.total"
                layout="prev, pager, next, jumper"
                @size-change="handlePageChange"
                @current-change="handlePageChange"
              />
              <span class="pagination-hint">每页 {{ pagination.size }} 条 · 共 {{ Math.ceil(pagination.total / pagination.size) || 1 }} 页</span>
            </div>
          </template>
          <el-empty v-else description="暂无资料" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import { getResourceList, getCategories } from '@/api/resource'

const route = useRoute()
const loading = ref(false)
const resources = ref([])
const categories = ref([])
const sortBy = ref('hot')
const viewMode = ref('grid')

const filterForm = reactive({
  categoryId: '',
  keyword: ''
})

const pagination = reactive({
  page: 1,
  size: 12,
  total: 0
})

// 排序只作用于当前页数据（接口未暴露排序参数），切换页码后重新生效
const sortedResources = computed(() => {
  const list = [...resources.value]
  const num = (v) => Number(v) || 0
  if (sortBy.value === 'latest') {
    return list.sort((a, b) => String(b.createTime || '').localeCompare(String(a.createTime || '')))
  }
  if (sortBy.value === 'favorites') {
    return list.sort((a, b) => num(b.favoriteCount ?? b.likeCount) - num(a.favoriteCount ?? a.likeCount))
  }
  return list.sort((a, b) => num(b.viewCount) - num(a.viewCount))
})

const initFromQuery = () => {
  if (route.query.keyword) filterForm.keyword = route.query.keyword
  if (route.query.categoryId) filterForm.categoryId = Number(route.query.categoryId)
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
  try {
    const res = await getResourceList({
      pageNum: pagination.page,
      pageSize: pagination.size,
      categoryId: filterForm.categoryId || undefined,
      keyword: filterForm.keyword || undefined
    })
    resources.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (error) {
    console.error('Failed to fetch resources:', error)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchResources()
}

const handlePageChange = () => {
  fetchResources()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const selectCategory = (id) => {
  filterForm.categoryId = id
  handleSearch()
}

const toggleView = () => {
  viewMode.value = viewMode.value === 'grid' ? 'list' : 'grid'
}

const resetFilters = () => {
  filterForm.keyword = ''
  filterForm.categoryId = ''
  sortBy.value = 'hot'
  pagination.page = 1
  fetchResources()
}

onMounted(() => {
  initFromQuery()
  Promise.all([fetchCategories(), fetchResources()])
})
</script>

<style scoped>
.resource-list-page {
  min-height: 100%;
  padding: 28px 0 64px;
}

.page-container {
  max-width: 1160px;
  margin: 0 auto;
  padding: 0 28px;
}

.breadcrumb {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 22px;
}

.breadcrumb a { color: var(--text-muted); text-decoration: none; }
.breadcrumb a:hover { color: var(--accent); }

.page-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 24px;
}

.page-head h1 {
  font-size: 30px;
  font-weight: 700;
  letter-spacing: -0.03em;
  color: var(--text-primary);
}

.page-head p {
  margin-top: 8px;
  font-size: 13px;
  color: var(--text-secondary);
}

.page-count {
  flex-shrink: 0;
  font-size: 12px;
  color: var(--text-muted);
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 18px;
  margin-bottom: 22px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
}

.toolbar :deep(.el-input__wrapper),
.toolbar :deep(.el-select__wrapper) {
  box-shadow: none;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  background: var(--bg-elevated);
}

.toolbar > .el-input { flex: 1; min-width: 180px; }
.toolbar-select { width: 140px; flex-shrink: 0; }
.toolbar-select--sort { width: 120px; }

.view-toggle {
  width: 34px;
  height: 32px;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  background: rgba(var(--accent-rgb), 0.08);
  color: var(--accent);
  cursor: pointer;
}

.toolbar-count {
  font-size: 12px;
  color: var(--text-muted);
  white-space: nowrap;
}

.reset-btn {
  border: none;
  background: transparent;
  color: var(--accent);
  font-size: 12px;
  cursor: pointer;
  white-space: nowrap;
}

.content-layout {
  display: grid;
  grid-template-columns: 200px 1fr;
  gap: 22px;
  align-items: start;
}

.category-panel {
  padding: 18px 12px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
}

.category-panel h3 {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
  padding: 0 12px 12px;
}

.category-item {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 9px 12px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-secondary);
  font-size: 13px;
  text-align: left;
  cursor: pointer;
  transition: var(--transition-fast);
}

.category-item:hover { background: var(--bg-hover); color: var(--text-primary); }

.category-item--active {
  background: rgba(var(--accent-rgb), 0.10);
  color: var(--accent);
  font-weight: 600;
}

.category-item em {
  font-family: var(--font-mono);
  font-style: normal;
  font-size: 11px;
  opacity: 0.7;
}

.resource-list { min-height: 400px; }

.resource-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}

.resource-grid--list { grid-template-columns: 1fr; }

.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 32px;
  padding: 18px 0;
}

.pagination-hint {
  font-size: 12px;
  color: var(--text-muted);
  white-space: nowrap;
}

@media (max-width: 1000px) {
  .content-layout { grid-template-columns: 1fr; }
  .category-panel { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
  .category-panel h3 { width: 100%; padding-bottom: 4px; }
  .category-item { width: auto; }
  .resource-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 640px) {
  .page-head { flex-direction: column; align-items: flex-start; }
  .toolbar { flex-wrap: wrap; }
  .toolbar > .el-input { width: 100%; flex: 1 1 100%; }
  .resource-grid { grid-template-columns: 1fr; }
  .pagination { flex-direction: column; }
}
</style>
