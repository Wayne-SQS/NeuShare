// ============================================================
// PageData<T> — 统一的后端分页响应接口
// 对应 Spring Boot PageResult<T> 结构
// ============================================================

export interface PageData<T> {
  current: number;
  size: number;
  total: number;
  pages: number;
  records: T[];
}
