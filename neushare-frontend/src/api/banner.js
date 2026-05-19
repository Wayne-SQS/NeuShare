import request from './request'

export function getBannerList() {
  return request({
    url: '/banner/list',
    method: 'get'
  })
}
