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

export function searchResources(keyword, sortBy = 'new') {
  return request({
    url: '/resource/search',
    method: 'get',
    params: { keyword, sortBy }
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
