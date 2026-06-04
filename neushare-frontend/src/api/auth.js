import request from './request'

export function login(username, password) {
  return request({
    url: '/auth/login',
    method: 'post',
    data: { username, password }
  })
}

export function register(data) {
  return request({
    url: '/auth/register',
    method: 'post',
    data
  })
}

export function getUserInfo() {
  return request({
    url: '/auth/info',
    method: 'get'
  })
}

export function updateUserInfo(data) {
  return request({
    url: '/auth/info',
    method: 'put',
    data
  })
}

export function updatePassword(oldPassword, newPassword) {
  return request({
    url: '/auth/password',
    method: 'put',
    params: { oldPassword, newPassword }
  })
}
