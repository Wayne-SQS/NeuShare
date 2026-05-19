import request from './request'

export function getFavorites(params) {
  return request({
    url: '/favorite/list',
    method: 'get',
    params
  })
}

export function addFavorite(resourceId) {
  return request({
    url: '/favorite/add',
    method: 'post',
    params: { resourceId }
  })
}

export function removeFavorite(resourceId) {
  return request({
    url: '/favorite/remove',
    method: 'delete',
    params: { resourceId }
  })
}

export function checkFavorite(resourceId) {
  return request({
    url: '/favorite/check',
    method: 'get',
    params: { resourceId }
  })
}
