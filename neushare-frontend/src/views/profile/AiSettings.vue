<template>
  <div class="ai-settings-page">
    <div class="info-card">
      <div class="card-header">
        <span>AI 助手设置</span>
      </div>

      <el-alert
        type="info"
        :closable="false"
        class="byok-tip"
        show-icon
        title="为什么要填自己的 Key？"
        description="默认情况下 AI 助手使用平台统一配置的额度。填入你自己的 API Key 后，对话将消耗你自己的额度，额度消耗不受平台限制。Key 加密存储在服务端，页面上永远只显示掩码。"
      />

      <el-form label-width="120px" class="ai-form">
        <el-form-item label="DeepSeek Key">
          <el-input
            v-model="form.deepseekKey"
            type="password"
            show-password
            placeholder="粘贴 sk- 开头的 DeepSeek API Key"
            autocomplete="off"
          />
          <div class="key-status">
            <el-tag v-if="status.hasDeepseekKey" type="success" size="small">
              已配置 {{ status.deepseekKeyMasked }}
            </el-tag>
            <el-tag v-else type="info" size="small">未配置（使用平台 Key）</el-tag>
            <el-button
              v-if="status.hasDeepseekKey"
              link
              type="danger"
              size="small"
              @click="handleClear('deepseek')"
            >清除</el-button>
          </div>
        </el-form-item>

        <el-form-item label="Tavily Key">
          <el-input
            v-model="form.tavilyKey"
            type="password"
            show-password
            placeholder="粘贴 tvly- 开头的 Tavily API Key（联网搜索）"
            autocomplete="off"
          />
          <div class="key-status">
            <el-tag v-if="status.hasTavilyKey" type="success" size="small">
              已配置 {{ status.tavilyKeyMasked }}
            </el-tag>
            <el-tag v-else type="info" size="small">未配置（使用平台 Key）</el-tag>
            <el-button
              v-if="status.hasTavilyKey"
              link
              type="danger"
              size="small"
              @click="handleClear('tavily')"
            >清除</el-button>
          </div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSave">
            保存配置
          </el-button>
          <span class="tip">留空保存 = 不改动对应字段</span>
        </el-form-item>
      </el-form>

      <el-divider />

      <div class="apply-note">
        <p><strong>去哪里拿 Key：</strong></p>
        <p>DeepSeek：platform.deepseek.com → API Keys（sk- 开头）</p>
        <p>Tavily：app.tavily.com → API Keys（tvly- 开头，免费额度每月 1000 次）</p>
        <p><strong>生效方式：</strong>保存后下一次对话立即生效；更改 Key 会重置该 Key 下的对话记忆。</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getAiConfig, updateAiConfig } from '@/api/aiConfig'

const status = reactive({
  hasDeepseekKey: false,
  deepseekKeyMasked: '',
  hasTavilyKey: false,
  tavilyKeyMasked: ''
})

const form = reactive({
  deepseekKey: '',
  tavilyKey: ''
})

const saving = ref(false)

const loadStatus = async () => {
  const res = await getAiConfig()
  if (res?.data) {
    Object.assign(status, res.data)
  }
}

const handleSave = async () => {
  if (!form.deepseekKey.trim() && !form.tavilyKey.trim()) {
    ElMessage.warning('两个输入框都是空的，没有要保存的内容')
    return
  }
  saving.value = true
  try {
    // undefined 字段会被 JSON 序列化丢弃 = 不改动；传 "" = 清除
    const payload = {}
    if (form.deepseekKey.trim()) payload.deepseekKey = form.deepseekKey.trim()
    if (form.tavilyKey.trim()) payload.tavilyKey = form.tavilyKey.trim()
    await updateAiConfig(payload)
    ElMessage.success('已保存，下一次对话生效')
    form.deepseekKey = ''
    form.tavilyKey = ''
    await loadStatus()
  } finally {
    saving.value = false
  }
}

const handleClear = async (which) => {
  const name = which === 'deepseek' ? 'DeepSeek Key' : 'Tavily Key'
  await ElMessageBox.confirm(`确定清除已保存的 ${name} 吗？清除后回到平台统一额度。`, '清除确认', {
    confirmButtonText: '清除',
    cancelButtonText: '取消',
    type: 'warning'
  })
  await updateAiConfig({ [which === 'deepseek' ? 'deepseekKey' : 'tavilyKey']: '' })
  ElMessage.success('已清除')
  await loadStatus()
}

onMounted(loadStatus)
</script>

<style scoped>
.ai-settings-page .info-card {
  background: var(--bg-surface);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
  padding: 24px 28px;
}

.card-header {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 20px;
}

.byok-tip {
  margin-bottom: 24px;
}

.key-status {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 8px;
}

.tip {
  margin-left: 12px;
  font-size: 12px;
  color: var(--text-tertiary, #999);
}

.apply-note {
  color: var(--text-secondary);
  font-size: 13px;
  line-height: 1.9;
}

.apply-note p {
  margin: 0;
}
</style>
