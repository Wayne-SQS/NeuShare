<template>
  <div class="resource-list-page">
    <div class="page-container">
      <div class="filter-section">
        <el-form :inline="true" :model="filterForm" class="filter-form">
          <el-form-item>
            <el-autocomplete
              v-model="filterForm.keyword"
              :fetch-suggestions="querySuggest"
              placeholder="搜索资料，如「操作系统 期末」"
              clearable
              style="width: 300px"
              @keyup.enter="handleSearch"
              @select="handleSearch"
            >
              <template #append>
                <el-button icon="Search" @click="handleSearch" />
              </template>
            </el-autocomplete>
          </el-form-item>

          <el-form-item label="课程">
            <el-select
              v-model="filterForm.courseName"
              placeholder="全部课程"
              clearable
              filterable
              style="width: 160px"
              @change="handleSearch"
            >
              <el-option v-for="c in filterOptions.courses" :key="c" :label="c" :value="c" />
            </el-select>
          </el-form-item>

          <el-form-item label="教师">
            <el-select
              v-model="filterForm.teacher"
              placeholder="全部教师"
              clearable
              filterable
              style="width: 130px"
              @change="handleSearch"
            >
              <el-option v-for="t in filterOptions.teachers" :key="t" :label="t" :value="t" />
            </el-select>
          </el-form-item>

          <el-form-item label="分类">
            <el-select
              v-model="filterForm.categoryId"
              placeholder="全部分类"
              clearable
              style="width: 140px"
              @change="handleSearch"
            >
              <el-option
                v-for="category in categories"
                :key="category.id"
                :label="category.name"
                :value="category.id"
              />
            </el-select>
          </el-form-item>

          <el-form-item label="学年">
            <el-select
              v-model="filterForm.schoolYear"
              placeholder="全部学年"
              clearable
              style="width: 130px"
              @change="handleSearch"
            >
              <el-option v-for="y in schoolYears" :key="y" :label="y" :value="y" />
            </el-select>
          </el-form-item>

          <el-form-item label="学期">
            <el-select
              v-model="filterForm.term"
              placeholder="全部"
              clearable
              style="width: 110px"
              @change="handleSearch"
            >
              <el-option label="春季" value="spring" />
              <el-option label="夏季" value="summer" />
              <el-option label="秋季" value="autumn" />
              <el-option label="冬季" value="winter" />
            </el-select>
          </el-form-item>

          <el-form-item label="类型">
            <el-select
              v-model="filterForm.type"
              placeholder="全部类型"
              clearable
              style="width: 120px"
              @change="handleSearch"
            >
              <el-option label="文档" value="document" />
              <el-option label="视频" value="video" />
              <el-option label="图片" value="image" />
              <el-option label="外部链接" value="link" />
              <el-option label="其他" value="other" />
            </el-select>
          </el-form-item>

          <el-form-item label="排序">
            <el-select
              v-model="filterForm.sortBy"
              style="width: 120px"
              @change="handleSearch"
            >
              <el-option label="相关度" value="relevance" />
              <el-option label="最热" value="hot" />
              <el-option label="最新" value="new" />
            </el-select>
          </el-form-item>

          <el-form-item v-if="hasFilter">
            <el-button link type="primary" @click="resetFilter">清空筛选</el-button>
          </el-form-item>
        </el-form>
      </div>

      <div class="resource-list" v-loading="loading">
        <template v-if="resources.length > 0">
          <div class="resource-grid">
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
        </template>

        <el-empty v-else description="没有匹配的资料，换个关键词或清空筛选试试" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import {
  getResourceList,
  getCategories,
  getResourceFilters,
  suggestResources
} from '@/api/resource'

const route = useRoute()
const loading = ref(false)
const resources = ref([])
const categories = ref([])
const filterOptions = reactive({ courses: [], teachers: [] })

// 学年候选：以当前年份向前推四年，覆盖在校生常见的资料年限
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
  sortBy: 'relevance'
})

const pagination = reactive({
  page: 1,
  size: 12,
  total: 0
})

const hasFilter = computed(() =>
  Boolean(
    filterForm.keyword ||
      filterForm.categoryId ||
      filterForm.courseName ||
      filterForm.teacher ||
      filterForm.schoolYear ||
      filterForm.term ||
      filterForm.type
  )
)

// 支持从资源卡片的课程/教师/学年标签直接跳过来筛选
const initFromQuery = () => {
  const q = route.query
  if (q.keyword) filterForm.keyword = q.keyword
  if (q.categoryId) filterForm.categoryId = Number(q.categoryId)
  if (q.courseName) filterForm.courseName = q.courseName
  if (q.teacher) filterForm.teacher = q.teacher
  if (q.schoolYear) filterForm.schoolYear = q.schoolYear
  if (q.term) filterForm.term = q.term
  if (q.type) filterForm.type = q.type
}

const fetchCategories = async () => {
  try {
    const res = await getCategories()
    categories.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch categories:', error)
  }
}

// 课程与教师候选来自真实数据，避免给用户空选项
const fetchFilterOptions = async () => {
  try {
    const res = await getResourceFilters()
    filterOptions.courses = res.data?.courses || []
    filterOptions.teachers = res.data?.teachers || []
  } catch (error) {
    console.error('Failed to fetch filter options:', error)
  }
}

const fetchResources = async () => {
  loading.value = true
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
  } catch (error) {
    console.error('Failed to fetch resources:', error)
  } finally {
    loading.value = false
  }
}

// 搜索联想：输入时给标题候选，降低用户组织关键词的成本
const querySuggest = async (queryString, cb) => {
  if (!queryString) {
    cb([])
    return
  }
  try {
    const res = await suggestResources(queryString, 8)
    cb((res.data || []).map((title) => ({ value: title })))
  } catch (error) {
    cb([])
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

const resetFilter = () => {
  Object.assign(filterForm, {
    categoryId: '',
    keyword: '',
    courseName: '',
    teacher: '',
    schoolYear: '',
    term: '',
    type: '',
    sortBy: 'relevance'
  })
  handleSearch()
}

onMounted(() => {
  initFromQuery()
  Promise.all([fetchCategories(), fetchFilterOptions(), fetchResources()])
})

// 从资源卡片点标签进来时路由不变、只有 query 变，必须监听否则列表不刷新
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
  min-height: 100%;
  padding: 28px 0;
}

.page-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 28px;
}

.filter-section {
  background: var(--bg-surface);
  padding: 20px 24px;
  border-radius: var(--radius);
  margin-bottom: 24px;
  border: 1px solid var(--border-subtle);
}

.filter-form {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.resource-list {
  min-height: 400px;
}

.resource-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 36px;
  padding: 20px 0;
}

@media (max-width: 1200px) {
  .resource-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (max-width: 900px) {
  .resource-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 600px) {
  .resource-grid { grid-template-columns: 1fr; }
}
</style>
