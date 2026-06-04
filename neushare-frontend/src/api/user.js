import request from './request'

export function getUserProfile(id) {
  return request({
    url: `/user/${id}`,
    method: 'get'
  })
}

export function getUserResources(id, params) {
  return request({
    url: `/user/${id}/resources`,
    method: 'get',
    params
  })
}
