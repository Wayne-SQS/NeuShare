<template>
  <div class="upload-page">
    <div class="page-container">
      <div class="upload-card">
        <div class="card-header">
          <el-icon><Upload /></el-icon>
          <span>{{ isEdit ? '编辑资料' : '上传资料' }}</span>
        </div>

        <el-form
          ref="formRef"
          :model="uploadForm"
          :rules="uploadRules"
          label-width="100px"
          class="upload-form"
        >
          <el-form-item label="资料标题" prop="title">
            <el-input
              v-model="uploadForm.title"
              placeholder="请输入资料标题"
              maxlength="100"
              show-word-limit
            />
          </el-form-item>

          <el-form-item label="所属分类" prop="categoryId">
            <el-select
              v-model="uploadForm.categoryId"
              placeholder="请选择分类（选课程后会自动带出）"
              style="width: 100%"
              @change="handleCategoryChange"
            >
              <el-option
                v-for="category in categories"
                :key="category.id"
                :label="category.name"
                :value="category.id"
              />
            </el-select>
          </el-form-item>

          <!-- 结构化归属信息：这几个字段决定了资料能不能被"按课程+教师+学年"精确找到 -->
          <el-form-item label="课程名称" prop="courseName">
            <el-select
              v-model="uploadForm.courseName"
              placeholder="选择或输入课程名，如「操作系统」"
              filterable
              allow-create
              default-first-option
              clearable
              style="width: 100%"
              @change="handleCourseChange"
            >
              <el-option v-for="name in courseOptions" :key="name" :label="name" :value="name" />
            </el-select>
          </el-form-item>

          <el-form-item label="授课教师" prop="teacher">
            <el-select
              v-model="uploadForm.teacher"
              placeholder="选择或输入教师姓名（选填）"
              filterable
              allow-create
              default-first-option
              clearable
              style="width: 100%"
            >
              <el-option v-for="name in teacherOptions" :key="name" :label="name" :value="name" />
            </el-select>
          </el-form-item>

          <el-form-item label="学年学期" prop="schoolYear">
            <div class="inline-group">
              <el-select v-model="uploadForm.schoolYear" placeholder="学年（选填）" clearable style="flex: 1">
                <el-option v-for="y in schoolYears" :key="y" :label="y" :value="y" />
              </el-select>
              <el-select v-model="uploadForm.term" placeholder="学期（选填）" clearable style="flex: 1">
                <el-option label="春季" value="spring" />
                <el-option label="夏季" value="summer" />
                <el-option label="秋季" value="autumn" />
                <el-option label="冬季" value="winter" />
              </el-select>
            </div>
          </el-form-item>

          <el-form-item label="资料类型" prop="type">
            <el-select v-model="uploadForm.type" placeholder="选择类型" style="width: 100%">
              <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
            </el-select>
          </el-form-item>

          <el-form-item label="资料描述" prop="description">
            <el-input
              v-model="uploadForm.description"
              type="textarea"
              :rows="4"
              placeholder="请输入资料描述"
              maxlength="500"
              show-word-limit
            />
          </el-form-item>

          <el-form-item label="上传文件" prop="file">
            <el-upload
              ref="uploadRef"
              :auto-upload="false"
              :limit="1"
              :on-change="handleFileChange"
              :on-remove="handleFileRemove"
              :file-list="fileList"
              drag
            >
              <el-icon class="upload-icon"><UploadFilled /></el-icon>
              <div class="upload-text">
                将文件拖到此处，或<em>点击上传</em>
              </div>
              <template #tip>
                <div class="upload-tip">
                  支持 doc, docx, pdf, ppt, pptx, xls, xlsx, zip, rar 等格式，最大 50MB
                </div>
              </template>
            </el-upload>
          </el-form-item>

          <!-- 上传进度 -->
          <el-form-item v-if="uploadProgress > 0 && uploadProgress < 100" label="上传进度">
            <el-progress :percentage="uploadProgress" :stroke-width="16" :text-inside="true" />
          </el-form-item>

          <el-form-item>
            <el-button type="primary" :loading="submitting" @click="handleSubmit">
              {{ isEdit ? '保存修改' : '提交上传' }}
            </el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  getCategories,
  createResource,
  updateResource,
  getResourceDetail,
  getResourceFilters
} from '@/api/resource'
import { getAllCourses } from '@/utils/courseData'

const route = useRoute()
const router = useRouter()

const formRef = ref(null)
const uploadRef = ref(null)
const submitting = ref(false)
const categories = ref([])
const fileList = ref([])
const uploadProgress = ref(0)

// 课程名词典（含课程→分类映射），用于下拉候选与选课后自动带出分类
const courseCategoryMap = new Map()
getAllCourses().forEach((course) => {
  if (course.categoryId != null && !courseCategoryMap.has(course.name)) {
    courseCategoryMap.set(course.name, course.categoryId)
  }
})

// 平台里已经出现过的课程/教师，优先排在候选前面
const existingCourses = ref([])
const existingTeachers = ref([])

const courseOptions = computed(() =>
  Array.from(new Set([...existingCourses.value, ...courseCategoryMap.keys()]))
)
const teacherOptions = computed(() => existingTeachers.value)

// 学年候选：以当前年份向前推五年，与列表页筛选保持一致
const currentYear = new Date().getFullYear()
const schoolYears = Array.from({ length: 5 }, (_, i) => {
  const start = currentYear - i
  return `${start}-${start + 1}`
})

const typeOptions = [
  { label: '文档（PDF / Word / PPT 等）', value: 'document' },
  { label: '视频', value: 'video' },
  { label: '图片', value: 'image' },
  { label: '外部链接', value: 'link' },
  { label: '其他', value: 'other' }
]


const isEdit = computed(() => !!route.params.id)

const uploadForm = reactive({
  title: '',
  categoryId: '',
  courseName: '',
  teacher: '',
  schoolYear: '',
  term: '',
  type: 'document',
  description: '',
  file: null
})

// 记录分类是否由课程自动带出，避免覆盖用户手动选择的分类
let categoryAutoFilled = false

const uploadRules = {
  title: [
    { required: true, message: '请输入资料标题', trigger: 'blur' },
    { min: 2, max: 100, message: '标题长度为2-100个字符', trigger: 'blur' }
  ],
  categoryId: [
    { required: true, message: '请选择分类', trigger: 'change' }
  ],
  description: [
    { required: true, message: '请输入资料描述', trigger: 'blur' }
  ]
}

const fetchCategories = async () => {
  try {
    const res = await getCategories()
    categories.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch categories:', error)
  }
}

// 候选取自真实数据，空库时才退回内置词典，不给用户空选项
const fetchFilterOptions = async () => {
  try {
    const res = await getResourceFilters()
    existingCourses.value = res.data?.courses || []
    existingTeachers.value = res.data?.teachers || []
  } catch (error) {
    console.error('Failed to fetch filter options:', error)
  }
}

// 选中已知课程时自动带出对应分类，省一次选择
const handleCourseChange = (name) => {
  const categoryId = courseCategoryMap.get(name)
  if (categoryId == null) return
  if (categoryAutoFilled || !uploadForm.categoryId) {
    uploadForm.categoryId = categoryId
    categoryAutoFilled = true
  }
}

// 用户手动改过分类后，后续选课程不再抢着覆盖他的选择
const handleCategoryChange = () => {
  categoryAutoFilled = false
}

const fetchResource = async () => {
  if (!isEdit.value) return
  try {
    const res = await getResourceDetail(route.params.id)
    const data = res.data
    uploadForm.title = data.title
    uploadForm.categoryId = data.categoryId
    uploadForm.courseName = data.courseName || ''
    uploadForm.teacher = data.teacher || ''
    uploadForm.schoolYear = data.schoolYear || ''
    uploadForm.term = data.term || ''
    uploadForm.type = data.type || 'document'
    uploadForm.description = data.description
  } catch (error) {
    console.error('Failed to fetch resource:', error)
  }
}

const handleFileChange = (file) => {
  const isValidSize = file.size / 1024 / 1024 < 50
  if (!isValidSize) {
    ElMessage.error('文件大小不能超过 50MB')
    fileList.value = []
    return
  }
  uploadForm.file = file.raw
}

const handleFileRemove = () => {
  uploadForm.file = null
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  if (!isEdit.value && !uploadForm.file) {
    ElMessage.warning('请上传文件')
    return
  }

  submitting.value = true
  // 空值统一转空串：FormData 只能传字符串，传 null 后端会收到 "null"
  const structured = {
    courseName: uploadForm.courseName || '',
    teacher: uploadForm.teacher || '',
    schoolYear: uploadForm.schoolYear || '',
    term: uploadForm.term || '',
    type: uploadForm.type || 'document'
  }

  try {
    if (isEdit.value) {
      await updateResource({
        id: route.params.id,
        title: uploadForm.title,
        categoryId: uploadForm.categoryId,
        description: uploadForm.description,
        ...structured
      })
      ElMessage.success('修改成功')
    } else {
      const formData = new FormData()
      formData.append('title', uploadForm.title)
      formData.append('categoryId', uploadForm.categoryId)
      formData.append('description', uploadForm.description)
      Object.entries(structured).forEach(([key, value]) => formData.append(key, value))
      if (uploadForm.file) {
        formData.append('file', uploadForm.file)
      }
      uploadProgress.value = 0
      await createResource(formData, (progressEvent) => {
        uploadProgress.value = Math.round((progressEvent.loaded * 100) / progressEvent.total)
      })
      uploadProgress.value = 100
      ElMessage.success('上传成功，等待审核')
    }
    router.push('/profile/resources')
  } catch (error) {
    console.error('Failed to submit:', error)
  } finally {
    submitting.value = false
  }
}

const handleReset = () => {
  formRef.value.resetFields()
  fileList.value = []
  uploadForm.file = null
  categoryAutoFilled = false
}

onMounted(() => {
  Promise.all([fetchCategories(), fetchFilterOptions(), fetchResource()])
})
</script>

<style scoped>
.upload-page {
  min-height: 100%;
  padding: 28px 0;
}

.page-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 0 28px;
}

.upload-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 28px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--border-subtle);
  letter-spacing: -0.02em;
}

.card-header .el-icon {
  color: var(--accent);
}

.upload-form {
  padding: 0;
}

.inline-group {
  display: flex;
  gap: 12px;
  width: 100%;
}

:deep(.el-upload-dragger) {
  width: 100%;
  background: var(--bg-elevated);
  border: 2px dashed var(--border-default);
  border-radius: var(--radius);
}

:deep(.el-upload-dragger:hover) {
  border-color: var(--accent);
}

.upload-icon {
  font-size: 40px;
  color: var(--text-muted);
  margin-bottom: 12px;
}

.upload-text {
  color: var(--text-muted);
  font-size: 14px;
}

.upload-text em {
  color: var(--accent);
  font-style: normal;
}

.upload-tip {
  color: var(--text-muted);
  font-size: 12px;
  margin-top: 8px;
}
</style>
