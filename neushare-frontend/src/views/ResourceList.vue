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

        <el-autocomplete
          v-model="filterForm.keyword"
          :fetch-suggestions="querySuggest"
          placeholder="搜索资料标题或描述"
          clearable
          class="toolbar__input"
          @keyup.enter="handleSearch"
          @select="handleSearch"
          @clear="handleSearch"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-autocomplete>

        <!-- V5/V6 结构化筛选：选项来自 /resource/filters 的真实数据 -->
        <el-select v-model="filterForm.courseName" placeholder="全部课程" clearable filterable class="toolbar__select" @change="handleSearch">
          <el-option v-for="c in filterOptions.courses" :key="c" :label="c" :value="c" />
        </el-select>
        <el-select v-model="filterForm.teacher" placeholder="全部教师" clearable filterable class="toolbar__select" @change="handleSearch">
          <el-option v-for="t in filterOptions.teachers" :key="t" :label="t" :value="t" />
        </el-select>
        <el-select v-model="filterForm.schoolYear" placeholder="全部学年" clearable class="toolbar__select" @change="handleSearch">
          <el-option v-for="y in schoolYears" :key="y" :label="y" :value="y" />
        </el-select>
        <el-select v-model="filterForm.term" placeholder="全部学期" clearable class="toolbar__select" @change="handleSearch">
          <el-option label="春季" value="spring" /><el-option label="夏季" value="summer" />
          <el-option label="秋季" value="autumn" /><el-option label="冬季" value="winter" />
        </el-select>
        <el-select v-model="filterForm.type" placeholder="全部类型" clearable class="toolbar__select" @change="handleSearch">
          <el-option label="文档" value="document" /><el-option label="视频" value="video" />
          <el-option label="图片" value="image" /><el-option label="外部链接" value="link" />
          <el-option label="其他" value="other" />
        </el-select>
        <el-select v-model="filterForm.sortBy" class="toolbar__select" @change="handleSearch">
          <el-option label="相关度" value="relevance" /><el-option label="按热度" value="hot" />
          <el-option label="按最新" value="new" />
        </el-select>

        <el-button type="primary" @click="handleSearch">搜索</el-button>
        <el-button v-if="hasFilter" link @click="resetFilter">重置</el-button>

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
            :keyword="filterForm.keyword"
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
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getResourceList, getCategories, getResourceFilters, suggestResources } from '@/api/resource'

const route = useRoute()
const loading = ref(true)
const error = ref(false)
const resources = ref([])
const categories = ref([])

const filterOptions = reactive({ courses: [], teachers: [] })
const currentYear = new Date().getFullYear()
const schoolYears = Array.from({ length: 5 }, (_, i) => {
  const start = currentYear - i
  return `${start}-${start + 1}`
})

const filterForm = reactive({
  categoryId: '',
  keyword: '',
  courseName: '',
  teacher: '',
  schoolYear: '',
  term: '',
  type: '',
  sortBy: 'new'
})

const hasFilter = computed(() => Boolean(
  filterForm.keyword || filterForm.categoryId || filterForm.courseName ||
  filterForm.teacher || filterForm.schoolYear || filterForm.term || filterForm.type
))

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
  for (const key of ['courseName', 'teacher', 'schoolYear', 'term', 'type']) {
    if (route.query[key]) filterForm[key] = route.query[key]
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

const fetchFilterOptions = async () => {
  try {
    const res = await getResourceFilters()
    filterOptions.courses = res.data?.courses || []
    filterOptions.teachers = res.data?.teachers || []
  } catch (err) {
    console.error('Failed to fetch filter options:', err)
  }
}

const querySuggest = async (queryString, cb) => {
  if (!queryString) { cb([]); return }
  try {
    const res = await suggestResources(queryString, 8)
    cb((res.data || []).map((title) => ({ value: title })))
  } catch (err) {
    cb([])
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
      keyword: filterForm.keyword || undefined,
      courseName: filterForm.courseName || undefined,
      teacher: filterForm.teacher || undefined,
      schoolYear: filterForm.schoolYear || undefined,
      term: filterForm.term || undefined,
      type: filterForm.type || undefined,
      sortBy: filterForm.sortBy
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
  Object.assign(filterForm, {
    categoryId: '', keyword: '', courseName: '', teacher: '',
    schoolYear: '', term: '', type: '', sortBy: 'new'
  })
  handleSearch()
}

const handlePageChange = () => {
  fetchResources()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(() => {
  initFromQuery()
  Promise.all([fetchCategories(), fetchFilterOptions(), fetchResources()])
})

// 卡片标签点进来时路由不变、只有 query 变，必须监听否则列表不刷新
watch(
  () => route.query,
  (next, prev) => {
    if (JSON.stringify(next) === JSON.stringify(prev)) return
    initFromQuery()
    handleSearch()
  }
)
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
