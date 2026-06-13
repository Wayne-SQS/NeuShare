import request from './request'

export function getNotifications(params) {
  return request({
    url: '/notification/list',
    method: 'get',
    params
  })
}

export function getUnreadCount() {
  return request({
    url: '/notification/unread',
    method: 'get'
  })
}

export function markAsRead(id) {
  return request({
    url: `/notification/read/${id}`,
    method: 'put'
  })
}

export function markAllAsRead() {
  return request({
    url: '/notification/read-all',
    method: 'put'
  })
}
