<template>
  <div class="home-page">
    <section class="hero">
      <el-carousel class="hero-carousel" :interval="5000" arrow="hover" trigger="click">
        <el-carousel-item v-for="(item, index) in localImages" :key="index">
          <div
            class="hero-slide"
            :style="{ backgroundImage: `url(${item.imageUrl})` }"
            @click="item.link && router.push(item.link)"
          ></div>
        </el-carousel-item>
      </el-carousel>

      <div class="hero-overlay">
        <div class="container">
          <div class="hero-card">
            <span class="hero-badge">东北大学专属</span>
            <h1 class="hero-title">发现优质学习资料</h1>
            <p class="hero-subtitle">与同学一起整理课程笔记、真题与资料，让复习更高效。</p>
            <div class="hero-actions">
              <el-button type="primary" size="large" @click="router.push('/resource')">
                <el-icon><Search /></el-icon>浏览资源
              </el-button>
              <el-button size="large" class="hero-btn-ghost" @click="router.push('/upload')">
                <el-icon><Upload /></el-icon>上传分享
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section-header">
          <div class="section-title">
            <span class="section-badge">快捷查找</span>
            <h2>按年级学期查找课程资料</h2>
            <p class="section-desc">选择对应的年级学期，快速查找课程相关学习资料</p>
          </div>
        </div>

        <div class="filter-container">
          <div class="grade-grid">
            <button
              v-for="option in gradeSemesterOptions"
              :key="option.key"
              type="button"
              :class="['grade-btn', { 'grade-btn--active': selectedOption === option.key }]"
              @click="selectOption(option.key)"
            >
              <el-icon class="grade-btn__icon"><Reading /></el-icon>
              <span class="grade-btn__label">{{ option.label }}</span>
            </button>
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
                <button
                  v-for="course in currentCourses"
                  :key="course.id"
                  type="button"
                  class="course-card"
                  @click="goToCourseResources(course)"
                >
                  <el-icon class="course-card__icon"><Document /></el-icon>
                  <span class="course-card__content">
                    <span class="course-card__name">{{ course.name }}</span>
                    <span class="course-card__hint">点击查看资料</span>
                  </span>
                  <el-icon class="course-card__arrow"><ArrowRight /></el-icon>
                </button>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section-header">
          <div class="section-title">
            <span class="section-badge">热门</span>
            <h2>热门资料</h2>
          </div>
          <router-link to="/resource" class="view-more">
            查看更多 <el-icon><ArrowRight /></el-icon>
          </router-link>
        </div>

        <div v-if="hotLoading" class="grid-auto">
          <SkeletonCard v-for="n in 3" :key="`hot-skeleton-${n}`" :rows="2" />
        </div>
        <div v-else-if="hotResources.length > 0" class="grid-auto">
          <ResourceCard
            v-for="resource in hotResources"
            :key="resource.id"
            :resource="resource"
          />
        </div>
        <EmptyState
          v-else
          icon="Document"
          title="暂无热门资料"
          :description="loadFailed ? '数据加载失败，请稍后重试' : '还没有资料被浏览，先上传一份吧'"
        >
          <el-button type="primary" @click="router.push('/upload')">上传资料</el-button>
        </EmptyState>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section-header">
          <div class="section-title">
            <span class="section-badge">最新</span>
            <h2>最新资料</h2>
          </div>
          <router-link to="/resource" class="view-more">
            查看更多 <el-icon><ArrowRight /></el-icon>
          </router-link>
        </div>

        <div v-if="latestLoading" class="grid-auto">
          <SkeletonCard v-for="n in 3" :key="`latest-skeleton-${n}`" :rows="2" />
        </div>
        <div v-else-if="latestResources.length > 0" class="grid-auto">
          <ResourceCard
            v-for="resource in latestResources"
            :key="resource.id"
            :resource="resource"
          />
        </div>
        <EmptyState
          v-else
          icon="Clock"
          title="暂无最新资料"
          :description="loadFailed ? '数据加载失败，请稍后重试' : '等待第一位同学分享资料'"
        />
      </div>
    </section>

    <section class="features-section">
      <div class="container">
        <div class="section-header section-header--centered">
          <div class="section-title">
            <span class="section-badge">特色</span>
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
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import ResourceCard from '@/components/ResourceCard.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getHotResources, getResourceList } from '@/api/resource'
import { coursesByGrade } from '@/utils/courseData'

const router = useRouter()

const hotResources = ref([])
const latestResources = ref([])
const hotLoading = ref(true)
const latestLoading = ref(true)
const loadFailed = ref(false)

const localImages = [
  { imageUrl: '/images/banner/南湖主楼.png', link: '/resource' },
  { imageUrl: '/images/banner/秋天东大.jpg', link: '/resource' },
  { imageUrl: '/images/banner/红砖.jpg', link: '/upload' },
  { imageUrl: '/images/banner/火箭落日.jpg', link: '/resource' },
  { imageUrl: '/images/banner/冬天东大.jpg', link: '/resource' },
  { imageUrl: '/images/banner/秋天.jpg', link: '/resource' }
]

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

const fetchHot = async () => {
  try {
    const res = await getHotResources(4)
    hotResources.value = (res.data || []).slice(0, 3)
  } catch (error) {
    console.error('Failed to fetch hot resources:', error)
    loadFailed.value = true
  } finally {
    hotLoading.value = false
  }
}

const fetchLatest = async () => {
  try {
    const res = await getResourceList({ pageNum: 1, pageSize: 4, status: 1 })
    latestResources.value = (res.data?.records || []).slice(0, 3)
  } catch (error) {
    console.error('Failed to fetch latest resources:', error)
    loadFailed.value = true
  } finally {
    latestLoading.value = false
  }
}

onMounted(() => {
  fetchHot()
  fetchLatest()
})
</script>

<style scoped>
.home-page {
  min-height: 100%;
}

/* Hero */
.hero {
  position: relative;
  border-bottom: 1px solid var(--border-default);
  background: var(--bg-base);
}

.hero-carousel :deep(.el-carousel__container) {
  height: clamp(320px, 40vw, 440px);
}

.hero-slide {
  width: 100%;
  height: 100%;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  cursor: pointer;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  pointer-events: none;
}

.hero-card {
  pointer-events: auto;
  max-width: 460px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-7);
  box-shadow: var(--shadow-sm);
}

.hero-badge {
  display: inline-block;
  padding: var(--space-1) var(--space-2);
  background: var(--info-bg);
  border-radius: var(--radius-xs);
  font-size: var(--text-xs);
  color: var(--accent);
  font-weight: var(--font-medium);
  margin-bottom: var(--space-4);
}

.hero-title {
  font-size: var(--heading-1);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  line-height: 1.25;
  letter-spacing: -0.02em;
  margin-bottom: var(--space-3);
}

.hero-subtitle {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  margin-bottom: var(--space-5);
}

.hero-actions {
  display: flex;
  gap: var(--space-3);
  flex-wrap: wrap;
}

.hero-btn-ghost {
  background: var(--bg-surface);
  border: 1px solid var(--border-strong);
  color: var(--text-primary);
}

.hero-btn-ghost:hover {
  border-color: var(--accent);
  color: var(--accent);
}

.hero-carousel :deep(.el-carousel__indicator) {
  padding: var(--space-2) var(--space-1);
}

.hero-carousel :deep(.el-carousel__indicator .el-carousel__button) {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.6);
  opacity: 1;
}

.hero-carousel :deep(.el-carousel__indicator.is-active .el-carousel__button) {
  width: 20px;
  border-radius: var(--radius-xs);
  background: var(--text-inverse);
}

.hero-carousel :deep(.el-carousel__arrow) {
  background: rgba(255, 255, 255, 0.85);
  color: var(--text-primary);
  width: 36px;
  height: 36px;
}

/* Sections */
.section {
  padding: var(--section-gap-lg) 0;
}

.section + .section {
  padding-top: 0;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-6);
  gap: var(--space-4);
  flex-wrap: wrap;
}

.section-header--centered {
  justify-content: center;
  text-align: center;
}

.section-title {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.section-badge {
  display: inline-block;
  align-self: flex-start;
  padding: var(--space-1) var(--space-2);
  background: var(--bg-hover);
  color: var(--text-secondary);
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
  border-radius: var(--radius-xs);
}

.section-header--centered .section-badge {
  align-self: center;
}

.section-header h2 {
  font-size: var(--heading-2);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin: 0;
  letter-spacing: -0.02em;
}

.section-desc {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin: 0;
}

.view-more {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.view-more:hover {
  color: var(--accent);
  background: var(--bg-hover);
}

/* Course filter */
.filter-container {
  background: var(--bg-surface);
  border-radius: var(--radius);
  padding: var(--space-6);
  border: 1px solid var(--border-default);
}

.grade-grid {
  display: grid;
  grid-template-columns: repeat(8, minmax(0, 1fr));
  gap: var(--space-3);
  margin-bottom: var(--space-5);
}

.grade-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-4) var(--space-2);
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-default);
  background: var(--bg-surface);
  color: var(--text-secondary);
  font-family: inherit;
  cursor: pointer;
  transition: border-color var(--transition-fast), background var(--transition-fast), color var(--transition-fast);
}

.grade-btn:hover {
  border-color: var(--border-strong);
  background: var(--bg-hover);
  color: var(--text-primary);
}

.grade-btn--active {
  border-color: var(--accent);
  background: var(--info-bg);
  color: var(--accent);
}

.grade-btn__icon {
  font-size: var(--text-xl);
}

.grade-btn__label {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
}

.courses-panel {
  background: var(--bg-deep);
  border-radius: var(--radius-sm);
  padding: var(--space-5);
  border: 1px solid var(--border-subtle);
}

.courses-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-3);
  border-bottom: 1px solid var(--border-default);
}

.courses-header-left {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  min-width: 0;
}

.courses-header-icon {
  color: var(--accent);
}

.courses-title {
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}

.courses-count {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  white-space: nowrap;
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: var(--space-2);
}

.course-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-3) var(--space-4);
  background: var(--bg-surface);
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-subtle);
  font-family: inherit;
  text-align: left;
  cursor: pointer;
  transition: border-color var(--transition-fast);
}

.course-card:hover {
  border-color: var(--border-strong);
}

.course-card__icon {
  color: var(--text-muted);
  font-size: var(--text-lg);
  flex-shrink: 0;
}

.course-card__content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  min-width: 0;
}

.course-card__name {
  font-size: var(--text-sm);
  color: var(--text-primary);
  font-weight: var(--font-medium);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.course-card__hint {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.course-card__arrow {
  color: var(--text-muted);
  font-size: var(--text-xs);
  flex-shrink: 0;
}

/* Features */
.features-section {
  background: var(--bg-base);
  border-top: 1px solid var(--border-default);
  padding: var(--section-gap-lg) 0;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--space-5);
}

.feature-card {
  padding: var(--space-7) var(--space-5);
  border-radius: var(--radius);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  transition: border-color var(--transition-fast);
}

.feature-card:hover {
  border-color: var(--border-strong);
}

.feature-card__icon {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-sm);
  background: var(--bg-hover);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  font-size: var(--text-xl);
  margin-bottom: var(--space-4);
}

.feature-card h3 {
  font-size: var(--heading-3);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin: 0 0 var(--space-2);
}

.feature-card p {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  margin: 0;
}

/* Transition */
.slide-fade-enter-active { transition: opacity 0.2s ease-out, transform 0.2s ease-out; }
.slide-fade-leave-active { transition: opacity 0.15s ease-in; }
.slide-fade-enter-from { transform: translateY(8px); opacity: 0; }
.slide-fade-leave-to { opacity: 0; }

@media (max-width: 1279px) {
  .grade-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }

  .features-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 767px) {
  .hero-carousel :deep(.el-carousel__container) {
    height: 300px;
  }

  .hero-overlay {
    align-items: flex-end;
  }

  .hero-overlay .container {
    padding-bottom: var(--space-4);
  }

  .hero-card {
    max-width: none;
    padding: var(--space-5);
  }

  .hero-title {
    font-size: var(--text-xl);
  }

  .hero-subtitle {
    display: none;
  }

  .section {
    padding: var(--section-gap-md) 0;
  }

  .section + .section {
    padding-top: 0;
  }

  .grade-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filter-container {
    padding: var(--space-4);
  }

  .features-section {
    padding: var(--section-gap-md) 0;
  }

  .features-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .feature-card {
    padding: var(--space-5);
  }
}
</style>
