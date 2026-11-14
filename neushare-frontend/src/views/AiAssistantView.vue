<template>
  <div class="ai-page">
    <!-- 左侧：会话列表 -->
    <aside class="ai-sidebar" :class="{ 'is-open': sidebarOpen }">
      <div class="sidebar-head">
        <div class="brand">
          <el-icon class="brand-icon"><ChatDotRound /></el-icon>
          <span>AI 学习助手</span>
        </div>
        <button class="new-chat-btn" type="button" @click="handleNewChat">
          <el-icon><Plus /></el-icon>
          <span>新建对话</span>
        </button>
      </div>

      <div class="conv-list">
        <div v-if="loadingConv" class="conv-empty">加载中…</div>
        <template v-else-if="conversations.length">
          <div
            v-for="c in conversations"
            :key="c.id"
            class="conv-item"
            :class="{ active: c.id === currentId }"
            @click="selectConversation(c.id)"
          >
            <div class="conv-main">
              <span class="conv-title" :title="c.title">{{ c.title }}</span>
              <span class="conv-time">{{ formatTime(c.updated_at) }}</span>
            </div>
            <button
              class="conv-del"
              type="button"
              title="删除会话"
              @click.stop="handleDelete(c.id)"
            >
              <el-icon><Delete /></el-icon>
            </button>
          </div>
        </template>
        <div v-else class="conv-empty">还没有对话，开始提问吧</div>
      </div>
    </aside>

    <!-- 移动端遮罩 -->
    <div v-if="sidebarOpen" class="sidebar-mask" @click="sidebarOpen = false"></div>

    <!-- 右侧：消息区 + 输入框 -->
    <section class="ai-main">
      <div class="ai-main-head">
        <button class="menu-btn" type="button" @click="sidebarOpen = !sidebarOpen">
          <el-icon><ChatLineRound /></el-icon>
        </button>
        <div class="ai-main-title">
          <span>AI 学习助手</span>
          <small>基于 NeuShare 知识库检索作答</small>
        </div>
      </div>

      <div v-if="contextResourceId" class="context-chip">
        <el-icon><Document /></el-icon>
        <span>正在咨询资料：{{ contextResourceTitle || `#${contextResourceId}` }}</span>
        <button class="chip-close" type="button" @click="clearContext" title="清除上下文">
          <el-icon><Close /></el-icon>
        </button>
      </div>

      <div class="messages" ref="messagesEl">
        <!-- 空态欢迎 -->
        <div v-if="!messages.length" class="welcome">
          <div class="welcome-hero">
            <div class="welcome-avatar"><el-icon :size="28"><ChatDotRound /></el-icon></div>
            <h2>你好，我是 NeuShare AI 助手</h2>
            <p>我可以检索平台的学习笔记与资料库，围绕你的问题给出引用来源的回答，并推荐相关资料。</p>
          </div>
          <div class="example-grid">
            <button
              v-for="q in exampleQuestions"
              :key="q"
              class="example-card"
              type="button"
              @click="send(q)"
            >
              <el-icon class="example-icon"><Search /></el-icon>
              <span>{{ q }}</span>
            </button>
          </div>
        </div>

        <!-- 消息流 -->
        <div
          v-for="(m, idx) in messages"
          :key="idx"
          class="msg"
          :class="m.role === 'user' ? 'msg-user' : 'msg-ai'"
        >
          <div class="msg-avatar" :class="m.role === 'user' ? 'avatar-user' : 'avatar-ai'">
            <el-icon v-if="m.role === 'user'"><User /></el-icon>
            <el-icon v-else><ChatDotRound /></el-icon>
          </div>
          <div class="msg-body">
            <div class="msg-name">{{ m.role === 'user' ? '我' : 'AI 助手' }}</div>
            <div class="bubble" :class="{ 'bubble-error': m.error }">
              <div class="msg-content" v-html="renderContent(m.content)"></div>
              <div v-if="streaming && idx === messages.length - 1 && !m.content" class="cursor">▋</div>
              <div v-if="m.error" class="msg-error">⚠ {{ m.error }}</div>

              <!-- 引用来源 -->
              <div v-if="m.sources && m.sources.length" class="attach-block">
                <div class="attach-title">
                  <el-icon><Document /></el-icon> 引用来源
                </div>
                <div class="source-list">
                  <div
                    v-for="(s, i) in m.sources"
                    :key="i"
                    class="source-item"
                    :class="{ clickable: s.resource_id }"
                    @click="s.resource_id && goResource(s.resource_id)"
                  >
                    <div class="source-head">
                      <el-icon class="source-icon"><Document /></el-icon>
                      <span class="source-title">{{ s.title || s.file_name || '学习笔记' }}</span>
                      <el-icon v-if="s.resource_id" class="source-arrow"><ArrowRight /></el-icon>
                    </div>
                    <div v-if="s.snippet" class="source-snippet">{{ s.snippet }}</div>
                  </div>
                </div>
              </div>

              <!-- 推荐资源 -->
              <div v-if="m.resources && m.resources.length" class="attach-block">
                <div class="attach-title">
                  <el-icon><Promotion /></el-icon> 推荐资料
                </div>
                <div class="resource-list">
                  <div
                    v-for="r in m.resources"
                    :key="r.resource_id"
                    class="resource-card"
                    @click="r.resource_id && goResource(r.resource_id)"
                  >
                    <div class="res-cover">
                      <img
                        v-if="r.cover_url"
                        :src="r.cover_url"
                        :alt="r.title"
                        @error="onCoverError($event)"
                      />
                      <div v-else class="res-cover-fallback">
                        <el-icon><Document /></el-icon>
                      </div>
                    </div>
                    <div class="res-info">
                      <div class="res-title">{{ r.title }}</div>
                      <div class="res-meta">
                        <span v-if="r.category" class="res-tag">{{ r.category }}</span>
                        <span v-if="r.source" class="res-source">{{ r.source }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 输入框 -->
      <div class="composer">
        <div class="composer-inner">
          <textarea
            v-model="input"
            class="composer-input"
            rows="1"
            :disabled="streaming"
            placeholder="输入你的问题，Enter 发送，Shift+Enter 换行"
            @keydown.enter.exact.prevent="send()"
          ></textarea>
          <button
            class="send-btn"
            type="button"
            :disabled="streaming || !input.trim()"
            @click="send()"
          >
            <el-icon v-if="!streaming"><Promotion /></el-icon>
            <span v-else>生成中…</span>
          </button>
        </div>
        <div class="composer-tip">AI 回答由检索结果生成，仅供参考；限流 10 次/分钟</div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getConversations,
  createConversation,
  getMessages,
  deleteConversation,
  chatStream
} from '@/api/ai'
import { getResourceDetail } from '@/api/resource'

const route = useRoute()
const router = useRouter()

const conversations = ref([])
const currentId = ref(null)
const messages = ref([])
const input = ref('')
const streaming = ref(false)
const loadingConv = ref(false)
const sidebarOpen = ref(false)

const contextResourceId = ref(null)
const contextResourceTitle = ref('')

const messagesEl = ref(null)

const exampleQuestions = [
  '伴随矩阵的秩有什么性质？',
  '操作系统常见的进程调度算法有哪些？',
  '帮我推荐线性代数的学习资源',
  '考研 408 计算机学科该怎么复习？'
]

function formatTime(s) {
  if (!s) return ''
  return String(s).slice(5, 16) // MM-DD HH:MM
}

// 安全的轻量 Markdown：先转义 HTML，再处理 **粗体** 与 `行内代码`，换行靠 white-space: pre-wrap
function renderContent(text) {
  if (!text) return ''
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/`([^`]+)`/g, '<code>$1</code>')
}

function goResource(id) {
  if (!id) return
  router.push(`/resource/${id}`)
}

function onCoverError(e) {
  const img = e.target
  img.style.display = 'none'
  const fallback = img.parentElement.querySelector('.res-cover-fallback')
  if (fallback) fallback.style.display = 'flex'
}

// ---------- 会话 ----------
async function loadConversations() {
  loadingConv.value = true
  try {
    const list = await getConversations()
    conversations.value = list || []
    if (currentId.value && !conversations.value.some((c) => c.id === currentId.value)) {
      currentId.value = null
    }
    if (!currentId.value && conversations.value.length) {
      selectConversation(conversations.value[0].id)
    }
  } catch (e) {
    ElMessage.error(e?.message || '加载会话失败')
  } finally {
    loadingConv.value = false
  }
}

async function selectConversation(id) {
  currentId.value = id
  sidebarOpen.value = false
  messages.value = []
  try {
    const list = await getMessages(id)
    messages.value = (list || []).map((m) => ({
      role: m.role,
      content: m.content || '',
      sources: m.sources ? parseJson(m.sources) : [],
      resources: m.resources ? parseJson(m.resources) : []
    }))
    jumpToBottom()
  } catch (e) {
    ElMessage.error(e?.message || '加载消息失败')
  }
}

function parseJson(v) {
  if (Array.isArray(v)) return v
  if (!v) return []
  try {
    return JSON.parse(v)
  } catch (e) {
    return []
  }
}

async function handleNewChat() {
  currentId.value = null
  messages.value = []
  sidebarOpen.value = false
  // 不立即创建空会话：首条消息发送时再创建，避免产生空会话
}

async function handleDelete(id) {
  try {
    await ElMessageBox.confirm('确定删除这个对话吗？', '提示', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'warning'
    })
  } catch (e) {
    return
  }
  try {
    await deleteConversation(id)
    conversations.value = conversations.value.filter((c) => c.id !== id)
    if (currentId.value === id) {
      currentId.value = null
      messages.value = []
      if (conversations.value.length) selectConversation(conversations.value[0].id)
    }
    ElMessage.success('已删除')
  } catch (e) {
    ElMessage.error(e?.message || '删除失败')
  }
}

function clearContext() {
  contextResourceId.value = null
  contextResourceTitle.value = ''
  // 同步清除地址栏 query
  router.replace({ path: '/ai' })
}

// ---------- 发送 ----------
async function send(text) {
  if (streaming.value) return
  const question = (text != null ? text : input.value).trim()
  if (!question) return
  input.value = ''

  // 确保存在会话
  if (!currentId.value) {
    try {
      const conv = await createConversation('新对话')
      currentId.value = conv.id
      conversations.value.unshift({ id: conv.id, title: conv.title, updated_at: '' })
    } catch (e) {
      ElMessage.error(e?.message || '创建会话失败')
      return
    }
  }

  const userMsg = { role: 'user', content: question }
  const aiMsg = { role: 'assistant', content: '', sources: [], resources: [] }
  messages.value.push(userMsg, aiMsg)
  streaming.value = true
  jumpToBottom()

  try {
    await chatStream({
      question,
      conversation_id: currentId.value,
      resource_id: contextResourceId.value || undefined,
      onToken: (delta) => {
        aiMsg.content += delta
        autoScroll()
      },
      onSources: (src) => {
        aiMsg.sources = src || []
        autoScroll()
      },
      onResources: (res) => {
        aiMsg.resources = res || []
        autoScroll()
      },
      onError: (msg) => {
        aiMsg.error = msg
      }
    })
    // 后端可能用首条问题更新了会话标题，刷新列表
    await loadConversations()
  } catch (e) {
    if (!aiMsg.error) aiMsg.error = e?.message || '发送失败'
  } finally {
    streaming.value = false
    jumpToBottom()
  }
}

// ---------- 滚动 ----------
function isNearBottom() {
  const el = messagesEl.value
  if (!el) return true
  return el.scrollHeight - el.scrollTop - el.clientHeight < 120
}
function autoScroll() {
  const el = messagesEl.value
  if (!el) return
  if (isNearBottom()) el.scrollTop = el.scrollHeight
}
function jumpToBottom() {
  nextTick(() => {
    const el = messagesEl.value
    if (el) el.scrollTop = el.scrollHeight
  })
}

// ---------- 上下文（来自资源详情页 ?resourceId=） ----------
async function applyContextFromRoute() {
  const rid = route.query.resourceId
  if (!rid) {
    contextResourceId.value = null
    contextResourceTitle.value = ''
    return
  }
  contextResourceId.value = Number(rid) || null
  contextResourceTitle.value = ''
  try {
    const res = await getResourceDetail(contextResourceId.value)
    if (res && res.data && res.data.title) contextResourceTitle.value = res.data.title
  } catch (e) {
    /* 取不到标题就只显示 id */
  }
}

watch(
  () => route.query.resourceId,
  () => applyContextFromRoute()
)

onMounted(async () => {
  await applyContextFromRoute()
  await loadConversations()
})
</script>

<style scoped>
.ai-page {
  height: calc(100vh - var(--header-height));
  display: flex;
  background: var(--bg-deep);
  overflow: hidden;
}

/* ---------- 侧栏 ---------- */
.ai-sidebar {
  width: 260px;
  flex-shrink: 0;
  background: var(--bg-surface);
  border-right: 1px solid var(--border-default);
  display: flex;
  flex-direction: column;
}

.sidebar-head {
  padding: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}

.brand-icon {
  color: var(--accent);
}

.new-chat-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  height: var(--control-height-lg);
  border: none;
  border-radius: var(--radius-sm);
  background: var(--accent);
  color: var(--text-inverse);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  cursor: pointer;
  transition: var(--transition-fast);
}

.new-chat-btn:hover {
  background: var(--accent-dim);
}

.conv-list {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-2);
}

.conv-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-fast);
  margin-bottom: 2px;
}

.conv-item:hover {
  background: var(--bg-hover);
}

.conv-item.active {
  background: var(--info-bg);
}

.conv-main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.conv-title {
  font-size: var(--text-sm);
  color: var(--text-primary);
  font-weight: var(--font-medium);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.conv-item.active .conv-title {
  color: var(--accent);
}

.conv-time {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.conv-del {
  width: 26px;
  height: 26px;
  display: none;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: var(--text-muted);
  border-radius: var(--radius-xs);
  cursor: pointer;
  flex-shrink: 0;
}

.conv-item:hover .conv-del {
  display: flex;
}

.conv-del:hover {
  background: var(--danger-bg);
  color: var(--danger);
}

.conv-empty {
  padding: var(--space-6) var(--space-3);
  text-align: center;
  font-size: var(--text-sm);
  color: var(--text-muted);
}

.sidebar-mask {
  display: none;
}

/* ---------- 主区 ---------- */
.ai-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.ai-main-head {
  height: 52px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: 0 var(--space-5);
  border-bottom: 1px solid var(--border-subtle);
  background: var(--bg-overlay);
  backdrop-filter: blur(12px);
}

.menu-btn {
  display: none;
  width: 36px;
  height: 36px;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-primary);
  cursor: pointer;
}

.ai-main-title {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.ai-main-title > span {
  font-size: var(--text-base);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}

.ai-main-title > small {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

/* 上下文芯片 */
.context-chip {
  margin: var(--space-3) var(--space-5) 0;
  padding: var(--space-2) var(--space-3);
  display: flex;
  align-items: center;
  gap: var(--space-2);
  background: var(--success-bg);
  border: 1px solid rgba(16, 185, 129, 0.25);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--text-secondary);
  align-self: flex-start;
}

.context-chip .el-icon {
  color: var(--success);
}

.chip-close {
  border: none;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  padding: 2px;
  border-radius: var(--radius-xs);
  display: flex;
}

.chip-close:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

/* ---------- 消息区 ---------- */
.messages {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-6) var(--space-5);
}

/* 欢迎空态 */
.welcome {
  max-width: 720px;
  margin: 0 auto;
  padding-top: var(--space-10);
}

.welcome-hero {
  text-align: center;
  margin-bottom: var(--space-8);
}

.welcome-avatar {
  width: 56px;
  height: 56px;
  margin: 0 auto var(--space-4);
  border-radius: var(--radius-lg);
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-accent);
}

.welcome-hero h2 {
  font-size: var(--heading-2);
  margin-bottom: var(--space-2);
}

.welcome-hero p {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-relaxed);
}

.example-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--space-3);
}

.example-card {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  padding: var(--space-4);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  cursor: pointer;
  text-align: left;
  font-size: var(--text-sm);
  color: var(--text-secondary);
  transition: var(--transition-fast);
  font-family: inherit;
}

.example-card:hover {
  border-color: var(--accent);
  color: var(--accent);
  box-shadow: var(--shadow);
  transform: translateY(-1px);
}

.example-icon {
  color: var(--accent);
  flex-shrink: 0;
  margin-top: 2px;
}

/* 单条消息 */
.msg {
  display: flex;
  gap: var(--space-3);
  margin-bottom: var(--space-6);
  max-width: 820px;
}

.msg-user {
  margin-left: auto;
  flex-direction: row-reverse;
}

.msg-avatar {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 18px;
}

.avatar-ai {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
}

.avatar-user {
  background: var(--bg-hover);
  color: var(--text-secondary);
}

.msg-body {
  min-width: 0;
  max-width: 100%;
}

.msg-name {
  font-size: var(--text-xs);
  color: var(--text-muted);
  margin-bottom: var(--space-1);
  font-weight: var(--font-medium);
}

.msg-user .msg-name {
  text-align: right;
}

.bubble {
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  line-height: var(--leading-relaxed);
}

.msg-user .bubble {
  background: var(--accent);
  border-color: var(--accent);
  color: var(--text-inverse);
}

.bubble-error {
  border-color: var(--danger);
}

.msg-content {
  white-space: pre-wrap;
  word-break: break-word;
  font-size: var(--text-base);
  color: var(--text-primary);
}

.msg-user .msg-content {
  color: var(--text-inverse);
}

.msg-content :deep(code) {
  background: var(--bg-hover);
  padding: 1px 6px;
  border-radius: var(--radius-xs);
  font-family: var(--font-mono);
  font-size: 0.9em;
}

.msg-user .msg-content :deep(code) {
  background: rgba(255, 255, 255, 0.2);
}

.msg-content :deep(strong) {
  font-weight: var(--font-semibold);
}

.cursor {
  display: inline-block;
  color: var(--accent);
  animation: blink 1s step-end infinite;
  margin-left: 1px;
}

@keyframes blink {
  50% { opacity: 0; }
}

.msg-error {
  margin-top: var(--space-2);
  padding: var(--space-2) var(--space-3);
  background: var(--danger-bg);
  border-radius: var(--radius-xs);
  font-size: var(--text-sm);
  color: var(--danger);
}

/* 引用 / 推荐区块 */
.attach-block {
  margin-top: var(--space-3);
  padding-top: var(--space-3);
  border-top: 1px dashed var(--border-default);
}

.attach-title {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  color: var(--text-muted);
  margin-bottom: var(--space-2);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.source-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.source-item {
  padding: var(--space-2) var(--space-3);
  background: var(--bg-deep);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.source-item.clickable {
  cursor: pointer;
}

.source-item.clickable:hover {
  border-color: var(--accent);
  background: var(--info-bg);
}

.source-head {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.source-icon {
  color: var(--accent);
  flex-shrink: 0;
  font-size: 14px;
}

.source-title {
  flex: 1;
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.source-arrow {
  color: var(--text-muted);
  flex-shrink: 0;
}

.source-snippet {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--text-secondary);
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 推荐资源卡片 */
.resource-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: var(--space-2);
}

.resource-card {
  display: flex;
  gap: var(--space-2);
  padding: var(--space-2);
  background: var(--bg-deep);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-fast);
}

.resource-card:hover {
  border-color: var(--accent);
  box-shadow: var(--shadow);
  transform: translateY(-1px);
}

.res-cover {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-xs);
  overflow: hidden;
  flex-shrink: 0;
  background: var(--bg-hover);
  display: flex;
  align-items: center;
  justify-content: center;
}

.res-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.res-cover-fallback {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  display: none;
}

.res-info {
  min-width: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
}

.res-title {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.res-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.res-tag {
  padding: 0 6px;
  background: var(--info-bg);
  color: var(--accent);
  border-radius: var(--radius-xs);
}

.res-source {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* ---------- 输入框 ---------- */
.composer {
  flex-shrink: 0;
  padding: var(--space-3) var(--space-5) var(--space-4);
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-overlay);
  backdrop-filter: blur(12px);
}

.composer-inner {
  max-width: 820px;
  margin: 0 auto;
  display: flex;
  align-items: flex-end;
  gap: var(--space-2);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: var(--space-2);
  transition: var(--transition-fast);
}

.composer-inner:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--border-accent);
}

.composer-input {
  flex: 1;
  border: none;
  outline: none;
  resize: none;
  background: transparent;
  font-family: inherit;
  font-size: var(--text-base);
  color: var(--text-primary);
  line-height: var(--leading-normal);
  padding: var(--space-2) var(--space-2);
  max-height: 160px;
}

.composer-input::placeholder {
  color: var(--text-muted);
}

.composer-input:disabled {
  cursor: not-allowed;
}

.send-btn {
  height: var(--control-height-lg);
  padding: 0 var(--space-4);
  border: none;
  border-radius: var(--radius-sm);
  background: var(--accent);
  color: var(--text-inverse);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: var(--space-1);
  transition: var(--transition-fast);
  flex-shrink: 0;
}

.send-btn:hover:not(:disabled) {
  background: var(--accent-dim);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.composer-tip {
  max-width: 820px;
  margin: var(--space-1) auto 0;
  font-size: var(--text-xs);
  color: var(--text-muted);
  text-align: center;
}

/* ---------- 响应式 ---------- */
@media (max-width: 767px) {
  .ai-page {
    height: calc(100vh - var(--header-height));
  }

  .ai-sidebar {
    position: fixed;
    top: var(--header-height);
    left: 0;
    bottom: 0;
    z-index: var(--z-overlay);
    transform: translateX(-100%);
    transition: transform var(--transition);
    box-shadow: var(--shadow-lg);
  }

  .ai-sidebar.is-open {
    transform: translateX(0);
  }

  .sidebar-mask {
    display: block;
    position: fixed;
    inset: var(--header-height) 0 0 0;
    background: rgba(0, 0, 0, 0.35);
    z-index: calc(var(--z-overlay) - 1);
  }

  .menu-btn {
    display: flex;
  }

  .messages {
    padding: var(--space-4) var(--space-3);
  }

  .example-grid {
    grid-template-columns: 1fr;
  }

  .msg {
    margin-bottom: var(--space-4);
  }

  .welcome {
    padding-top: var(--space-7);
  }

  .composer {
    padding: var(--space-2) var(--space-3) var(--space-3);
  }
}
</style>
