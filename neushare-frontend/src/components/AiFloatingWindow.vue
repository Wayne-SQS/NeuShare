<template>
  <div v-if="userStore.isLoggedIn" class="ai-float-root">
    <!-- 收起态：右下角悬浮按钮 -->
    <button
      v-show="!ai.open"
      class="ai-fab"
      :class="{ 'ai-fab--active': ai.hasActivity }"
      type="button"
      aria-label="打开 AI 助手"
      @click="openPanel"
    >
      <el-icon :size="22"><ChatDotRound /></el-icon>
      <span v-if="ai.hasActivity" class="ai-fab__dot"></span>
    </button>

    <!-- 展开态：浮窗面板 -->
    <transition name="ai-fade">
      <div v-show="ai.open" class="ai-float-panel">
        <!-- 顶栏 -->
        <div class="panel-head">
          <div class="head-brand">
            <el-icon :size="16"><ChatDotRound /></el-icon>
          </div>
          <button
            class="head-btn"
            type="button"
            title="会话列表"
            @click="ai.convDrawer = !ai.convDrawer"
          >
            <el-icon><ChatLineRound /></el-icon>
          </button>
          <div class="head-title">
            <span>AI 学习助手</span>
            <small>基于 NeuShare 知识库</small>
          </div>
          <button class="head-btn" type="button" title="全屏专注模式" @click="goFullscreen">
            <el-icon><FullScreen /></el-icon>
          </button>
          <button class="head-btn head-btn--close" type="button" title="收起" @click="ai.hide()">
            <el-icon><Close /></el-icon>
          </button>
        </div>

        <!-- 会话列表抽屉（覆盖在面板左侧） -->
        <transition name="ai-slide">
          <aside v-show="ai.convDrawer" class="conv-drawer">
            <div class="conv-drawer__head">
              <span>我的对话</span>
              <button class="new-chat-btn" type="button" @click="ai.newChat()">
                <el-icon><Plus /></el-icon>
              </button>
            </div>
            <div class="conv-list">
              <div v-if="ai.loadingConv" class="conv-empty">加载中…</div>
              <template v-else-if="ai.conversations.length">
                <div
                  v-for="c in ai.conversations"
                  :key="c.id"
                  class="conv-item"
                  :class="{ active: c.id === ai.currentId }"
                  @click="ai.selectConversation(c.id)"
                >
                  <div class="conv-main">
                    <span class="conv-title" :title="c.title">{{ c.title }}</span>
                    <span class="conv-time">{{ formatTime(c.updated_at) }}</span>
                  </div>
                  <button
                    class="conv-del"
                    type="button"
                    title="删除会话"
                    @click.stop="ai.removeConversation(c.id)"
                  >
                    <el-icon><Delete /></el-icon>
                  </button>
                </div>
              </template>
              <div v-else class="conv-empty">还没有对话，开始提问吧</div>
            </div>
          </aside>
        </transition>

        <!-- 资料上下文芯片 -->
        <div v-if="ai.contextResourceId" class="context-chip">
          <el-icon><Document /></el-icon>
          <span class="context-chip__text">
            正在咨询：{{ ai.contextResourceTitle || `资料 #${ai.contextResourceId}` }}
          </span>
          <button class="chip-close" type="button" title="清除上下文" @click="ai.clearContext()">
            <el-icon><Close /></el-icon>
          </button>
        </div>

        <!-- 内联错误提示（替代反复弹出的全屏 toast） -->
        <div v-if="ai.error" class="error-banner">
          <el-icon class="error-banner__icon"><WarningFilled /></el-icon>
          <span class="error-banner__text">{{ ai.error }}</span>
          <button class="error-banner__close" type="button" title="关闭" @click="ai.clearError()">
            <el-icon><Close /></el-icon>
          </button>
        </div>

        <!-- 消息流 -->
        <div class="messages" ref="messagesEl" @click="onMessagesClick">
          <!-- 空态欢迎 -->
          <div v-if="!ai.messages.length" class="welcome">
            <div class="welcome-hero">
              <div class="welcome-avatar"><el-icon :size="24"><ChatDotRound /></el-icon></div>
              <h3>你好，我是 NeuShare AI 助手</h3>
              <p>检索平台笔记与资料库，给出引用来源的回答，并推荐相关资料。</p>
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

          <!-- 消息 -->
          <div
            v-for="(m, idx) in ai.messages"
            :key="idx"
            class="msg"
            :class="m.role === 'user' ? 'msg-user' : 'msg-ai'"
          >
            <div class="msg-avatar" :class="m.role === 'user' ? 'avatar-user' : 'avatar-ai'">
              <el-icon v-if="m.role === 'user'" :size="16"><User /></el-icon>
              <el-icon v-else :size="16"><ChatDotRound /></el-icon>
            </div>
            <div class="msg-body">
              <div class="msg-name">{{ m.role === 'user' ? '我' : 'AI 助手' }}</div>
              <div class="bubble" :class="{ 'bubble-error': m.error }">
                <div class="msg-content" v-html="renderContent(m.content)"></div>
                <div v-if="ai.streaming && idx === ai.messages.length - 1 && !m.content" class="cursor">▋</div>
                <div v-if="m.error" class="msg-error">⚠ {{ m.error }}</div>

                <div v-if="m.sources && m.sources.length" class="attach-block">
                  <div class="attach-title"><el-icon><Document /></el-icon> 引用来源</div>
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

                <div v-if="m.resources && m.resources.length" class="attach-block">
                  <div class="attach-title"><el-icon><Promotion /></el-icon> 推荐资料</div>
                  <div class="resource-list">
                    <div
                      v-for="r in m.resources"
                      :key="r.resource_id"
                      class="resource-card"
                      @click="r.resource_id && goResource(r.resource_id)"
                    >
                      <div class="res-cover">
                        <img v-if="r.cover_url" :src="r.cover_url" :alt="r.title" @error="onCoverError($event)" />
                        <div v-else class="res-cover-fallback"><el-icon><Document /></el-icon></div>
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
              :disabled="ai.streaming"
              placeholder="输入问题，Enter 发送"
              @keydown.enter.exact.prevent="send()"
            ></textarea>
            <button
              class="send-btn"
              type="button"
              :disabled="ai.streaming || !input.trim()"
              @click="send()"
            >
              <el-icon v-if="!ai.streaming"><Promotion /></el-icon>
              <span v-else>生成中…</span>
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import { useAiStore } from '@/store/modules/ai'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const ai = useAiStore()

const input = ref('')
const messagesEl = ref(null)

const exampleQuestions = [
  '伴随矩阵的秩有什么性质？',
  '操作系统常见的进程调度算法有哪些？',
  '帮我推荐线性代数的学习资源',
  '考研 408 计算机学科该怎么复习？'
]

// 登录后初始化一次会话列表；退出登录则收起面板
watch(
  () => userStore.isLoggedIn,
  (loggedIn) => {
    if (loggedIn) ai.init()
    else {
      ai.hide()
      ai.convDrawer = false
    }
  }
)

onMounted(() => {
  if (userStore.isLoggedIn) ai.init()
})

// 进入 /ai 全屏页时自动收起浮窗，避免与专注页重复
watch(
  () => route.path,
  (path) => {
    if (path === '/ai') ai.hide()
  }
)

function openPanel() {
  ai.show()
  if (!ai.initialized) ai.init()
}

function goFullscreen() {
  ai.hide()
  router.push('/ai')
}

function send(text) {
  const question = (text != null ? text : input.value).trim()
  if (!question || ai.streaming) return
  input.value = ''
  ai.send(question)
}

function formatTime(s) {
  if (!s) return ''
  return String(s).slice(5, 16)
}

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
  // 不关闭浮窗：跳转到资料详情后浮窗仍常驻，可继续追问
  router.push(`/resource/${id}`)
}

function onCoverError(e) {
  const img = e.target
  img.style.display = 'none'
  const fallback = img.parentElement.querySelector('.res-cover-fallback')
  if (fallback) fallback.style.display = 'flex'
}

// 点击消息区空白：关闭会话抽屉（若打开）
function onMessagesClick() {
  if (ai.convDrawer) ai.convDrawer = false
}

// ---------- 滚动：跟随 store 的 scrollSignal ----------
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
watch(
  () => ai.scrollSignal,
  () => autoScroll()
)
watch(
  () => ai.messages.length,
  () => jumpToBottom()
)
watch(
  () => ai.open,
  (v) => {
    if (v) jumpToBottom()
  }
)
</script>

<style scoped>
.ai-float-root {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 1000; /* 高于 Header(--z-sticky:100)，低于 toast(--z-toast:1100) */
}

/* ---------- 悬浮按钮 ---------- */
.ai-fab {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, var(--accent) 0%, var(--accent-secondary) 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 8px 22px rgba(37, 99, 235, 0.45), 0 2px 6px rgba(37, 99, 235, 0.25);
  transition: transform var(--transition-fast), box-shadow var(--transition-fast);
  position: relative;
}
.ai-fab:hover {
  transform: translateY(-3px) scale(1.06);
  box-shadow: 0 14px 30px rgba(37, 99, 235, 0.55), 0 4px 10px rgba(37, 99, 235, 0.3);
}
.ai-fab:active {
  transform: translateY(-1px) scale(1.02);
}
.ai-fab--active {
  animation: ai-pulse 1.8s ease-in-out infinite;
}
.ai-fab__dot {
  position: absolute;
  top: 5px;
  right: 5px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #fff;
  border: 2px solid var(--accent);
}
@keyframes ai-pulse {
  0%, 100% { box-shadow: 0 8px 22px rgba(37, 99, 235, 0.45), 0 2px 6px rgba(37, 99, 235, 0.25); }
  50% { box-shadow: 0 8px 32px rgba(16, 185, 129, 0.65), 0 2px 6px rgba(16, 185, 129, 0.3); }
}

/* ---------- 浮窗面板 ---------- */
.ai-float-panel {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 400px;
  height: min(72vh, 660px);
  min-height: 480px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg), inset 0 1px 0 rgba(255, 255, 255, 0.7);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transform-origin: bottom right;
}
/* 顶部渐变装饰条 */
.ai-float-panel::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--accent), var(--accent-secondary));
  z-index: 3;
  pointer-events: none;
}

/* ---------- 顶栏 ---------- */
.panel-head {
  height: 52px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: 0 var(--space-3);
  border-bottom: 1px solid var(--border-subtle);
  background: var(--bg-overlay);
  backdrop-filter: blur(14px);
  position: relative;
  z-index: 2;
}
.head-brand {
  width: 28px;
  height: 28px;
  flex-shrink: 0;
  border-radius: var(--radius-sm);
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-accent);
}
.head-title {
  flex: 1;
  display: flex;
  flex-direction: column;
  line-height: 1.3;
  min-width: 0;
}
.head-title > span {
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}
.head-title > small {
  font-size: 11px;
  color: var(--text-muted);
}
.head-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: var(--text-secondary);
  border-radius: var(--radius-sm);
  cursor: pointer;
  flex-shrink: 0;
  transition: var(--transition-fast);
}
.head-btn:hover {
  background: var(--bg-hover);
  color: var(--accent);
}
.head-btn--close:hover {
  background: var(--danger-bg);
  color: var(--danger);
}

/* ---------- 会话抽屉 ---------- */
.conv-drawer {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  width: 260px;
  background: var(--bg-surface);
  border-right: 1px solid var(--border-default);
  z-index: 5;
  display: flex;
  flex-direction: column;
  box-shadow: 6px 0 20px rgba(0, 0, 0, 0.08);
}
.conv-drawer__head {
  padding: var(--space-3);
  border-bottom: 1px solid var(--border-subtle);
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
}
.new-chat-btn {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: var(--radius-sm);
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: var(--text-inverse);
  cursor: pointer;
  transition: var(--transition-fast);
  box-shadow: var(--shadow-accent);
}
.new-chat-btn:hover {
  transform: scale(1.08);
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
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  cursor: pointer;
  margin-bottom: 2px;
  border: 1px solid transparent;
  transition: var(--transition-fast);
}
.conv-item:hover {
  background: var(--bg-hover);
}
.conv-item.active {
  background: var(--info-bg);
  border-color: var(--border-accent);
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
  font-size: 11px;
  color: var(--text-muted);
}
.conv-del {
  width: 24px;
  height: 24px;
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

/* ---------- 上下文芯片 ---------- */
.context-chip {
  margin: var(--space-2) var(--space-3) 0;
  padding: 6px 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--success-bg);
  border: 1px solid rgba(16, 185, 129, 0.25);
  border-radius: var(--radius-sm);
  font-size: 12px;
  color: var(--text-secondary);
  flex-shrink: 0;
}
.context-chip .el-icon {
  color: var(--success);
  font-size: 13px;
}
.context-chip__text {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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

/* ---------- 内联错误条 ---------- */
.error-banner {
  margin: var(--space-2) var(--space-3) 0;
  padding: 7px 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--danger-bg);
  border: 1px solid rgba(239, 68, 68, 0.25);
  border-radius: var(--radius-sm);
  font-size: 12px;
  color: var(--danger);
  flex-shrink: 0;
  animation: ai-shake 0.3s ease;
}
.error-banner__icon {
  font-size: 14px;
  flex-shrink: 0;
}
.error-banner__text {
  flex: 1;
  line-height: 1.4;
}
.error-banner__close {
  border: none;
  background: transparent;
  color: var(--danger);
  cursor: pointer;
  padding: 2px;
  border-radius: var(--radius-xs);
  display: flex;
  opacity: 0.7;
  transition: var(--transition-fast);
}
.error-banner__close:hover {
  opacity: 1;
  background: rgba(239, 68, 68, 0.12);
}
@keyframes ai-shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-2px); }
  75% { transform: translateX(2px); }
}

/* ---------- 消息区 ---------- */
.messages {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-3);
  background: linear-gradient(180deg, var(--bg-deep) 0%, var(--bg-surface) 60px);
}
.welcome {
  padding: var(--space-5) 0;
}
.welcome-hero {
  text-align: center;
  margin-bottom: var(--space-5);
}
.welcome-avatar {
  width: 52px;
  height: 52px;
  margin: 0 auto var(--space-3);
  border-radius: var(--radius-lg);
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-accent);
}
.welcome-hero h3 {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  margin-bottom: 4px;
}
.welcome-hero p {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.6;
  max-width: 280px;
  margin: 0 auto;
}
.example-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-2);
}
.example-card {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  padding: 10px 12px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  cursor: pointer;
  text-align: left;
  font-size: 12px;
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
  margin-top: 1px;
}

/* ---------- 单条消息 ---------- */
.msg {
  display: flex;
  gap: 8px;
  margin-bottom: var(--space-3);
}
.msg-user {
  flex-direction: row-reverse;
}
.msg-avatar {
  width: 28px;
  height: 28px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.avatar-ai {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
  box-shadow: 0 2px 6px rgba(37, 99, 235, 0.25);
}
.avatar-user {
  background: var(--bg-hover);
  color: var(--text-secondary);
}
.msg-body {
  min-width: 0;
  max-width: calc(100% - 36px);
}
.msg-name {
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 2px;
  font-weight: var(--font-medium);
}
.msg-user .msg-name {
  text-align: right;
}
.bubble {
  padding: 9px 13px;
  border-radius: var(--radius);
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  line-height: 1.6;
  box-shadow: var(--shadow-sm);
}
/* AI 气泡：左下角更锐，贴近头像 */
.msg-ai .bubble {
  border-bottom-left-radius: 4px;
}
/* 用户气泡：右下角更锐，主色填充 */
.msg-user .bubble {
  background: linear-gradient(135deg, var(--accent), var(--accent-light));
  border-color: transparent;
  color: var(--text-inverse);
  border-bottom-right-radius: 4px;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
}
.bubble-error {
  border-color: var(--danger);
}
.msg-content {
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 13px;
  color: var(--text-primary);
}
.msg-user .msg-content {
  color: var(--text-inverse);
}
.msg-content :deep(code) {
  background: var(--bg-hover);
  padding: 1px 5px;
  border-radius: var(--radius-xs);
  font-family: var(--font-mono);
  font-size: 0.9em;
}
.msg-user .msg-content :deep(code) {
  background: rgba(255, 255, 255, 0.22);
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
  margin-top: 6px;
  padding: 6px 8px;
  background: var(--danger-bg);
  border-radius: var(--radius-xs);
  font-size: 12px;
  color: var(--danger);
}

/* ---------- 引用 / 推荐 ---------- */
.attach-block {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px dashed var(--border-default);
}
.attach-title {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: var(--font-semibold);
  color: var(--text-muted);
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.source-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.source-item {
  padding: 7px 9px;
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
  gap: 6px;
}
.source-icon {
  color: var(--accent);
  flex-shrink: 0;
  font-size: 13px;
}
.source-title {
  flex: 1;
  font-size: 12px;
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
  margin-top: 3px;
  font-size: 11px;
  color: var(--text-secondary);
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.resource-list {
  display: grid;
  grid-template-columns: 1fr;
  gap: 6px;
}
.resource-card {
  display: flex;
  gap: 8px;
  padding: 6px;
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
  width: 42px;
  height: 42px;
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
  font-size: 12px;
  font-weight: var(--font-medium);
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.res-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--text-muted);
}
.res-tag {
  padding: 0 5px;
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
  padding: var(--space-2) var(--space-3) var(--space-3);
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-overlay);
  backdrop-filter: blur(14px);
}
.composer-inner {
  display: flex;
  align-items: flex-end;
  gap: 6px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius);
  padding: 6px;
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
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
  padding: 4px 6px;
  max-height: 120px;
}
.composer-input::placeholder {
  color: var(--text-muted);
}
.composer-input:disabled {
  cursor: not-allowed;
}
.send-btn {
  height: 34px;
  padding: 0 14px;
  border: none;
  border-radius: var(--radius-sm);
  background: linear-gradient(135deg, var(--accent), var(--accent-light));
  color: var(--text-inverse);
  font-size: 12px;
  font-weight: var(--font-medium);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: var(--transition-fast);
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
}
.send-btn:hover:not(:disabled) {
  background: linear-gradient(135deg, var(--accent-dim), var(--accent));
  transform: translateY(-1px);
}
.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* ---------- 过渡 ---------- */
.ai-fade-enter-active,
.ai-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.ai-fade-enter-from,
.ai-fade-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.96);
}

.ai-slide-enter-active,
.ai-slide-leave-active {
  transition: transform 0.2s ease;
}
.ai-slide-enter-from,
.ai-slide-leave-to {
  transform: translateX(-100%);
}

/* ---------- 移动端：底部抽屉 ---------- */
@media (max-width: 767px) {
  .ai-float-root {
    right: 16px;
    bottom: 16px;
  }
  .ai-fab {
    width: 52px;
    height: 52px;
  }
  .ai-float-panel {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    top: 16vh;
    width: auto;
    height: auto;
    min-height: 0;
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  }
  .example-grid {
    grid-template-columns: 1fr 1fr;
  }
}
</style>
