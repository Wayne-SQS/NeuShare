<template>
  <div class="form-card-manage-page">
    <div class="page-head">
      <div class="page-head__text">
        <span class="breadcrumb">管理后台 / 服务卡片管理</span>
        <h1 class="page-title">服务卡片管理</h1>
        <p class="page-subtitle">控制服务卡片展示的推荐内容</p>
      </div>
      <div class="page-head__actions">
        <el-button type="primary" @click="handleAdd">
          <el-icon><Plus /></el-icon>添加卡片
        </el-button>
      </div>
    </div>

    <div class="panel">
      <div v-if="loading" class="skeleton-list">
        <SkeletonCard v-for="n in 4" :key="`skeleton-${n}`" variant="list" :rows="1" />
      </div>

      <div v-else class="table-wrap">
        <el-table :data="cards" stripe>
          <el-table-column prop="id" label="ID" width="70" />
          <el-table-column prop="title" label="卡片标题" min-width="200" />
          <el-table-column label="类型" width="110">
            <template #default="{ row }">
              <el-tag size="small" :type="typeTag(row.resourceType)" effect="plain">
                {{ typeLabel(row.resourceType) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="resourceId" label="关联资源ID" width="120" />
          <el-table-column prop="contentUrl" label="内容URL" min-width="180">
            <template #default="{ row }">
              <span class="link-text">{{ row.contentUrl || '-' }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="sortOrder" label="排序" width="80" align="right" />
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <el-switch
                :model-value="row.status === 1"
                @change="handleStatusChange(row)"
              />
            </template>
          </el-table-column>
          <el-table-column label="操作" width="140" fixed="right">
            <template #default="{ row }">
              <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
              <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
            </template>
          </el-table-column>

          <template #empty>
            <EmptyState
              icon="Postcard"
              title="暂无服务卡片"
              description="添加卡片后可展示在服务卡片中"
            >
              <el-button type="primary" @click="handleAdd">添加卡片</el-button>
            </EmptyState>
          </template>
        </el-table>
      </div>
    </div>

    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑卡片' : '添加卡片'"
      width="520px"
      destroy-on-close
    >
      <el-form
        ref="formRef"
        :model="formCardForm"
        :rules="formCardRules"
        label-position="top"
      >
        <el-form-item label="卡片标题" prop="title">
          <el-input v-model="formCardForm.title" placeholder="在卡片上显示的标题" />
        </el-form-item>
        <el-form-item label="资源类型" prop="resourceType">
          <el-select v-model="formCardForm.resourceType" placeholder="选择类型" style="width: 100%">
            <el-option label="书籍" value="book" />
            <el-option label="视频" value="video" />
            <el-option label="软件" value="software" />
            <el-option label="教程" value="tutorial" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联资源ID" prop="resourceId">
          <el-input-number v-model="formCardForm.resourceId" :min="0" placeholder="关联的资源主键" />
        </el-form-item>
        <el-form-item label="内容URL" prop="contentUrl">
          <el-input v-model="formCardForm.contentUrl" placeholder="点击卡片跳转的资源链接" />
        </el-form-item>
        <el-form-item label="排序" prop="sortOrder">
          <el-input-number v-model="formCardForm.sortOrder" :min="0" :max="99" />
          <span class="form-hint">越小越靠前</span>
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
import SkeletonCard from '@/components/SkeletonCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import {
  getFormCardList,
  addFormCard,
  updateFormCard,
  deleteFormCard,
  updateFormCardStatus
} from '@/api/admin'

const loading = ref(true)
const submitting = ref(false)
const cards = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)
const currentId = ref(null)

const formCardForm = reactive({
  title: '',
  resourceType: 'book',
  resourceId: 0,
  contentUrl: '',
  sortOrder: 0
})

const formCardRules = {
  title: [{ required: true, message: '请输入卡片标题', trigger: 'blur' }],
  resourceType: [{ required: true, message: '请选择资源类型', trigger: 'change' }]
}

const typeLabel = (type) => {
  const map = { book: '书籍', video: '视频', software: '软件', tutorial: '教程' }
  return map[type] || type
}

const typeTag = (type) => {
  const map = { book: '', video: 'warning', software: 'danger', tutorial: 'success' }
  return map[type] || 'info'
}

const fetchCards = async () => {
  loading.value = true
  try {
    const res = await getFormCardList()
    cards.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch cards:', error)
  } finally {
    loading.value = false
  }
}

const handleAdd = () => {
  isEdit.value = false
  currentId.value = null
  Object.assign(formCardForm, {
    title: '',
    resourceType: 'book',
    resourceId: 0,
    contentUrl: '',
    sortOrder: 0
  })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  currentId.value = row.id
  Object.assign(formCardForm, {
    title: row.title,
    resourceType: row.resourceType || 'book',
    resourceId: row.resourceId || 0,
    contentUrl: row.contentUrl || '',
    sortOrder: row.sortOrder || 0
  })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await updateFormCard({ id: currentId.value, ...formCardForm })
      ElMessage.success('修改成功')
    } else {
      await addFormCard(formCardForm)
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    fetchCards()
  } catch (error) {
    console.error('Failed to submit:', error)
  } finally {
    submitting.value = false
  }
}

const handleStatusChange = async (row) => {
  const newStatus = row.status === 1 ? 0 : 1
  try {
    await updateFormCardStatus(row.id, newStatus)
    ElMessage.success('状态更新成功')
    fetchCards()
  } catch (error) {
    console.error('Failed to update status:', error)
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除该卡片吗？', '提示', {
      type: 'warning'
    })
    await deleteFormCard(row.id)
    ElMessage.success('删除成功')
    fetchCards()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to delete:', error)
    }
  }
}

onMounted(() => {
  fetchCards()
})
</script>

<style scoped>
.form-card-manage-page {
  display: flex;
  flex-direction: column;
}

.skeleton-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.table-wrap {
  width: 100%;
  overflow-x: auto;
}

.link-text {
  color: var(--text-muted);
  font-size: var(--text-xs);
  word-break: break-all;
}

.form-hint {
  font-size: var(--text-xs);
  color: var(--text-muted);
  margin-left: var(--space-2);
}

@media (max-width: 767px) {
  .el-dialog {
    width: calc(100vw - var(--space-8)) !important;
  }
}
</style>
