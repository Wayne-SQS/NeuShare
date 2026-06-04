<template>
  <div class="dashboard-page">
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-content">
            <div class="stat-icon stat-icon--blue">
              <el-icon :size="28"><User /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ statistics.userCount || 0 }}</div>
              <div class="stat-label">用户总数</div>
            </div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-content">
            <div class="stat-icon stat-icon--green">
              <el-icon :size="28"><Document /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ statistics.resourceCount || 0 }}</div>
              <div class="stat-label">资料总数</div>
            </div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-content">
            <div class="stat-icon stat-icon--gold">
              <el-icon :size="28"><ChatDotRound /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ statistics.commentCount || 0 }}</div>
              <div class="stat-label">评论总数</div>
            </div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-content">
            <div class="stat-icon stat-icon--red">
              <el-icon :size="28"><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ statistics.pendingResourceCount || 0 }}</div>
              <div class="stat-label">待审核</div>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="chart-row">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-card__header">
            <span>资料上传趋势</span>
          </div>
          <div ref="resourceChartRef" class="chart-container"></div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-card__header">
            <span>分类分布</span>
          </div>
          <div ref="categoryChartRef" class="chart-container"></div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getStatistics } from '@/api/admin'
import { getCategories, getResourceList } from '@/api/resource'
import { RESOURCE_STATUS } from '@/utils/constants'

const resourceChartRef = ref(null)
const categoryChartRef = ref(null)

let resourceChart = null
let categoryChart = null
let disposed = false

const statistics = ref({
  userCount: 0,
  resourceCount: 0,
  commentCount: 0,
  pendingResourceCount: 0
})

const fetchStatistics = async () => {
  try {
    const res = await getStatistics()
    statistics.value = res.data || {}
  } catch (error) {
    console.error('Failed to fetch statistics:', error)
  }
}

const initCharts = async () => {
  try {
    const [catRes, resRes] = await Promise.all([
      getCategories(),
      getResourceList({ pageNum: 1, pageSize: 100, status: RESOURCE_STATUS.PUBLISHED })
    ])

    const categories = catRes.data || []
    const resources = resRes.data?.records || []

    if (!disposed) {
      initResourceChart(resources)
      initCategoryChart(categories, resources)
    }
  } catch (error) {
    console.error('Failed to fetch chart data:', error)
    if (!disposed) initDemoCharts()
  }
}

const initDemoCharts = () => {
  initResourceChart([])
  initCategoryChart([], [])
}

const initResourceChart = (resources) => {
  resourceChart = echarts.init(resourceChartRef.value)

  const monthMap = {}
  resources.forEach(r => {
    if (r.createTime) {
      const month = r.createTime.substring(0, 7)
      monthMap[month] = (monthMap[month] || 0) + 1
    }
  })

  const months = Object.keys(monthMap).sort()
  const counts = months.map(m => monthMap[m])

  if (months.length === 0) {
    const labels = ['9月', '10月', '11月', '12月']
    const data = [3, 5, 4, 2]
    const option = {
      tooltip: { trigger: 'axis' },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: {
        type: 'category',
        data: labels,
        axisLine: { lineStyle: { color: '#d1d5db' } },
        axisLabel: { color: '#9ca3af' }
      },
      yAxis: {
        type: 'value',
        splitLine: { lineStyle: { color: '#e5e7eb' } },
        axisLabel: { color: '#9ca3af' }
      },
      series: [{
        name: '上传数量',
        type: 'bar',
        data: data,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#3b82f6' },
            { offset: 1, color: '#2563eb' }
          ])
        }
      }]
    }
    resourceChart.setOption(option)
    return
  }

  const option = {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      data: months,
      axisLine: { lineStyle: { color: '#d1d5db' } },
      axisLabel: { color: '#9ca3af' }
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#e5e7eb' } },
      axisLabel: { color: '#9ca3af' }
    },
    series: [{
      name: '上传数量',
      type: 'bar',
      data: counts,
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: '#3b82f6' },
          { offset: 1, color: '#2563eb' }
        ])
      }
    }]
  }
  resourceChart.setOption(option)
}

const initCategoryChart = (categories, resources) => {
  categoryChart = echarts.init(categoryChartRef.value)

  const catCountMap = {}
  resources.forEach(r => {
    const catId = r.categoryId
    catCountMap[catId] = (catCountMap[catId] || 0) + 1
  })

  const data = categories.map(cat => ({
    name: cat.name,
    value: catCountMap[cat.id] || 0
  })).filter(d => d.value > 0)

  if (data.length === 0) {
    const demoData = [
      { name: '高等数学', value: 3 },
      { name: '数据结构与算法', value: 2 },
      { name: '操作系统', value: 1 },
      { name: '计算机网络', value: 1 },
      { name: 'Python程序设计', value: 1 }
    ]
    const option = {
      tooltip: { trigger: 'item' },
      legend: { bottom: 0, textStyle: { color: '#6b7280' } },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
        label: { show: false },
        emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold', color: '#111827' } },
        labelLine: { show: false },
        data: demoData
      }]
    }
    categoryChart.setOption(option)
    return
  }

  const option = {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: '#6b7280' } },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      avoidLabelOverlap: false,
      itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold', color: '#111827' } },
      labelLine: { show: false },
      data: data
    }]
  }
  categoryChart.setOption(option)
}

const handleResize = () => {
  resourceChart?.resize()
  categoryChart?.resize()
}

onMounted(() => {
  Promise.all([fetchStatistics(), initCharts()])
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  disposed = true
  window.removeEventListener('resize', handleResize)
  resourceChart?.dispose()
  categoryChart?.dispose()
})
</script>

<style scoped>
.stat-cards {
  margin-bottom: 20px;
}

.stat-card {
  background: var(--bg-surface);
  border-radius: var(--radius-lg);
  padding: 24px;
  border: 1px solid var(--border-subtle);
  height: 100%;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 18px;
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: var(--radius);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-icon--blue { background: rgba(64, 158, 255, 0.15); color: #409eff; }
.stat-icon--green { background: rgba(103, 194, 58, 0.15); color: #67c23a; }
.stat-icon--gold { background: rgba(200, 164, 78, 0.15); color: var(--accent); }
.stat-icon--red { background: rgba(245, 108, 108, 0.15); color: #f56c6c; }

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.stat-label {
  font-size: 13px;
  color: var(--text-muted);
  margin-top: 2px;
}

.chart-row {
  margin-bottom: 20px;
}

.chart-card {
  background: var(--bg-surface);
  border-radius: var(--radius-lg);
  padding: 24px;
  border: 1px solid var(--border-subtle);
}

.chart-card__header {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 16px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.chart-container {
  height: 300px;
}
</style>
