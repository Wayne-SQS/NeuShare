<template>
  <div class="home-page">
    <!-- Hero：左文案 + 右校园图，玻璃卡叠在图上 -->
    <section class="hero">
      <div class="hero-inner">
        <div class="hero-copy">
          <span class="eyebrow-pill"><i></i>东北大学软件学院 · 学习资料共建</span>
          <h1>把好资料，<br>留给下一届</h1>
          <p class="hero-lede">课件、笔记、真题、实验报告 —— 按学院课程归档，一次上传，全专业复用。</p>

          <div class="hero-search">
            <el-input v-model="searchKeyword" placeholder="搜索课程名、资料标题或关键词" clearable @keyup.enter="handleSearch">
              <template #prefix><el-icon><Search /></el-icon></template>
            </el-input>
            <button class="hero-search__btn" type="button" @click="handleSearch">搜索</button>
          </div>

          <div class="hot-keywords">
            <span>热门搜索</span>
            <button v-for="kw in hotKeywords" :key="kw" type="button" @click="searchFor(kw)">{{ kw }}</button>
          </div>

          <div class="hero-stats">
            <div class="hero-stat"><strong>{{ totalResources }}</strong><span>累计资料</span></div>
            <div class="hero-stat"><strong>{{ courseCount }}</strong><span>门课程</span></div>
            <div class="hero-stat"><strong>同学共建</strong><span>审核通过后全站可见</span></div>
          </div>
        </div>

        <div class="hero-visual">
          <img :src="heroImage" alt="东北大学校园" />
          <div class="hero-glass">
            <span class="hero-glass__label">最新上架资料</span>
            <strong>{{ latestResources.length }} 份</strong>
            <span class="hero-glass__hint">审核通过后全站可见</span>
          </div>
        </div>
      </div>
    </section>

    <!-- 学期胶囊 -->
    <section class="section grade-section">
      <div class="section-head">
        <h2>按年级学期找课程</h2>
        <span>覆盖软件学院 4 个年级 · 8 个学期 · {{ courseCount }} 门课</span>
      </div>
      <div class="grade-pills">
        <button
          v-for="(option, index) in gradeSemesterOptions"
          :key="option.key"
          type="button"
          :class="['grade-pill', `grade-pill--tone-${(index % 4) + 1}`, { 'grade-pill--active': selectedOption === option.key }]"
          @click="selectOption(option.key)"
        >{{ option.label }}</button>
      </div>

      <transition name="slide-fade">
        <div v-if="currentCourses.length > 0" class="courses-panel">
          <div class="courses-head">
            <span><el-icon><Collection /></el-icon>{{ currentLabel }} 课程</span>
            <span>共 {{ currentCourses.length }} 门课程</span>
          </div>
          <div class="courses-grid">
            <div v-for="course in currentCourses" :key="course.id" class="course-chip" @click="goToCourseResources(course)">
              <el-icon><Document /></el-icon>
              <span>{{ course.name }}</span>
              <el-icon class="course-chip__arrow"><ArrowRight /></el-icon>
            </div>
          </div>
        </div>
      </transition>
    </section>

    <!-- 热门资料：四色渐变卡 -->
    <section class="section hot-section">
      <div class="section-head">
        <h2>热门资料</h2>
        <router-link to="/resource" class="view-all">查看全部资料 <el-icon><ArrowRight /></el-icon></router-link>
      </div>
      <div class="resource-grid">
        <ResourceCard v-for="resource in hotResources" :key="resource.id" :resource="resource" />
      </div>
      <p v-if="!hotResources.length" class="empty-hint">暂无资料，去资源广场看看吧</p>
    </section>

    <!-- 三步流程 -->
    <section class="section steps-section">
      <h2>三步，把资料交到需要的人手里</h2>
      <div class="steps-grid">
        <div v-for="step in steps" :key="step.no" class="step-card">
          <span class="step-no">{{ step.no }} <i>/</i> {{ step.en }}</span>
          <h3>{{ step.title }}</h3>
          <p>{{ step.desc }}</p>
        </div>
      </div>
    </section>

    <!-- 共建 CTA -->
    <section class="cta-band">
      <div class="cta-copy">
        <h2>这份笔记，可能正好帮到下一个赶 DDL 的人</h2>
        <p>上传一份资料，审核通过后全学院可见；目前已有 {{ totalResources }} 份共建资料。</p>
      </div>
      <button class="cta-btn" type="button" @click="$router.push('/upload')">开始上传</button>
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
const totalResources = ref(0)
const searchKeyword = ref('')
const heroImage = '/images/banner/南湖主楼.png'
const hotKeywords = ['数据结构', '操作系统', '计算机网络', '期末论文']

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

const steps = [
  { no: '01', en: 'UPLOAD', title: '拖入文件，选好课程', desc: '支持 PDF / Word / PPT / 压缩包，单文件 50MB 以内，自动带上传进度。' },
  { no: '02', en: 'REVIEW', title: '管理员审核，自动通知', desc: '审核通过即全站可见，结果与反馈会推送到你的消息中心。' },
  { no: '03', en: 'REUSE', title: '被收藏、被讨论、被接住', desc: '评论支持树形回复，点赞收藏防重复，让好资料被下一届接着用。' }
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

const courseCount = computed(() =>
  Object.values(coursesByGrade).reduce((sum, list) => sum + (Array.isArray(list) ? list.length : 0), 0)
)

const selectOption = (key) => {
  selectedOption.value = selectedOption.value === key ? null : key
}

const goToCourseResources = (course) => {
  const query = { keyword: course.name }
  if (course.categoryId) query.categoryId = course.categoryId
  router.push({ path: '/resource', query })
}

const handleSearch = () => {
  const kw = searchKeyword.value.trim()
  router.push({ path: '/resource', query: kw ? { keyword: kw } : {} })
}

const searchFor = (kw) => {
  searchKeyword.value = kw
  handleSearch()
}

const fetchData = async () => {
  try {
    const [hotRes, latestRes] = await Promise.all([
      getHotResources(4),
      getResourceList({ pageNum: 1, pageSize: 4, status: 1 })
    ])
    hotResources.value = hotRes.data || []
    latestResources.value = (latestRes.data?.records || []).slice(0, 4)
    totalResources.value = latestRes.data?.total || 0
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
  padding-bottom: 56px;
}

.hero {
  padding: 64px 0 56px;
}

.hero-inner,
.section,
.cta-band {
  max-width: 1160px;
  margin: 0 auto;
  padding-left: 28px;
  padding-right: 28px;
}

.hero-inner {
  display: grid;
  grid-template-columns: 1fr 0.82fr;
  gap: 56px;
  align-items: center;
}

.eyebrow-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: var(--radius-full);
  background: rgba(var(--accent-rgb), 0.10);
  color: var(--accent);
  font-size: 12px;
  font-weight: 600;
}

.eyebrow-pill i {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
}

.hero-copy h1 {
  margin: 22px 0 16px;
  font-size: 54px;
  line-height: 1.18;
  font-weight: 700;
  letter-spacing: -0.035em;
  color: var(--text-primary);
}

.hero-lede {
  font-size: 15px;
  color: var(--text-secondary);
  line-height: 1.8;
  max-width: 460px;
}

.hero-search {
  display: flex;
  gap: 8px;
  margin-top: 28px;
  padding: 7px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}

.hero-search :deep(.el-input__wrapper) {
  box-shadow: none;
  background: transparent;
  padding: 2px 8px;
}

.hero-search :deep(.el-input__inner) {
  font-size: 14px;
}

.hero-search__btn {
  flex-shrink: 0;
  padding: 0 26px;
  border: none;
  border-radius: var(--radius-sm);
  background: var(--accent);
  color: var(--text-inverse);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition-fast);
}

.hero-search__btn:hover {
  background: var(--accent-light);
  box-shadow: var(--shadow-accent);
}

.hot-keywords {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  font-size: 12px;
  color: var(--text-muted);
}

.hot-keywords button {
  border: none;
  background: transparent;
  color: var(--text-secondary);
  cursor: pointer;
  padding: 2px 6px;
  font-size: 12px;
}

.hot-keywords button:hover {
  color: var(--accent);
}

.hero-stats {
  display: flex;
  gap: 36px;
  margin-top: 30px;
  padding-top: 22px;
  border-top: 1px solid var(--border-default);
}

.hero-stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.hero-stat strong {
  font-family: var(--font-mono);
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
}

.hero-stat span {
  font-size: 12px;
  color: var(--text-muted);
}

.hero-visual {
  position: relative;
  border-radius: var(--radius-xl);
  overflow: hidden;
  aspect-ratio: 1 / 1.05;
  box-shadow: var(--shadow-lg);
}

.hero-visual img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.hero-glass {
  position: absolute;
  left: 20px;
  bottom: 20px;
  right: 20px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 16px 20px;
  border-radius: var(--radius);
  background: var(--bg-overlay);
  border: 1px solid var(--border-default);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  box-shadow: var(--shadow-md);
}

.hero-glass__label,
.hero-glass__hint {
  font-size: 12px;
  color: var(--text-secondary);
}

.hero-glass strong {
  font-family: var(--font-mono);
  font-size: 26px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.3;
}

.section {
  margin-top: 56px;
}

.section-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
}

.section-head h2,
.steps-section h2 {
  font-size: 21px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.section-head > span {
  font-size: 12px;
  color: var(--text-muted);
}

.view-all {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  color: var(--accent);
  text-decoration: none;
  font-weight: 600;
}

.grade-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.grade-pill {
  padding: 8px 20px;
  border-radius: var(--radius-full);
  border: 1px solid var(--border-default);
  background: var(--bg-surface);
  color: var(--text-secondary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: var(--transition-fast);
}

.grade-pill--tone-1 { color: var(--chip-blue-ink); background: var(--chip-blue-bg); }
.grade-pill--tone-2 { color: var(--chip-pink-ink); background: var(--chip-pink-bg); }
.grade-pill--tone-3 { color: var(--chip-yellow-ink); background: var(--chip-yellow-bg); }
.grade-pill--tone-4 { color: var(--chip-cyan-ink); background: var(--chip-cyan-bg); }

.grade-pill:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-sm);
}

.grade-pill--active {
  background: var(--accent);
  border-color: var(--accent);
  color: var(--text-inverse);
  box-shadow: var(--shadow-accent);
}

[data-theme="dark"] .grade-pill--tone-1.grade-pill--active,
[data-theme="dark"] .grade-pill--tone-2.grade-pill--active,
[data-theme="dark"] .grade-pill--tone-3.grade-pill--active,
[data-theme="dark"] .grade-pill--tone-4.grade-pill--active {
  background: var(--accent);
  color: var(--text-inverse);
}

.courses-panel {
  margin-top: 20px;
  padding: 20px 22px;
  border-radius: var(--radius-lg);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
}

.courses-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-size: 13px;
  color: var(--text-muted);
}

.courses-head > span:first-child {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: var(--text-primary);
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
}

.course-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 11px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-subtle);
  background: var(--bg-elevated);
  font-size: 13px;
  color: var(--text-secondary);
  cursor: pointer;
  transition: var(--transition-fast);
}

.course-chip:hover {
  border-color: var(--border-accent);
  color: var(--accent);
}

.course-chip span {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.course-chip__arrow { opacity: 0.5; }

.resource-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
}

.empty-hint {
  padding: 28px 0;
  text-align: center;
  color: var(--text-muted);
  font-size: 13px;
}

.steps-section h2 { margin-bottom: 20px; }

.steps-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}

.step-card {
  padding: 22px 24px;
  border-radius: var(--radius-lg);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
}

.step-no {
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 0.06em;
  color: var(--accent);
}

.step-no i { font-style: normal; color: var(--text-muted); }

.step-card h3 {
  margin: 12px 0 8px;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.step-card p {
  font-size: 13px;
  line-height: 1.7;
  color: var(--text-secondary);
}

.cta-band {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  margin-top: 56px;
  padding-top: 32px;
  padding-bottom: 32px;
  border-radius: var(--radius-xl);
  background: var(--accent);
  color: var(--text-inverse);
  box-shadow: var(--shadow-accent);
}

.cta-copy h2 {
  font-size: 22px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-inverse);
}

.cta-copy p {
  margin-top: 8px;
  font-size: 13px;
  opacity: 0.85;
}

.cta-btn {
  flex-shrink: 0;
  padding: 12px 26px;
  border: none;
  border-radius: var(--radius-sm);
  background: var(--bg-surface);
  color: var(--text-primary);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition-fast);
}

.cta-btn:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }

.slide-fade-enter-active, .slide-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.slide-fade-enter-from, .slide-fade-leave-to { opacity: 0; transform: translateY(-8px); }

@media (max-width: 1100px) {
  .hero-inner { grid-template-columns: 1fr; gap: 32px; }
  .hero-visual { max-width: 520px; }
  .resource-grid { grid-template-columns: repeat(3, 1fr); }
  .courses-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (max-width: 768px) {
  .hero { padding: 40px 0; }
  .hero-copy h1 { font-size: 36px; }
  .resource-grid { grid-template-columns: repeat(2, 1fr); }
  .steps-grid { grid-template-columns: 1fr; }
  .courses-grid { grid-template-columns: repeat(2, 1fr); }
  .hero-stats { gap: 20px; flex-wrap: wrap; }
  .cta-band { flex-direction: column; align-items: flex-start; }
}

@media (max-width: 560px) {
  .resource-grid { grid-template-columns: 1fr; }
  .courses-grid { grid-template-columns: 1fr; }
  .hero-search { flex-direction: column; }
  .hero-search__btn { padding: 12px; }
}
</style>
