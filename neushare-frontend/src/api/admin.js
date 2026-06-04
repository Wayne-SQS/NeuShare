import request from './request'

export function getStatistics() {
  return request({
    url: '/admin/statistics',
    method: 'get'
  })
}

export function getUserList(params) {
  return request({
    url: '/admin/user/list',
    method: 'get',
    params
  })
}

export function updateUserStatus(id, status) {
  return request({
    url: '/admin/user/status',
    method: 'put',
    params: { id, status }
  })
}

export function deleteUser(id) {
  return request({
    url: `/admin/user/delete/${id}`,
    method: 'delete'
  })
}

export function getPendingResources(params) {
  return request({
    url: '/admin/resource/pending',
    method: 'get',
    params
  })
}

export function auditResource(id, status) {
  return request({
    url: '/admin/resource/audit',
    method: 'put',
    params: { id, status }
  })
}

export function deleteAdminResource(id) {
  return request({
    url: `/admin/resource/delete/${id}`,
    method: 'delete'
  })
}

export function getAdminCommentList(params) {
  return request({
    url: '/admin/comment/list',
    method: 'get',
    params
  })
}

export function deleteAdminComment(id) {
  return request({
    url: `/admin/comment/delete/${id}`,
    method: 'delete'
  })
}

export function getBannerList() {
  return request({
    url: '/admin/banner/list',
    method: 'get'
  })
}

export function addBanner(data) {
  return request({
    url: '/admin/banner/add',
    method: 'post',
    data
  })
}

export function updateBanner(data) {
  return request({
    url: '/admin/banner/update',
    method: 'put',
    data
  })
}

export function deleteBanner(id) {
  return request({
    url: `/admin/banner/delete/${id}`,
    method: 'delete'
  })
}

export function updateBannerStatus(id, status) {
  return request({
    url: '/admin/banner/status',
    method: 'put',
    params: { id, status }
  })
}
