import request from './request'
import { ElMessage } from 'element-plus'

export function getResourceList(params) {
  return request({
    url: '/resource/list',
    method: 'get',
    params
  })
}

export function getResourceDetail(id) {
  return request({
    url: `/resource/detail/${id}`,
    method: 'get'
  })
}

export function getHotResources(limit = 6) {
  return request({
    url: '/resource/hot',
    method: 'get',
    params: { limit }
  })
}

export function searchResources(keyword, sortBy = 'new') {
  // 兼容旧调用（字符串关键词）与新调用（完整 params 对象）
  const params = (keyword && typeof keyword === 'object') ? keyword : { keyword, sortBy }
  return request({
    url: '/resource/search',
    method: 'get',
    params
  })
}

/** V5：已发布资源中出现过的课程与教师 */
export function getResourceFilters() {
  return request({ url: '/resource/filters', method: 'get' })
}

/** V5：搜索联想，返回标题候选 */
export function suggestResources(keyword, limit = 10) {
  return request({ url: '/resource/suggest', method: 'get', params: { keyword, limit } })
}

export function createResource(data, onProgress) {
  return request({
    url: '/resource/create',
    method: 'post',
    data,
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: onProgress
  })
}

export function updateResource(data) {
  return request({
    url: '/resource/update',
    method: 'put',
    data
  })
}

export function deleteResource(id) {
  return request({
    url: `/resource/delete/${id}`,
    method: 'delete'
  })
}

export function getMyResources(params) {
  return request({
    url: '/resource/user',
    method: 'get',
    params
  })
}

export function likeResource(id) {
  return request({
    url: `/resource/like/${id}`,
    method: 'post'
  })
}

export function unlikeResource(id) {
  return request({
    url: `/resource/like/${id}`,
    method: 'delete'
  })
}

export function checkLiked(id) {
  return request({
    url: `/resource/like/check/${id}`,
    method: 'get'
  })
}

export function getCategories() {
  return request({
    url: '/category/list',
    method: 'get'
  })
}

/**
 * 下载资源文件。
 * 后端业务异常统一返回 HTTP 200 + JSON body，这里按 content-type 区分：
 *   - application/json：解析出 message 并提示错误，不触发下载
 *   - 其他：触发浏览器下载，文件名取资源标题（调用方传入）
 */
export async function downloadResource(id, filename) {
  const response = await request({
    url: `/resource/download/${id}`,
    method: 'get',
    responseType: 'blob'
  })
  const contentType = response.headers['content-type'] || ''
  const blob = response.data
  if (contentType.includes('application/json')) {
    // 后端返回的是错误 JSON（如文件已丢失 / 无权限），读出来提示
    try {
      const text = await blob.text()
      const err = JSON.parse(text)
      ElMessage.error(err.message || '下载失败')
    } catch {
      ElMessage.error('下载失败')
    }
    return
  }
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename || `resource-${id}`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  window.URL.revokeObjectURL(url)
}
