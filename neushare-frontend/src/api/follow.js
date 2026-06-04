import request from './request'

export function followUser(followedId) {
  return request({
    url: '/follow/add',
    method: 'post',
    params: { followedId }
  })
}

export function unfollowUser(followedId) {
  return request({
    url: '/follow/remove',
    method: 'delete',
    params: { followedId }
  })
}

export function checkFollow(followedId) {
  return request({
    url: '/follow/check',
    method: 'get',
    params: { followedId }
  })
}
