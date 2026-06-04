<template>
  <div class="home-page">
    <!-- Banner Carousel -->
    <section class="banner-section">
      <el-carousel
        :interval="5000"
        arrow="hover"
        height="620px"
        trigger="click"
      >
        <el-carousel-item v-for="(item, index) in localImages" :key="index">
          <div class="banner-slide" :style="{ backgroundImage: `url(${item.imageUrl})` }">
            <div class="banner-overlay"></div>
          </div>
        </el-carousel-item>
      </el-carousel>

      <!-- Glass hero card overlaid on carousel -->
      <div class="banner-hero-overlay">
        <div class="hero-glass-card">
          <div class="hero-badge">
            <span class="badge-dot"></span>
            东北大学专属
          </div>
          <h1 class="hero-title">发现优质<br>学习资料</h1>
          <p class="hero-subtitle">与同学们一起，让学习更高效</p>
          <div class="hero-actions">
            <el-button class="hero-btn-primary" size="large" @click="$router.push('/resource')">
              <el-icon><Search /></el-icon>浏览资源
            </el-button>
            <el-button class="hero-btn-outline" size="large" @click="$router.push('/upload')">
              <el-icon><Upload /></el-icon>上传分享
            </el-button>
          </div>
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

const localImages = [
  { imageUrl: '/images/banner/南湖主楼.png' },
  { imageUrl: '/images/banner/秋天东大.jpg' },
  { imageUrl: '/images/banner/红砖.jpg' },
  { imageUrl: '/images/banner/火箭落日.jpg' },
  { imageUrl: '/images/banner/冬天东大.jpg' },
  { imageUrl: '/images/banner/秋天.jpg' }
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

const fetchData = async () => {
  try {
    const [hotRes, latestRes] = await Promise.all([
      getHotResources(4),
      getResourceList({ pageNum: 1, pageSize: 4, status: 1 })
    ])
    hotResources.value = hotRes.data || []
    latestResources.value = (latestRes.data?.records || []).slice(0, 4)
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

/* ========== Banner Carousel ========== */
.banner-section {
  position: relative;
  margin-top: -1px;
}

.banner-slide {
  width: 100%;
  height: 620px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}

.banner-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    180deg,
    rgba(0, 0, 0, 0.08) 0%,
    transparent 40%,
    transparent 70%,
    rgba(0, 0, 0, 0.15) 100%
  );
}

/* Glass hero card overlaid on carousel */
.banner-hero-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 10;
  max-width: 420px;
  width: 88%;
}

/* Glass-morphism card */
.hero-glass-card {
  background: rgba(255, 255, 255, 0.55);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.6);
  border-radius: var(--radius-xl);
  padding: 40px 36px;
  text-align: center;
  aspect-ratio: 1 / 1;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.04),
    0 2px 8px rgba(0, 0, 0, 0.02),
    inset 0 0 0 1px rgba(255, 255, 255, 0.5);
  animation: cardShadowPulse 6s ease-in-out infinite;
  transition: box-shadow var(--transition-slow);
}

.hero-glass-card:hover {
  box-shadow:
    0 16px 48px rgba(37, 99, 235, 0.12),
    0 4px 16px rgba(0, 0, 0, 0.06),
    inset 0 0 0 1px rgba(255, 255, 255, 0.6);
}

@keyframes cardShadowPulse {
  0%, 100% {
    box-shadow:
      0 8px 32px rgba(0, 0, 0, 0.04),
      0 2px 8px rgba(0, 0, 0, 0.02),
      inset 0 0 0 1px rgba(255, 255, 255, 0.5);
  }
  50% {
    box-shadow:
      0 12px 40px rgba(37, 99, 235, 0.08),
      0 4px 12px rgba(0, 0, 0, 0.04),
      inset 0 0 0 1px rgba(37, 99, 235, 0.12);
  }
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px 14px;
  background: rgba(37, 99, 235, 0.06);
  border: 1px solid rgba(37, 99, 235, 0.12);
  border-radius: var(--radius-full);
  font-size: 12px;
  color: var(--accent);
  font-weight: 500;
  margin-bottom: 20px;
}

.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
  animation: dotPulse 2s ease-in-out infinite;
}

@keyframes dotPulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.3); }
}

.hero-title {
  font-size: 2.6rem;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1.2;
  letter-spacing: -0.03em;
  margin-bottom: 12px;
  background: linear-gradient(135deg, #111827 0%, #2563eb 50%, #1d4ed8 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-subtitle {
  font-size: 15px;
  color: var(--text-secondary);
  margin-bottom: 28px;
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
  border-radius: var(--radius) !important;
  transition: all 0.3s ease !important;
}

.hero-btn-primary:hover {
  background: var(--accent-dim) !important;
  border-color: var(--accent-dim) !important;
  box-shadow: 0 8px 28px rgba(37, 99, 235, 0.3) !important;
  transform: translateY(-2px);
}

.hero-btn-outline {
  background: rgba(255, 255, 255, 0.6) !important;
  backdrop-filter: blur(8px) !important;
  border: 1px solid var(--border-default) !important;
  color: var(--text-primary) !important;
  font-weight: 500 !important;
  padding: 14px 28px !important;
  font-size: 15px !important;
  display: flex !important;
  align-items: center !important;
  gap: 8px !important;
  border-radius: var(--radius) !important;
  transition: all 0.3s ease !important;
}

.hero-btn-outline:hover {
  border-color: var(--accent) !important;
  color: var(--accent) !important;
  background: rgba(255, 255, 255, 0.85) !important;
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(37, 99, 235, 0.12);
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
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.03),
    0 4px 12px rgba(0, 0, 0, 0.04);
}

.grade-semester-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
  margin-bottom: 20px;
}

.grade-btn {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 20px 14px;
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid transparent;
  color: #fff;
  font-weight: 500;
  overflow: hidden;
  box-shadow:
    0 2px 8px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.15);
}

/* Shine highlight at top */
.grade-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: 8px;
  right: 8px;
  height: 40%;
  border-radius: 0 0 12px 12px;
  background: linear-gradient(180deg, rgba(255,255,255,0.25) 0%, transparent 100%);
  pointer-events: none;
  transition: opacity 0.35s ease;
}

.grade-btn:hover {
  transform: translateY(-3px);
  box-shadow:
    0 8px 28px rgba(0, 0, 0, 0.15),
    0 2px 6px rgba(0, 0, 0, 0.06),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
}

.grade-btn:hover::before {
  background: linear-gradient(180deg, rgba(255,255,255,0.35) 0%, transparent 100%);
}

.grade-btn:active {
  transform: translateY(-1px) scale(0.98);
  transition: all 0.15s ease;
}

/* Color each grade row — richer 3-stop gradients */
.grade-btn:nth-child(1) { background: linear-gradient(160deg, #3b82f6 0%, #2563eb 50%, #1d4ed8 100%); }
.grade-btn:nth-child(2) { background: linear-gradient(160deg, #4f46e5 0%, #3730a3 50%, #312e81 100%); }
.grade-btn:nth-child(3) { background: linear-gradient(160deg, #2dd4bf 0%, #0d9488 50%, #0f766e 100%); }
.grade-btn:nth-child(4) { background: linear-gradient(160deg, #14b8a6 0%, #0f766e 50%, #115e59 100%); }
.grade-btn:nth-child(5) { background: linear-gradient(160deg, #fbbf24 0%, #d97706 50%, #b45309 100%); }
.grade-btn:nth-child(6) { background: linear-gradient(160deg, #f59e0b 0%, #d97706 50%, #92400e 100%); }
.grade-btn:nth-child(7) { background: linear-gradient(160deg, #a78bfa 0%, #7c3aed 50%, #6d28d9 100%); }
.grade-btn:nth-child(8) { background: linear-gradient(160deg, #8b5cf6 0%, #7c3aed 50%, #5b21b6 100%); }

.grade-btn--active {
  transform: scale(1.06) translateY(-1px);
  box-shadow:
    0 12px 36px rgba(0, 0, 0, 0.22),
    0 2px 8px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.25);
  border-color: rgba(255, 255, 255, 0.5);
}

.grade-btn__icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.18);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 19px;
  color: rgba(255, 255, 255, 0.9);
  transition: all 0.35s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
}

.grade-btn:hover .grade-btn__icon {
  background: rgba(255, 255, 255, 0.25);
  transform: scale(1.05);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.grade-btn--active .grade-btn__icon {
  background: rgba(255, 255, 255, 0.32);
  color: #fff;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.12);
}

.grade-btn__label {
  font-size: 15px;
  font-weight: 650;
  color: #fff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  letter-spacing: 0.02em;
}

.courses-panel {
  background: var(--bg-hover);
  border-radius: var(--radius);
  padding: 24px;
  border: 1px solid var(--border-subtle);
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.02),
    0 2px 8px rgba(0, 0, 0, 0.03);
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
  padding: 15px 18px;
  background: var(--bg-elevated);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid var(--border-subtle);
  box-shadow:
    0 1px 2px rgba(0, 0, 0, 0.02);
  animation: fadeInUp 0.3s ease-out both;
}

@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.course-card:hover {
  border-color: rgba(37, 99, 235, 0.2);
  box-shadow:
    0 4px 16px rgba(37, 99, 235, 0.08),
    0 1px 3px rgba(0, 0, 0, 0.04);
  transform: translateY(-2px);
}

.course-card:active {
  transform: translateY(0) scale(0.98);
}

.course-card__icon {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.1), rgba(37, 99, 235, 0.05));
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
  font-size: 18px;
  flex-shrink: 0;
  transition: all 0.3s ease;
  box-shadow: inset 0 1px 0 rgba(37, 99, 235, 0.08);
}

.course-card:hover .course-card__icon {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.18), rgba(37, 99, 235, 0.08));
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.12), inset 0 1px 0 rgba(37, 99, 235, 0.12);
}

.course-card__content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.course-card__name {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 550;
}

.course-card__hint {
  font-size: 12px;
  color: var(--text-muted);
}

.course-card__arrow {
  color: var(--text-muted);
  font-size: 15px;
  transition: all 0.3s ease;
}

.course-card:hover .course-card__arrow {
  color: var(--accent);
  transform: translateX(4px);
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
  padding: 40px 28px;
  border-radius: var(--radius-lg);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow:
    0 1px 2px rgba(0, 0, 0, 0.02);
}

.feature-card:hover {
  border-color: rgba(37, 99, 235, 0.15);
  box-shadow:
    0 8px 28px rgba(37, 99, 235, 0.07),
    0 2px 8px rgba(0, 0, 0, 0.04);
  transform: translateY(-4px);
}

.feature-card:active {
  transform: translateY(-1px) scale(0.98);
}

.feature-card__icon {
  width: 56px;
  height: 56px;
  border-radius: var(--radius);
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.12) 0%, rgba(37, 99, 235, 0.04) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
  font-size: 24px;
  margin: 0 auto 18px;
  transition: all 0.35s ease;
  box-shadow: inset 0 1px 0 rgba(37, 99, 235, 0.1);
}

.feature-card:hover .feature-card__icon {
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.2) 0%, rgba(37, 99, 235, 0.08) 100%);
  box-shadow: 0 4px 16px rgba(37, 99, 235, 0.15), inset 0 1px 0 rgba(37, 99, 235, 0.15);
  transform: scale(1.06);
}

.feature-card h3 {
  font-size: 17px;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 10px;
  letter-spacing: -0.01em;
}

.feature-card p {
  font-size: 14px;
  color: var(--text-muted);
  line-height: 1.65;
  margin: 0;
}

/* Slide-fade transition */
.slide-fade-enter-active { transition: all 0.3s ease-out; }
.slide-fade-leave-active { transition: all 0.2s ease-in; }
.slide-fade-enter-from { transform: translateY(10px); opacity: 0; }
.slide-fade-leave-to { transform: translateY(-10px); opacity: 0; }

/* Element Plus Carousel overrides */
:deep(.el-carousel__container) {
  height: 620px;
}

:deep(.el-carousel__indicator) {
  padding: 8px 4px;
}

:deep(.el-carousel__indicator .el-carousel__button) {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  opacity: 0.5;
  background: #fff;
  border: 2px solid rgba(255, 255, 255, 0.6);
  transition: all 0.3s ease;
}

:deep(.el-carousel__indicator.is-active .el-carousel__button) {
  width: 24px;
  border-radius: 4px;
  background: #fff;
  opacity: 1;
}

:deep(.el-carousel__arrow) {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(8px);
  border-radius: 50%;
  width: 40px;
  height: 40px;
  transition: all 0.3s ease;
}

:deep(.el-carousel__arrow:hover) {
  background: rgba(255, 255, 255, 0.85);
}

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
