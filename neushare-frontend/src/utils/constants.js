export const RESOURCE_STATUS = {
  PENDING: 0,
  PUBLISHED: 1,
  REJECTED: 2
}

export const RESOURCE_STATUS_MAP = {
  [RESOURCE_STATUS.PENDING]: '待审核',
  [RESOURCE_STATUS.PUBLISHED]: '已发布',
  [RESOURCE_STATUS.REJECTED]: '已驳回'
}

export const RESOURCE_STATUS_TAG_TYPE = {
  [RESOURCE_STATUS.PENDING]: 'warning',
  [RESOURCE_STATUS.PUBLISHED]: 'success',
  [RESOURCE_STATUS.REJECTED]: 'danger'
}

export const USER_STATUS = {
  DISABLED: 0,
  ENABLED: 1
}

export const ROLE_MAP = {
  admin: '管理员',
  teacher: '教师',
  student: '学生',
  user: '用户'
}

export const ROLE_TAG_TYPE = {
  admin: 'danger',
  teacher: 'warning',
  student: 'primary',
  user: 'info'
}

export const GRADE_LABELS = ['大一', '大二', '大三', '大四']
