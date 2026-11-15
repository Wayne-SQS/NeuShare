<template>
  <div class="dashboard-page">
    <header class="dash-head">
      <div class="dash-crumb">管理后台 <span>/</span> 数据统计</div>
      <div class="range-switch">
        <button v-for="d in [7, 30, 90]" :key="d" type="button" :class="{ 'is-active': range === d }" @click="setRange(d)">{{ d }} 天</button>
      </div>
      <button class="export-btn" type="button" @click="exportCsv">导出 CSV <i>/ EXPORT</i></button>
    </header>

    <div class="kpi-grid">
      <div v-for="k in kpis" :key="k.label" class="kpi-card">
        <span class="kpi-label">{{ k.label }}</span>
        <strong class="kpi-value">{{ k.value }}</strong>
        <span class="kpi-hint">{{ k.hint }}</span>
      </div>
    </div>

    <div class="chart-grid">
      <div class="chart-card">
        <div class="chart-head"><h3>资料上传趋势</h3><span>/ 近 {{ range }} 天</span></div>
        <div ref="resourceChartRef" class="chart-container"></div>
      </div>
      <div class="chart-card">
        <div class="chart-head"><h3>分类分布</h3><span>/ CATEGORY</span></div>
        <div ref="categoryChartRef" class="chart-container"></div>
      </div>
    </div>

    <div class="pending-card">
      <div class="pending-head">
        <h3>待审核资料 <span>· {{ statistics.pendingResourceCount || 0 }}</span></h3>
        <router-link to="/admin/audit">查看全部 <i>/ ALL</i></router-link>
      </div>
      <div class="pending-table">
        <div class="pending-row pending-row--head">
          <span>资料标题</span><span>上传者</span><span>提交时间</span><span>状态</span>
        </div>
        <div v-for="item in pendingList" :key="item.id" class="pending-row">
          <span class="pending-title">{{ item.title }}</span>
          <span>{{ item.uploadNickname || '匿名' }}</span>
          <span>{{ formatTime(item.createTime) }}</span>
          <span class="pending-status">待审核</span>
        </div>
        <div v-if="!pendingList.length" class="pending-empty">暂无待审核资料</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getStatistics } from '@/api/admin'
import { getCategories, getResourceList } from '@/api/resource'
import { RESOURCE_STATUS } from '@/utils/constants'
import { getTheme } from '@/utils/theme'
import { formatTime } from '@/utils/format'

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

const range = ref(30)
const pendingList = ref([])

const kpis = computed(() => [
  { label: '用户总数', value: statistics.value.userCount || 0, hint: '平台累计' },
  { label: '资料总数', value: statistics.value.resourceCount || 0, hint: '已发布资料' },
  { label: '评论总数', value: statistics.value.commentCount || 0, hint: '互动累计' },
  { label: '待审核', value: statistics.value.pendingResourceCount || 0, hint: '需今日处理' }
])

const setRange = (days) => {
  range.value = days
  resourceChart?.dispose()
  categoryChart?.dispose()
  resourceChart = null
  categoryChart = null
  initCharts()
}

const fetchPending = async () => {
  try {
    const res = await getResourceList({ pageNum: 1, pageSize: 3, status: RESOURCE_STATUS.PENDING })
    pendingList.value = res.data?.records || []
  } catch (error) {
    console.error('Failed to fetch pending list:', error)
  }
}

// 导出当前统计为 CSV，纯前端生成，不依赖后端
const exportCsv = () => {
  const rows = [
    ['指标', '数值'],
    ['用户总数', statistics.value.userCount || 0],
    ['资料总数', statistics.value.resourceCount || 0],
    ['评论总数', statistics.value.commentCount || 0],
    ['待审核', statistics.value.pendingResourceCount || 0]
  ]
  const csv = '\ufeff' + rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\r\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
  const a = document.createElement('a')
  a.href = url
  a.download = 'neushare-statistics.csv'
  a.click()
  URL.revokeObjectURL(url)
}


const chartColors = () => {
  const cs = getComputedStyle(document.documentElement)
  const v = (name, fallback) => (cs.getPropertyValue(name) || fallback).trim()
  const dark = getTheme() === 'dark'
  return {
    axis: v('--border-strong', '#d1d5db'),
    label: v('--text-muted', '#9ca3af'),
    split: v('--border-default', '#e5e7eb'),
    legend: v('--text-secondary', '#6b7280'),
    emphasis: v('--text-primary', '#111827'),
    pieBorder: v('--bg-surface', '#ffffff'),
    barTop: dark ? '#E8E8EA' : v('--accent-light', '#3b82f6'),
    barBottom: dark ? '#6A6A72' : v('--accent', '#2563eb'),
    pie: dark
      ? ['#E8E8EA', '#B8B8BE', '#8A8A90', '#5E5E64', '#3A3A40']
      : [v('--accent', '#4A6BFF'), '#00C2CB', '#FF8FB1', '#FFD93D', '#6BCB77']
  }
}

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
    const all = resRes.data?.records || []
    const cutoff = Date.now() - range.value * 24 * 60 * 60 * 1000
    const resources = all.filter(r => {
      if (!r.createTime) return true
      const ts = new Date(String(r.createTime).replace(/-/g, '/')).getTime()
      return Number.isNaN(ts) || ts >= cutoff
    })

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
  const c = chartColors()
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
        axisLine: { lineStyle: { color: c.axis } },
        axisLabel: { color: c.label }
      },
      yAxis: {
        type: 'value',
        splitLine: { lineStyle: { color: c.split } },
        axisLabel: { color: c.label }
      },
      series: [{
        name: '上传数量',
        type: 'bar',
        data: data,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: c.barTop },
            { offset: 1, color: c.barBottom }
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
      axisLine: { lineStyle: { color: c.axis } },
      axisLabel: { color: c.label }
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: c.split } },
      axisLabel: { color: c.label }
    },
    series: [{
      name: '上传数量',
      type: 'bar',
      data: counts,
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: c.barTop },
          { offset: 1, color: c.barBottom }
        ])
      }
    }]
  }
  resourceChart.setOption(option)
}

const initCategoryChart = (categories, resources) => {
  const c = chartColors()
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
      color: c.pie,
      legend: { bottom: 0, textStyle: { color: c.legend } },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: { borderRadius: 8, borderColor: c.pieBorder, borderWidth: 2 },
        label: { show: false },
        emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold', color: c.emphasis } },
        labelLine: { show: false },
        data: demoData
      }]
    }
    categoryChart.setOption(option)
    return
  }

  const option = {
    tooltip: { trigger: 'item' },
    color: c.pie,
    legend: { bottom: 0, textStyle: { color: c.legend } },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      avoidLabelOverlap: false,
      itemStyle: { borderRadius: 8, borderColor: c.pieBorder, borderWidth: 2 },
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold', color: c.emphasis } },
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

const handleThemeChange = () => {
  if (disposed) return
  resourceChart?.dispose()
  categoryChart?.dispose()
  resourceChart = null
  categoryChart = null
  initCharts()
}

onMounted(() => {
  Promise.all([fetchStatistics(), initCharts(), fetchPending()])
  window.addEventListener('resize', handleResize)
  window.addEventListener('ns-theme-change', handleThemeChange)
})

onUnmounted(() => {
  disposed = true
  window.removeEventListener('resize', handleResize)
  window.removeEventListener('ns-theme-change', handleThemeChange)
  resourceChart?.dispose()
  categoryChart?.dispose()
})
</script>

<style scoped>
.dashboard-page { display: flex; flex-direction: column; gap: 18px; }

.dash-head { display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.dash-crumb { font-size: 13px; color: var(--text-secondary); }
.dash-crumb span { margin: 0 6px; color: var(--text-muted); }

.range-switch {
  display: inline-flex; padding: 3px; gap: 2px;
  border: 1px solid var(--border-default); border-radius: var(--radius-full);
  background: var(--bg-surface);
}
.range-switch button {
  border: none; background: transparent; cursor: pointer;
  padding: 5px 14px; border-radius: var(--radius-full);
  font-size: 12px; color: var(--text-muted);
}
.range-switch button.is-active { background: var(--bg-hover); color: var(--text-primary); font-weight: 600; }

.export-btn {
  border: none; background: transparent; cursor: pointer;
  font-size: 12px; font-weight: 600; color: var(--text-primary);
}
.export-btn i { font-style: normal; font-family: var(--font-mono); color: var(--text-muted); margin-left: 4px; }
.export-btn:hover { color: var(--accent); }

.kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.kpi-card {
  display: flex; flex-direction: column; gap: 8px;
  padding: 22px 24px; border-radius: var(--radius-lg);
  background: var(--bg-surface); border: 1px solid var(--border-default);
}
.kpi-label { font-size: 12px; color: var(--text-secondary); }
.kpi-value {
  font-family: var(--font-mono); font-size: 30px; font-weight: 700;
  line-height: 1.1; letter-spacing: -0.03em; color: var(--text-primary);
}
.kpi-hint { font-size: 11px; color: var(--text-muted); }

.chart-grid { display: grid; grid-template-columns: 1.55fr 1fr; gap: 16px; }
.chart-card {
  padding: 22px 24px; border-radius: var(--radius-lg);
  background: var(--bg-surface); border: 1px solid var(--border-default);
}
.chart-head { display: flex; align-items: baseline; gap: 10px; margin-bottom: 12px; }
.chart-head h3 { font-size: 14px; font-weight: 600; color: var(--text-primary); }
.chart-head span {
  font-family: var(--font-mono); font-size: 10px;
  letter-spacing: 0.06em; color: var(--text-muted);
}
.chart-container { height: 260px; }

.pending-card {
  padding: 22px 24px; border-radius: var(--radius-lg);
  background: var(--bg-surface); border: 1px solid var(--border-default);
}
.pending-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.pending-head h3 { font-size: 14px; font-weight: 600; color: var(--text-primary); }
.pending-head h3 span { font-family: var(--font-mono); color: var(--text-muted); }
.pending-head a { font-size: 12px; font-weight: 600; color: var(--accent); text-decoration: none; }
.pending-head a i { font-style: normal; font-family: var(--font-mono); color: var(--text-muted); margin-left: 4px; }

.pending-row {
  display: grid; grid-template-columns: 2fr 1fr 1fr 0.6fr; gap: 12px;
  align-items: center; padding: 12px 4px;
  border-top: 1px solid var(--border-subtle);
  font-size: 12px; color: var(--text-secondary);
}
.pending-row--head {
  border-top: none; padding-top: 4px; padding-bottom: 8px;
  font-size: 11px; color: var(--text-muted);
}
.pending-title { color: var(--text-primary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pending-status {
  justify-self: start; padding: 3px 10px; border-radius: var(--radius-full);
  border: 1px solid var(--border-strong); color: var(--text-primary);
  font-size: 11px; font-weight: 600;
}
.pending-empty { padding: 24px 0 8px; text-align: center; font-size: 12px; color: var(--text-muted); }

@media (max-width: 1100px) {
  .kpi-grid { grid-template-columns: repeat(2, 1fr); }
  .chart-grid { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
  .kpi-grid { grid-template-columns: 1fr; }
  .pending-row { grid-template-columns: 1.6fr 1fr; }
  .pending-row span:nth-child(3), .pending-row span:nth-child(4) { display: none; }
}
</style>
