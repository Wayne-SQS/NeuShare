/**
 * NeuShare Web 主题切换（v3.0）
 *
 * 主题层的唯一开关：给 <html> 写 data-theme="light" | "dark"，
 * 具体颜色全部由 src/styles/theme-v3.css 的变量决定，这里不碰样式。
 * 偏好持久化到 localStorage，键名 ns-theme。
 */
const STORAGE_KEY = 'ns-theme'

export function getTheme() {
  return document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light'
}

export function applyTheme(theme) {
  const next = theme === 'dark' ? 'dark' : 'light'
  document.documentElement.dataset.theme = next
  try {
    localStorage.setItem(STORAGE_KEY, next)
  } catch (e) {
    // 隐私模式 / 禁用存储时，切换仍然生效，只是不跨会话保留
  }
  // ECharts 是 canvas 渲染，读不到 CSS 变量；通知图表组件按新主题重绘
  window.dispatchEvent(new CustomEvent('ns-theme-change', { detail: next }))
  return next
}

/** 应用启动时调用一次，避免深色用户出现亮色闪屏 */
export function initTheme() {
  let saved = null
  try {
    saved = localStorage.getItem(STORAGE_KEY)
  } catch (e) {
    // ignore
  }
  return applyTheme(saved || 'light')
}

export function toggleTheme() {
  return applyTheme(getTheme() === 'dark' ? 'light' : 'dark')
}
