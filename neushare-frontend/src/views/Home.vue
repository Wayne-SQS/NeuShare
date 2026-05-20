<template>
  <div class="home-page">
    <!-- Banner Carousel -->
    <section class="banner-section">
      <el-carousel
        v-if="banners.length > 0"
        :interval="5000"
        arrow="hover"
        height="420px"
        trigger="click"
      >
        <el-carousel-item v-for="banner in banners" :key="banner.id">
          <div class="banner-slide" :style="{ backgroundImage: `url(${banner.imageUrl})` }">
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

      <!-- Fallback when no banners -->
      <div v-if="banners.length === 0" class="banner-fallback">
        <div class="hero-blob hero-blob--1"></div>
        <div class="hero-blob hero-blob--2"></div>
        <div class="hero-blob hero-blob--3"></div>
        <div class="hero-content">
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
import { getBannerList } from '@/api/banner'
import { coursesByGrade } from '@/utils/courseData'

const router = useRouter()

const banners = ref([])
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
    const [hotRes, latestRes, bannerRes] = await Promise.all([
      getHotResources(4),
      getResourceList({ pageNum: 1, pageSize: 4, status: 1 }),
      getBannerList()
    ])
    hotResources.value = hotRes.data || []
    latestResources.value = (latestRes.data?.records || []).slice(0, 4)
    banners.value = bannerRes.data || []
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
  margin-top: -1px; /* Flush against header border */
}

.banner-slide {
  width: 100%;
  height: 420px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}

.banner-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    180deg,
    rgba(255, 255, 255, 0.3) 0%,
    rgba(255, 255, 255, 0.6) 50%,
    rgba(248, 249, 251, 0.92) 100%
  );
}

/* Glass hero card overlaid on carousel */
.banner-hero-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 10;
  max-width: 620px;
  width: 90%;
}

/* Fallback when no banners */
.banner-fallback {
  position: relative;
  padding: 110px 20px 120px;
  overflow: hidden;
  background:
    radial-gradient(ellipse 80% 60% at 50% 0%, rgba(37, 99, 235, 0.06) 0%, transparent 70%),
    radial-gradient(ellipse 40% 50% at 80% 80%, rgba(37, 99, 235, 0.04) 0%, transparent 70%),
    radial-gradient(ellipse 40% 50% at 20% 70%, rgba(16, 185, 129, 0.03) 0%, transparent 70%),
    linear-gradient(180deg, #f0f4ff 0%, var(--bg-base) 40%, var(--bg-deep) 100%);
}
.hero-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  pointer-events: none;
  animation: blobFloat 12s ease-in-out infinite;
}

.hero-blob--1 {
  width: 500px;
  height: 500px;
  top: -200px;
  right: -100px;
  background: rgba(37, 99, 235, 0.10);
  animation-delay: 0s;
}

.hero-blob--2 {
  width: 350px;
  height: 350px;
  bottom: -80px;
  left: -80px;
  background: rgba(59, 130, 246, 0.07);
  animation-delay: -4s;
}

.hero-blob--3 {
  width: 200px;
  height: 200px;
  top: 50%;
  left: 50%;
  background: rgba(16, 185, 129, 0.06);
  animation-delay: -8s;
}

@keyframes blobFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(30px, -40px) scale(1.05); }
  50% { transform: translate(-20px, 20px) scale(0.95); }
  75% { transform: translate(10px, 30px) scale(1.02); }
}

.hero-content {
  position: relative;
  z-index: 1;
  max-width: 720px;
  margin: 0 auto;
}

/* Glass-morphism card */
.hero-glass-card {
  background: rgba(255, 255, 255, 0.55);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.6);
  border-radius: var(--radius-xl);
  padding: 56px 48px;
  text-align: center;
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
  padding: 6px 16px;
  background: rgba(37, 99, 235, 0.06);
  border: 1px solid rgba(37, 99, 235, 0.12);
  border-radius: var(--radius-full);
  font-size: 13px;
  color: var(--accent);
  font-weight: 500;
  margin-bottom: 28px;
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
  font-size: 3.5rem;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1.15;
  letter-spacing: -0.04em;
  margin-bottom: 16px;
  background: linear-gradient(135deg, #111827 0%, #2563eb 50%, #1d4ed8 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-subtitle {
  font-size: 18px;
  color: var(--text-secondary);
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
  border-radius: var(--radius);
  cursor: pointer;
  transition: var(--transition);
  border: 1px solid transparent;
  color: #fff;
  font-weight: 500;
}

.grade-btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

/* Color each grade row */
.grade-btn:nth-child(1) { background: linear-gradient(135deg, #2563eb, #3b82f6); }
.grade-btn:nth-child(2) { background: linear-gradient(135deg, #1d4ed8, #2563eb); }
.grade-btn:nth-child(3) { background: linear-gradient(135deg, #0d9488, #14b8a6); }
.grade-btn:nth-child(4) { background: linear-gradient(135deg, #0f766e, #0d9488); }
.grade-btn:nth-child(5) { background: linear-gradient(135deg, #d97706, #f59e0b); }
.grade-btn:nth-child(6) { background: linear-gradient(135deg, #b45309, #d97706); }
.grade-btn:nth-child(7) { background: linear-gradient(135deg, #7c3aed, #8b5cf6); }
.grade-btn:nth-child(8) { background: linear-gradient(135deg, #6d28d9, #7c3aed); }

.grade-btn--active {
  transform: scale(1.05);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  border-color: rgba(255, 255, 255, 0.4);
}

.grade-btn__icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  color: rgba(255, 255, 255, 0.85);
  transition: var(--transition);
}

.grade-btn--active .grade-btn__icon {
  background: rgba(255, 255, 255, 0.3);
  color: #fff;
}

.grade-btn__label {
  font-size: 14px;
  font-weight: 600;
  color: #fff;
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

/* Element Plus Carousel overrides */
:deep(.el-carousel__container) {
  height: 420px;
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
