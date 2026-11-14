<template>
  <div class="create-post container container--form">
    <div class="page-head">
      <div class="page-head__text">
        <span class="breadcrumb">NeuShare / 学习社区 / 发帖</span>
        <h1 class="page-title">发布新帖</h1>
      </div>
    </div>

    <div class="panel">
      <el-form label-position="top" @submit.prevent>
        <el-form-item label="标题" required>
          <el-input
            v-model="form.title"
            placeholder="请输入帖子标题"
            maxlength="80"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="标签">
          <el-input
            v-model="tagsInput"
            placeholder="多个标签用空格或逗号分隔，如：考研 408 经验"
          />
          <div class="tag-preview">
            <span v-for="t in tagList" :key="t" class="tag">{{ t }}</span>
            <span v-if="!tagList.length" class="tag-hint">暂未添加标签</span>
          </div>
        </el-form-item>

        <el-form-item label="正文" required>
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="14"
            placeholder="分享你的内容…支持纯文本，换行保留"
            resize="vertical"
          />
        </el-form-item>

        <div class="actions">
          <el-button @click="router.back()">取消</el-button>
          <el-button type="primary" :loading="submitting" @click="submit">发布</el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { createPost } from '@/api/post'

const router = useRouter()

const form = ref({ title: '', content: '' })
const tagsInput = ref('')
const submitting = ref(false)

const tagList = computed(() =>
  tagsInput.value
    .split(/[\s,，、]+/)
    .map((t) => t.trim())
    .filter(Boolean)
    .slice(0, 6)
)

async function submit() {
  if (!form.value.title.trim()) {
    ElMessage.warning('请填写标题')
    return
  }
  if (!form.value.content.trim()) {
    ElMessage.warning('请填写正文')
    return
  }
  submitting.value = true
  try {
    await createPost({
      title: form.value.title.trim(),
      content: form.value.content,
      tags: JSON.stringify(tagList.value),
      imageUrls: JSON.stringify([]),
      files: JSON.stringify([])
    })
    ElMessage.success('发布成功')
    router.push('/community')
  } catch (e) {
    ElMessage.error(e?.message || '发布失败')
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.create-post {
  padding-top: var(--section-gap-md);
  padding-bottom: var(--section-gap-md);
}

.tag-preview {
  margin-top: var(--space-2);
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
  align-items: center;
}

.tag {
  font-size: var(--text-xs);
  color: var(--accent);
  background: var(--info-bg);
  padding: 2px 10px;
  border-radius: var(--radius-xs);
}

.tag-hint {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}
</style>
