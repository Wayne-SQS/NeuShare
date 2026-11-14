import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getConversations,
  createConversation,
  getMessages,
  deleteConversation,
  chatStream
} from '@/api/ai'

/**
 * 把 axios/网络错误转成用户能看懂的文案。
 * 悬浮窗是后台常驻组件，加载失败不应反复弹全屏 toast，而是渲染内联提示。
 */
function friendlyError(e, fallback) {
  if (!e) return fallback
  const status = e?.response?.status
  if (status === 401) return '登录已过期，请重新登录'
  if (status === 429) return '提问过于频繁，请稍后再试'
  if (status === 500 || status === 502 || status === 503 || status === 504)
    return 'AI 服务暂时不可用，请稍后重试'
  if (!e.response) return '网络连接失败，请检查网络'
  return e?.message || fallback
}

/**
 * 把流式聊天返回的原始错误（如 LLM SDK 抛出的英文异常）转成用户能看懂的文案，
 * 避免把 "The api_key client option must be set..." 这类技术细节直接暴露在气泡里。
 */
function friendlyChatError(msg) {
  if (!msg) return ''
  const m = String(msg).toLowerCase()
  if (m.includes('api_key') || m.includes('api key') || m.includes('openai_api_key'))
    return 'AI 模型尚未配置 API Key，暂时无法生成回答。请在服务端配置 DEEPSEEK_API_KEY 后重试。'
  if (m.includes('timeout') || m.includes('timed out')) return 'AI 响应超时，请稍后重试'
  if (m.includes('rate limit') || m.includes('429')) return '提问过于频繁，请稍后再试'
  return String(msg)
}

/**
 * AI 助手全局状态。
 *
 * 把会话 / 消息流 / 流式发送 / 资料上下文从页面级提升到全局，
 * 支撑「悬浮窗」跨页面常驻：切页不丢会话、流式回答不中断。
 * 视图相关（DOM 滚动、Markdown 渲染、跳转）留在组件里。
 */
export const useAiStore = defineStore('ai', () => {
  // ---------- 面板状态 ----------
  const open = ref(false)
  const convDrawer = ref(false) // 会话列表抽屉（浮窗内）
  const initialized = ref(false)

  // ---------- 数据 ----------
  const conversations = ref([])
  const currentId = ref(null)
  const messages = ref([])
  const streaming = ref(false)
  const loadingConv = ref(false)
  // 后台加载（会话列表 / 历史消息）失败时的内联提示，避免反复弹全屏 toast
  const error = ref('')

  // 当前咨询的资料上下文（来自资源详情「问 AI」注入）
  const contextResourceId = ref(null)
  const contextResourceTitle = ref('')

  // 悬浮按钮活动提示：流式生成中高亮
  const hasActivity = computed(() => streaming.value)

  // ---------- 生命周期 ----------
  async function init() {
    if (initialized.value) return
    initialized.value = true
    await loadConversations()
  }

  // ---------- 面板控制 ----------
  function show() {
    open.value = true
  }
  function hide() {
    open.value = false
  }
  function toggle() {
    open.value = !open.value
  }

  /**
   * 唤起浮窗并注入资料上下文（资源详情「问 AI」用，不跳页）。
   */
  async function openWithContext(id, title) {
    contextResourceId.value = id ? Number(id) : null
    contextResourceTitle.value = title || ''
    convDrawer.value = false
    open.value = true
    if (!initialized.value) await init()
  }

  function clearContext() {
    contextResourceId.value = null
    contextResourceTitle.value = ''
  }

  function clearError() {
    error.value = ''
  }

  // ---------- 会话 ----------
  async function loadConversations() {
    loadingConv.value = true
    try {
      error.value = ''
      const list = await getConversations()
      conversations.value = list || []
      if (currentId.value && !conversations.value.some((c) => c.id === currentId.value)) {
        currentId.value = null
      }
      if (!currentId.value && conversations.value.length) {
        selectConversation(conversations.value[0].id)
      }
    } catch (e) {
      error.value = friendlyError(e, '加载会话失败')
    } finally {
      loadingConv.value = false
    }
  }

  async function selectConversation(id) {
    currentId.value = id
    convDrawer.value = false
    messages.value = []
    try {
      error.value = ''
      const list = await getMessages(id)
      messages.value = (list || []).map((m) => ({
        role: m.role,
        content: m.content || '',
        sources: parseJson(m.sources),
        resources: parseJson(m.resources)
      }))
    } catch (e) {
      error.value = friendlyError(e, '加载消息失败')
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

  function newChat() {
    currentId.value = null
    messages.value = []
    convDrawer.value = false
    // 不立即创建空会话：首条消息发送时再创建，避免产生空会话
  }

  async function removeConversation(id) {
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

  // ---------- 发送 ----------
  async function send(text) {
    if (streaming.value) return
    const question = (text != null ? text : '').trim()
    if (!question) return

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

    // 通知视图滚到底部（组件通过 watch streaming/messages 触发）
    scrollSignal.value++

    try {
      await chatStream({
        question,
        conversation_id: currentId.value,
        resource_id: contextResourceId.value || undefined,
        onToken: (delta) => {
          aiMsg.content += delta
          scrollSignal.value++
        },
        onSources: (src) => {
          aiMsg.sources = src || []
          scrollSignal.value++
        },
        onResources: (res) => {
          aiMsg.resources = res || []
          scrollSignal.value++
        },
        onError: (msg) => {
          aiMsg.error = friendlyChatError(msg) || 'AI 服务出错了，请稍后重试'
        }
      })
      // 后端可能用首条问题更新了会话标题，刷新列表
      await loadConversations()
    } catch (e) {
      if (!aiMsg.error) aiMsg.error = friendlyChatError(e?.message) || '发送失败'
    } finally {
      streaming.value = false
      scrollSignal.value++
    }
  }

  // 视图层据此触发滚动（store 不碰 DOM）
  const scrollSignal = ref(0)

  return {
    // state
    open,
    convDrawer,
    initialized,
    conversations,
    currentId,
    messages,
    streaming,
    loadingConv,
    contextResourceId,
    contextResourceTitle,
    scrollSignal,
    error,
    // getters
    hasActivity,
    // actions
    init,
    show,
    hide,
    toggle,
    openWithContext,
    clearContext,
    clearError,
    loadConversations,
    selectConversation,
    newChat,
    removeConversation,
    send
  }
})
