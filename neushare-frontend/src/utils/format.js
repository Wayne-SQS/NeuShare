export function formatTime(time) {
  if (!time) return ''
  const now = Date.now()
  const date = new Date(time)
  const diff = now - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) {
    const hours = Math.floor(diff / (1000 * 60 * 60))
    if (hours === 0) {
      const minutes = Math.floor(diff / (1000 * 60))
      return minutes <= 0 ? '刚刚' : `${minutes}分钟前`
    }
    return `${hours}小时前`
  } else if (days < 7) {
    return `${days}天前`
  }
  return date.toLocaleDateString()
}

export function getInitial(name) {
  return name?.charAt(0)?.toUpperCase() || '?'
}

export const TERM_LABELS = { spring: '春季', summer: '夏季', autumn: '秋季', winter: '冬季' }

/**
 * 组装资源的结构化归属标签（课程 / 教师 / 学年学期）
 * <p>每个标签自带 query，卡片与详情页点了都能直接按该维度筛选，不必让用户手动重填筛选框。
 *
 * @param {object} resource 资源对象（ResourceVO）
 * @returns {Array<{text: string, query: object}>}
 */
export function buildStructuredTags(resource) {
  const r = resource || {}
  const tags = []
  if (r.courseName) {
    tags.push({ text: r.courseName, query: { courseName: r.courseName } })
  }
  if (r.teacher) {
    // 已经写了"老师"就不再拼，避免出现"张老师 老师"
    const teacherText = /老师$/.test(r.teacher) ? r.teacher : `${r.teacher} 老师`
    tags.push({ text: teacherText, query: { teacher: r.teacher } })
  }
  const yearTerm = [r.schoolYear, r.term ? TERM_LABELS[r.term] || r.term : '']
    .filter(Boolean)
    .join(' ')
  if (yearTerm) {
    const query = {}
    if (r.schoolYear) query.schoolYear = r.schoolYear
    if (r.term) query.term = r.term
    tags.push({ text: yearTerm, query })
  }
  return tags
}

/**
 * 转义 HTML，供 v-html 场景防止用户输入被当成标签执行
 */
export function escapeHtml(text) {
  if (text == null) return ''
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/**
 * 搜索结果高亮：把命中的关键词包成 <mark>，返回可直接 v-html 的安全字符串
 * <p>先转义再插标签，顺序反了等于开了 XSS 口子
 *
 * @param {string} text 原文
 * @param {string} keyword 关键词，支持空格分词
 * @returns {string}
 */
export function highlight(text, keyword) {
  if (text == null) return ''
  const source = String(text)
  const kw = (keyword || '').trim()
  if (!kw) return escapeHtml(source)

  // 按空格拆词，长度太短（如单字）仍高亮，中文场景有意义
  const words = Array.from(
    new Set(kw.split(/\s+/).filter((w) => w.length > 0))
  ).sort((a, b) => b.length - a.length)
  if (words.length === 0) return escapeHtml(source)

  const escaped = escapeHtml(source)
  const pattern = words.map((w) => escapeHtml(w).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')
  return escaped.replace(new RegExp(`(${pattern})`, 'gi'), '<mark class="hl">$1</mark>')
}
