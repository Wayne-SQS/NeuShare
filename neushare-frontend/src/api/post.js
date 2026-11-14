import request from './request'

// 学习社区帖子接口（消费后端已有 /api/post/*）
// 注意：tags / imageUrls / files 在后端是 JSON 字符串，前端需 JSON.parse

export const getPostList = (params) =>
  request({ url: '/post/list', method: 'get', params })

export const getPostDetail = (id) =>
  request({ url: `/post/detail/${id}`, method: 'get' })

export const getHotPosts = (limit = 10) =>
  request({ url: '/post/hot', method: 'get', params: { limit } })

// 发帖：后端 @RequestBody Post 实体，tags/imageUrls/files 需传 JSON 字符串
export const createPost = (data) =>
  request({ url: '/post/create', method: 'post', data })

export const getPostComments = (postId) =>
  request({ url: `/post/comment/list/${postId}`, method: 'get' })

// 添加评论：后端走 @RequestParam（postId/content/parentId）
export const addPostComment = (postId, content, parentId) =>
  request({
    url: '/post/comment/add',
    method: 'post',
    params: { postId, content, parentId: parentId || undefined }
  })
