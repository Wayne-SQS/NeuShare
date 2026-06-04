<template>
  <div class="banner-manage-page">
    <div class="banner-card">
      <div class="card-header">
        <span>轮播图管理</span>
        <el-button type="primary" @click="handleAdd">
          <el-icon><Plus /></el-icon>添加轮播图
        </el-button>
      </div>

      <el-table :data="banners" v-loading="loading" stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="imageUrl" label="图片" width="150">
          <template #default="{ row }">
            <el-image
              :src="row.imageUrl"
              :preview-src-list="[row.imageUrl]"
              fit="cover"
              style="width: 120px; height: 60px; border-radius: 4px"
            >
              <template #error>
                <div class="image-placeholder">
                  <el-icon><Picture /></el-icon>
                </div>
              </template>
            </el-image>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="150" />
        <el-table-column prop="linkUrl" label="链接" min-width="150">
          <template #default="{ row }">
            <span class="link-text">{{ row.linkUrl || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="sort" label="排序" width="80" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-switch
              :model-value="row.status === 1"
              @change="handleStatusChange(row)"
            />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑轮播图' : '添加轮播图'"
      width="500px"
    >
      <el-form
        ref="formRef"
        :model="bannerForm"
        :rules="bannerRules"
        label-width="80px"
      >
        <el-form-item label="标题" prop="title">
          <el-input v-model="bannerForm.title" placeholder="请输入标题" />
        </el-form-item>
        <el-form-item label="图片URL" prop="imageUrl">
          <el-input v-model="bannerForm.imageUrl" placeholder="请输入图片URL" />
        </el-form-item>
        <el-form-item label="链接" prop="linkUrl">
          <el-input v-model="bannerForm.linkUrl" placeholder="请输入跳转链接（可选）" />
        </el-form-item>
        <el-form-item label="排序" prop="sort">
          <el-input-number v-model="bannerForm.sort" :min="0" :max="99" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getBannerList, addBanner, updateBanner, deleteBanner, updateBannerStatus } from '@/api/admin'

const loading = ref(false)
const submitting = ref(false)
const banners = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)
const currentId = ref(null)

const bannerForm = reactive({
  title: '',
  imageUrl: '',
  linkUrl: '',
  sort: 0
})

const bannerRules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  imageUrl: [{ required: true, message: '请输入图片URL', trigger: 'blur' }]
}

const fetchBanners = async () => {
  loading.value = true
  try {
    const res = await getBannerList()
    banners.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch banners:', error)
  } finally {
    loading.value = false
  }
}

const handleAdd = () => {
  isEdit.value = false
  currentId.value = null
  Object.assign(bannerForm, {
    title: '',
    imageUrl: '',
    linkUrl: '',
    sort: 0
  })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  currentId.value = row.id
  Object.assign(bannerForm, {
    title: row.title,
    imageUrl: row.imageUrl,
    linkUrl: row.linkUrl,
    sort: row.sort
  })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await updateBanner({ id: currentId.value, ...bannerForm })
      ElMessage.success('修改成功')
    } else {
      await addBanner(bannerForm)
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    fetchBanners()
  } catch (error) {
    console.error('Failed to submit:', error)
  } finally {
    submitting.value = false
  }
}

const handleStatusChange = async (row) => {
  const newStatus = row.status === 1 ? 0 : 1
  try {
    await updateBannerStatus(row.id, newStatus)
    ElMessage.success('状态更新成功')
    fetchBanners()
  } catch (error) {
    console.error('Failed to update status:', error)
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该轮播图吗？', '提示', {
      type: 'warning'
    })
    await deleteBanner(row.id)
    ElMessage.success('删除成功')
    fetchBanners()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to delete:', error)
    }
  }
}

onMounted(() => {
  fetchBanners()
})
</script>

<style scoped>
.banner-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.card-header > span {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.image-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-elevated);
  color: var(--text-muted);
  border-radius: 4px;
}

.link-text {
  color: var(--text-muted);
  font-size: 13px;
}
</style>
