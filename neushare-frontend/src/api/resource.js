import request from './request'

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

export function searchResources(params) {
  return request({
    url: '/resource/search',
    method: 'get',
    params
  })
}

/**
 * 结构化筛选项：已发布资源中出现过的课程与教师
 */
export function getResourceFilters() {
  return request({
    url: '/resource/filters',
    method: 'get'
  })
}

/**
 * 搜索联想：标题候选
 */
export function suggestResources(keyword, limit = 10) {
  return request({
    url: '/resource/suggest',
    method: 'get',
    params: { keyword, limit }
  })
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
