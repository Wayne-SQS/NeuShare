import axios from 'axios'
import router from '@/router'

/**
 * NeuShare AI 服务 API 模块。
 * 后端是独立的 Python FastAPI 服务（:8000），Vite 已把 /ai 代理过去。
 * 会话 CRUD 走 axios；流式聊天走 fetch + 手动 SSE 解析
 * （EventSource 不支持 POST 与自定义 Authorization 头）。
 */

// 独立实例：baseURL = /ai，复用 token，401 统一跳登录
const aiRequest = axios.create({
  baseURL: '/ai',
  timeout: 30000
})

aiRequest.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

aiRequest.interceptors.response.use(
  (response) => {
    const res = response.data
    // 与 Java 后端一致：code 0 / 200 视为成功
    if (res.code === 0 || res.code === 200) return res
    return Promise.reject(new Error(res.message || '请求失败'))
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      router.push('/login')
    }
    return Promise.reject(error)
  }
)

// ---------------- 会话 ----------------
export const getConversations = () => aiRequest.get('/conversations').then((r) => r.data)

export const createConversation = (title = '新对话') =>
  aiRequest.post('/conversations', { title }).then((r) => r.data)

export const getMessages = (conversationId) =>
  aiRequest.get(`/conversations/${conversationId}/messages`).then((r) => r.data)

export const deleteConversation = (conversationId) =>
  aiRequest.delete(`/conversations/${conversationId}`).then((r) => r.data)

// ---------------- 流式聊天（SSE） ----------------
/**
 * @param {Object} opts
 * @param {string} opts.question
 * @param {number} [opts.conversation_id]
 * @param {number} [opts.resource_id]  当前查看的资料，agent 优先围绕它检索
 * @param {(delta:string)=>void} [opts.onToken]
 * @param {(sources:Array)=>void} [opts.onSources]
 * @param {(resources:Array)=>void} [opts.onResources]
 * @param {(msg:string)=>void} [opts.onError]
 * @param {(conversationId:number)=>void} [opts.onDone]
 * @returns {Promise<number>} resolve 为 conversation_id
 */
export function chatStream(opts) {
  return new Promise((resolve, reject) => {
    const body = { question: opts.question }
    if (opts.conversation_id) body.conversation_id = Number(opts.conversation_id)
    if (opts.resource_id) body.resource_id = Number(opts.resource_id)

    const headers = { 'Content-Type': 'application/json', Accept: 'text/event-stream' }
    const token = localStorage.getItem('token')
    if (token) headers.Authorization = `Bearer ${token}`

    let settled = false

    const handleBlock = (block) => {
      const lines = block.split('\n')
      let event = 'message'
      const dataLines = []
      for (const line of lines) {
        if (line.startsWith('event:')) event = line.slice(6).trim()
        else if (line.startsWith('data:')) dataLines.push(line.slice(5).trim())
      }
      const dataStr = dataLines.join('\n')
      let data = null
      if (dataStr) {
        try {
          data = JSON.parse(dataStr)
        } catch (e) {
          data = dataStr
        }
      }
      if (event === 'token') {
        opts.onToken && opts.onToken(data && data.delta != null ? data.delta : '')
      } else if (event === 'sources') {
        opts.onSources && opts.onSources((data && data.sources) || [])
      } else if (event === 'resources') {
        opts.onResources && opts.onResources((data && data.resources) || [])
      } else if (event === 'error') {
        const msg = (data && data.message) || 'AI 服务出错了'
        opts.onError && opts.onError(msg)
        if (!settled) {
          settled = true
          reject(new Error(msg))
        }
      } else if (event === 'done') {
        opts.onDone && opts.onDone(data && data.conversation_id)
        if (!settled) {
          settled = true
          resolve(data && data.conversation_id)
        }
      }
    }

    fetch('/ai/chat/stream', {
      method: 'POST',
      headers,
      body: JSON.stringify(body)
    })
      .then(async (response) => {
        if (!response.ok) {
          // 429 限流 / 500 等：尽量读出后端 message
          let msg = `请求失败 (${response.status})`
          try {
            const j = await response.json()
            if (j && j.message) msg = j.message
          } catch (e) {
            /* ignore */
          }
          opts.onError && opts.onError(msg)
          if (!settled) {
            settled = true
            reject(new Error(msg))
          }
          return
        }
        if (!response.body) {
          const msg = '浏览器不支持流式响应'
          opts.onError && opts.onError(msg)
          if (!settled) {
            settled = true
            reject(new Error(msg))
          }
          return
        }
        const reader = response.body.getReader()
        const decoder = new TextDecoder()
        let buffer = ''
        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buffer += decoder.decode(value, { stream: true })
          let idx
          while ((idx = buffer.indexOf('\n\n')) !== -1) {
            const block = buffer.slice(0, idx)
            buffer = buffer.slice(idx + 2)
            if (block.trim()) handleBlock(block)
          }
        }
        // 收尾：部分实现末尾可能缺 \n\n
        if (buffer.trim()) handleBlock(buffer)
        // 流正常结束但没收到 done 事件：兜底 resolve
        if (!settled) {
          settled = true
          resolve(opts.conversation_id || null)
        }
      })
      .catch((err) => {
        const msg = (err && err.message) || '网络连接失败'
        opts.onError && opts.onError(msg)
        if (!settled) {
          settled = true
          reject(err)
        }
      })
  })
}
