/**
 * 资源地址工具：把后端返回的相对路径拼接为当前站点可访问的完整 URL。
 *
 * 后端 content_url 可能是：
 *   - 外链（http/https）：原样返回，由浏览器直接访问
 *   - 裸文件名（如 test-math-notes.pdf）：存于 uploads 目录，经后端 /files/** 静态映射暴露
 *   - 已带 /files/ 前缀的路径：去重后返回
 *
 * 开发环境经 Vite /files 代理转发到后端；生产环境由 nginx 同源提供 /files。
 */

const EXTERNAL_RE = /^https?:\/\//i

export function isExternalUrl(url) {
  return !!url && EXTERNAL_RE.test(url)
}

/**
 * 把 content_url 转成可在浏览器打开/下载的 URL。
 */
export function buildFullUrl(path) {
  if (!path) return ''
  if (isExternalUrl(path)) return path
  const p = String(path).replace(/^\/+/, '')
  if (p.startsWith('files/')) {
    return '/' + p
  }
  return `/files/${p}`
}

/**
 * 取文件扩展名（小写，不含点），无扩展名返回空串
 */
export function getFileExtension(filename) {
  if (!filename) return ''
  const name = String(filename).split('?')[0]
  const idx = name.lastIndexOf('.')
  return idx >= 0 ? name.slice(idx + 1).toLowerCase() : ''
}

/**
 * 是否可在浏览器内联预览（图片 / PDF / 文本）。
 * 其余类型走下载，避免浏览器无法渲染导致空白页。
 */
const PREVIEWABLE_EXT = new Set([
  'pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'txt', 'md', 'csv'
])
export function isPreviewable(filename) {
  return PREVIEWABLE_EXT.has(getFileExtension(filename))
}
