<template>
  <div class="resource-list-page">
    <div class="page-container">
      <div class="filter-section">
        <el-form :inline="true" :model="filterForm" class="filter-form">
          <el-form-item label="分类">
            <el-select
              v-model="filterForm.categoryId"
              placeholder="全部分类"
              clearable
              style="width: 160px"
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
          <el-form-item>
            <el-input
              v-model="filterForm.keyword"
              placeholder="搜索资料..."
              clearable
              style="width: 280px"
              @keyup.enter="handleSearch"
            >
              <template #append>
                <el-button icon="Search" @click="handleSearch" />
              </template>
            </el-input>
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

        <el-empty v-else description="暂无资料" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import { getResourceList, getCategories } from '@/api/resource'

const route = useRoute()
const loading = ref(false)
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

onMounted(() => {
  initFromQuery()
  Promise.all([fetchCategories(), fetchResources()])
})
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
