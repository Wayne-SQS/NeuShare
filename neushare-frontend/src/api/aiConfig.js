import request from './request'

/** 拉当前 AI key 配置状态（掩码，无明文） */
export function getAiConfig() {
  return request({
    url: '/ai/config',
    method: 'get'
  })
}

/**
 * 保存 / 清除 AI key。
 * 字段约定与后端一致：不传 = 不改；传 "" = 清除；传值 = 保存。
 * 例：updateAiConfig({ deepseekKey: 'sk-...' }) 只更新 DeepSeek。
 */
export function updateAiConfig(data) {
  return request({
    url: '/ai/config',
    method: 'put',
    data
  })
}
