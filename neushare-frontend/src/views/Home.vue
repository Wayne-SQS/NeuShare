<template>
  <div class="home-page">
    <section class="hero-section">
      <div class="hero-content">
        <div class="hero-badge animate-fade-in">
          <span class="badge-dot"></span>
          东北大学专属
        </div>
        <h1 class="hero-title animate-slide-up">发现优质<br>学习资料</h1>
        <p class="hero-subtitle animate-slide-up stagger-1">与同学们一起，让学习更高效</p>
        <div class="hero-actions animate-slide-up stagger-2">
          <el-button class="hero-btn-primary" size="large" @click="$router.push('/resource')">
            <el-icon><Search /></el-icon>浏览资源
          </el-button>
          <el-button class="hero-btn-outline" size="large" @click="$router.push('/upload')">
            <el-icon><Upload /></el-icon>上传分享
          </el-button>
        </div>
      </div>
    </section>

    <section class="section course-filter-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-badge">快捷查找</span>
          <h2>按年级学期查找课程资料</h2>
          <p class="section-desc">选择对应的年级学期，快速查找课程相关学习资料</p>
        </div>
      </div>

      <div class="filter-container">
        <div class="grade-semester-grid">
          <div
            v-for="option in gradeSemesterOptions"
            :key="option.key"
            :class="['grade-btn', { 'grade-btn--active': selectedOption === option.key }]"
            @click="selectOption(option.key)"
          >
            <div class="grade-btn__icon">
              <el-icon><Reading /></el-icon>
            </div>
            <span class="grade-btn__label">{{ option.label }}</span>
          </div>
        </div>

        <transition name="slide-fade">
          <div v-if="currentCourses.length > 0" class="courses-panel">
            <div class="courses-header">
              <div class="courses-header-left">
                <el-icon class="courses-header-icon"><Collection /></el-icon>
                <span class="courses-title">{{ currentLabel }} 课程</span>
              </div>
              <span class="courses-count">共 {{ currentCourses.length }} 门课程</span>
            </div>
            <div class="courses-grid">
              <div
                v-for="(course, index) in currentCourses"
                :key="course.id"
                class="course-card"
                :style="{ animationDelay: `${index * 0.05}s` }"
                @click="goToCourseResources(course)"
              >
                <div class="course-card__icon">
                  <el-icon><Document /></el-icon>
                </div>
                <div class="course-card__content">
                  <span class="course-card__name">{{ course.name }}</span>
                  <span class="course-card__hint">点击查看资料</span>
                </div>
                <el-icon class="course-card__arrow"><ArrowRight /></el-icon>
              </div>
            </div>
          </div>
        </transition>
      </div>
    </section>

    <section class="section hot-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-badge section-badge--accent">热门</span>
          <h2>热门资料</h2>
        </div>
        <router-link to="/resource" class="view-more">
          查看更多 <el-icon><ArrowRight /></el-icon>
        </router-link>
      </div>
      <div class="resource-grid">
        <ResourceCard
          v-for="(resource, index) in hotResources"
          :key="resource.id"
          :resource="resource"
          :style="{ animationDelay: `${index * 0.1}s` }"
          class="animate-slide-up"
        />
      </div>
    </section>

    <section class="section latest-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-badge section-badge--alt">最新</span>
          <h2>最新资料</h2>
        </div>
        <router-link to="/resource" class="view-more">
          查看更多 <el-icon><ArrowRight /></el-icon>
        </router-link>
      </div>
      <div class="resource-grid">
        <ResourceCard
          v-for="(resource, index) in latestResources"
          :key="resource.id"
          :resource="resource"
          :style="{ animationDelay: `${index * 0.1}s` }"
          class="animate-slide-up"
        />
      </div>
    </section>

    <section class="features-section">
      <div class="section-header centered">
        <div class="section-title">
          <span class="section-badge section-badge--muted">特色</span>
          <h2>为什么选择 NeuShare</h2>
          <p class="section-desc">为东北大学学子打造的专属学习平台</p>
        </div>
      </div>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-card__icon">
            <el-icon><Upload /></el-icon>
          </div>
          <h3>便捷上传</h3>
          <p>一键分享学习资料，支持多种文件格式</p>
        </div>
        <div class="feature-card">
          <div class="feature-card__icon">
            <el-icon><Search /></el-icon>
          </div>
          <h3>智能搜索</h3>
          <p>快速检索所需资料，支持分类筛选</p>
        </div>
        <div class="feature-card">
          <div class="feature-card__icon">
            <el-icon><ChatDotRound /></el-icon>
          </div>
          <h3>互动交流</h3>
          <p>评论点赞收藏，与同学交流学习心得</p>
        </div>
        <div class="feature-card">
          <div class="feature-card__icon">
            <el-icon><Medal /></el-icon>
          </div>
          <h3>优质资源</h3>
          <p>严格审核机制，确保资料质量</p>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import { getHotResources, getResourceList } from '@/api/resource'
import { coursesByGrade } from '@/utils/courseData'

const router = useRouter()

const hotResources = ref([])
const latestResources = ref([])

const gradeSemesterOptions = [
  { key: '1-1', label: '大一上' },
  { key: '1-2', label: '大一下' },
  { key: '2-1', label: '大二上' },
  { key: '2-2', label: '大二下' },
  { key: '3-1', label: '大三上' },
  { key: '3-2', label: '大三下' },
  { key: '4-1', label: '大四上' },
  { key: '4-2', label: '大四下' }
]

const selectedOption = ref(null)

const currentLabel = computed(() => {
  const option = gradeSemesterOptions.find(o => o.key === selectedOption.value)
  return option ? option.label : ''
})

const currentCourses = computed(() => {
  if (!selectedOption.value) return []
  return coursesByGrade[selectedOption.value] || []
})

const selectOption = (key) => {
  selectedOption.value = selectedOption.value === key ? null : key
}

const goToCourseResources = (course) => {
  const query = { keyword: course.name }
  if (course.categoryId) {
    query.categoryId = course.categoryId
  }
  router.push({ path: '/resource', query })
}

const fetchData = async () => {
  try {
    const [hotRes, latestRes] = await Promise.all([
      getHotResources(4),
      getResourceList({ pageNum: 1, pageSize: 4, status: 1 })
    ])
    hotResources.value = hotRes.data || []
    const latestData = latestRes.data?.records || []
    latestResources.value = latestData.slice(0, 4)
  } catch (error) {
    console.error('Failed to fetch data:', error)
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.home-page {
  min-height: 100%;
}

/* Hero */
.hero-section {
  position: relative;
  padding: 100px 20px 120px;
  overflow: hidden;
  background: linear-gradient(180deg, #f8fafc 0%, #f0f4ff 50%, #f5f5f7 100%);
}

.hero-content {
  position: relative;
  z-index: 1;
  max-width: 720px;
  margin: 0 auto;
  text-align: center;
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-full);
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 24px;
  background: var(--bg-elevated);
}

.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
}

.hero-title {
  font-size: 4rem;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1.1;
  letter-spacing: -0.04em;
  margin-bottom: 20px;
}

.hero-subtitle {
  font-size: 18px;
  color: var(--text-muted);
  margin-bottom: 36px;
}

.hero-actions {
  display: flex;
  gap: 14px;
  justify-content: center;
}

.hero-btn-primary {
  background: var(--accent) !important;
  border-color: var(--accent) !important;
  color: #fff !important;
  font-weight: 600 !important;
  padding: 14px 28px !important;
  font-size: 15px !important;
  display: flex !important;
  align-items: center !important;
  gap: 8px !important;
}

.hero-btn-primary:hover {
  background: var(--accent-dim) !important;
  box-shadow: var(--shadow-accent) !important;
}

.hero-btn-outline {
  background: var(--bg-elevated) !important;
  border: 1px solid var(--border-default) !important;
  color: var(--text-primary) !important;
  font-weight: 500 !important;
  padding: 14px 28px !important;
  font-size: 15px !important;
  display: flex !important;
  align-items: center !important;
  gap: 8px !important;
}

.hero-btn-outline:hover {
  border-color: var(--accent) !important;
  color: var(--accent) !important;
}

/* Sections */
.section {
  max-width: 1280px;
  margin: 0 auto;
  padding: 72px 28px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 36px;
  gap: 16px;
  flex-wrap: wrap;
}

.section-header.centered {
  justify-content: center;
  text-align: center;
}

.section-title {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.section-badge {
  display: inline-block;
  padding: 4px 10px;
  background: rgba(37, 99, 235, 0.08);
  color: var(--accent);
  font-size: 12px;
  font-weight: 600;
  border-radius: var(--radius-xs);
  align-self: flex-start;
}

.section-badge--accent {
  background: rgba(37, 99, 235, 0.08);
  color: var(--accent);
}

.section-badge--alt {
  background: rgba(13, 148, 136, 0.08);
  color: var(--accent-secondary);
}

.section-badge--muted {
  background: rgba(0, 0, 0, 0.04);
  color: var(--text-muted);
}

.section-header h2 {
  font-size: 28px;
  color: var(--text-primary);
  margin: 0;
  letter-spacing: -0.02em;
}

.section-desc {
  font-size: 15px;
  color: var(--text-muted);
  margin: 0;
}

.view-more {
  display: flex;
  align-items: center;
  gap: 4px;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  padding: 8px 14px;
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.view-more:hover {
  color: var(--accent);
  background: var(--bg-hover);
}

/* Course Filter */
.filter-container {
  background: var(--bg-elevated);
  border-radius: var(--radius-lg);
  padding: 28px;
  border: 1px solid var(--border-subtle);
  box-shadow: var(--shadow-sm);
}

.grade-semester-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin-bottom: 20px;
}

.grade-btn {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 18px 14px;
  background: var(--bg-hover);
  border-radius: var(--radius);
  cursor: pointer;
  transition: var(--transition);
  border: 1px solid transparent;
}

.grade-btn:hover {
  border-color: var(--border-default);
  background: var(--bg-elevated);
}

.grade-btn--active {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

.grade-btn--active:hover {
  background: var(--accent-dim);
}

.grade-btn__icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  background: var(--bg-elevated);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  color: var(--text-muted);
  transition: var(--transition);
}

.grade-btn--active .grade-btn__icon {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.grade-btn__label {
  font-size: 14px;
  font-weight: 600;
}

.courses-panel {
  background: var(--bg-hover);
  border-radius: var(--radius);
  padding: 24px;
  border: 1px solid var(--border-subtle);
}

.courses-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 18px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.courses-header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.courses-header-icon {
  font-size: 18px;
  color: var(--accent);
}

.courses-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.courses-count {
  font-size: 12px;
  color: var(--text-muted);
  background: var(--bg-elevated);
  padding: 4px 12px;
  border-radius: var(--radius-full);
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 10px;
}

.course-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: var(--bg-elevated);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-fast);
  border: 1px solid var(--border-subtle);
  animation: fadeInUp 0.3s ease-out both;
}

@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.course-card:hover {
  border-color: var(--border-accent);
  box-shadow: var(--shadow-sm);
}

.course-card__icon {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-sm);
  background: rgba(37, 99, 235, 0.08);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
  font-size: 18px;
  flex-shrink: 0;
}

.course-card__content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.course-card__name {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 500;
}

.course-card__hint {
  font-size: 12px;
  color: var(--text-muted);
}

.course-card__arrow {
  color: var(--text-muted);
  font-size: 15px;
  transition: var(--transition-fast);
}

.course-card:hover .course-card__arrow {
  color: var(--accent);
  transform: translateX(3px);
}

/* Resource grids */
.resource-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

/* Features */
.features-section {
  background: var(--bg-base);
  padding: 80px 28px;
  border-top: 1px solid var(--border-subtle);
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  max-width: 1280px;
  margin: 0 auto;
}

.feature-card {
  text-align: center;
  padding: 36px 24px;
  border-radius: var(--radius-lg);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  transition: var(--transition);
}

.feature-card:hover {
  border-color: var(--border-accent);
  box-shadow: var(--shadow-sm);
}

.feature-card__icon {
  width: 52px;
  height: 52px;
  border-radius: var(--radius);
  background: rgba(37, 99, 235, 0.08);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
  font-size: 22px;
  margin: 0 auto 16px;
}

.feature-card h3 {
  font-size: 16px;
  color: var(--text-primary);
  margin: 0 0 8px;
}

.feature-card p {
  font-size: 14px;
  color: var(--text-muted);
  line-height: 1.6;
  margin: 0;
}

/* Slide-fade transition */
.slide-fade-enter-active { transition: all 0.3s ease-out; }
.slide-fade-leave-active { transition: all 0.2s ease-in; }
.slide-fade-enter-from { transform: translateY(10px); opacity: 0; }
.slide-fade-leave-to { transform: translateY(-10px); opacity: 0; }

/* Responsive */
@media (max-width: 1200px) {
  .resource-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (max-width: 900px) {
  .resource-grid { grid-template-columns: repeat(2, 1fr); }
  .features-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 768px) {
  .grade-semester-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 600px) {
  .resource-grid { grid-template-columns: 1fr; }
  .features-grid { grid-template-columns: 1fr; }
  .hero-title { font-size: 2.5rem; }
  .hero-actions { flex-direction: column; }
}
</style>
