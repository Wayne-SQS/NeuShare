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
              placeholder="请选择分类"
              style="width: 100%"
            >
              <el-option
                v-for="category in categories"
                :key="category.id"
                :label="category.name"
                :value="category.id"
              />
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
import { getCategories, createResource, updateResource, getResourceDetail } from '@/api/resource'

const route = useRoute()
const router = useRouter()

const formRef = ref(null)
const uploadRef = ref(null)
const submitting = ref(false)
const categories = ref([])
const fileList = ref([])

const isEdit = computed(() => !!route.params.id)

const uploadForm = reactive({
  title: '',
  categoryId: '',
  description: '',
  file: null
})

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

const fetchResource = async () => {
  if (!isEdit.value) return
  try {
    const res = await getResourceDetail(route.params.id)
    const data = res.data
    uploadForm.title = data.title
    uploadForm.categoryId = data.categoryId
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
  try {
    if (isEdit.value) {
      await updateResource({
        id: route.params.id,
        title: uploadForm.title,
        categoryId: uploadForm.categoryId,
        description: uploadForm.description
      })
      ElMessage.success('修改成功')
    } else {
      const formData = new FormData()
      formData.append('title', uploadForm.title)
      formData.append('categoryId', uploadForm.categoryId)
      formData.append('description', uploadForm.description)
      if (uploadForm.file) {
        formData.append('file', uploadForm.file)
      }
      await createResource(formData)
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
}

onMounted(() => {
  Promise.all([fetchCategories(), fetchResource()])
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
