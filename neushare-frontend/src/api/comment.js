import request from './request'

export function getComments(resourceId) {
  return request({
    url: `/comment/list/${resourceId}`,
    method: 'get'
  })
}

export function addComment(resourceId, content, parentId) {
  return request({
    url: '/comment/add',
    method: 'post',
    params: {
      resourceId,
      content,
      parentId: parentId || undefined
    }
  })
}

export function deleteComment(id) {
  return request({
    url: `/comment/delete/${id}`,
    method: 'delete'
  })
}

export function getMyComments(params) {
  return request({
    url: '/comment/user',
    method: 'get',
    params
  })
}
