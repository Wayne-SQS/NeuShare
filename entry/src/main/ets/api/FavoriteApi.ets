import { HttpClient, ApiResponse } from '@neushare/common';
import { ResourceVO } from '../models/ResourceModel';

export interface FavoriteCheckResult {
  isFavorite: boolean;
}

// 后端 /api/favorite/list 返回的是 PageResult<ResourceVO>（扁平资源列表，含 favoriteTime）
// 不是嵌套 { resource: ResourceVO } 结构
export interface FavoriteListResult {
  current: number;
  pages: number;
  records: ResourceVO[];
  size: number;
  total: number;
}

interface FavoriteAddParams {
  resourceId: number;
}

interface FavoriteCheckParams {
  resourceId: number;
}

interface FavoriteRemoveParams {
  resourceId: number;
}

interface FavoriteListParams {
  pageNum: number;
  pageSize: number;
}

export class FavoriteApi {
  private http: HttpClient = HttpClient.getInstance();

  async add(resourceId: number): Promise<ApiResponse<null>> {
    const params: FavoriteAddParams = { resourceId: resourceId };
    return this.http.postWithParams<null>('/api/favorite/add', params);
  }

  async remove(resourceId: number): Promise<ApiResponse<null>> {
    const removeParams: FavoriteRemoveParams = { resourceId: resourceId };
    return this.http.deleteWithParams<null>('/api/favorite/remove', removeParams);
  }

  async check(resourceId: number): Promise<ApiResponse<FavoriteCheckResult>> {
    const params: FavoriteCheckParams = { resourceId: resourceId };
    return this.http.get<FavoriteCheckResult>('/api/favorite/check', params);
  }

  async getList(pageNum: number, pageSize: number): Promise<ApiResponse<FavoriteListResult>> {
    const params: FavoriteListParams = { pageNum: pageNum, pageSize: pageSize };
    return this.http.get<FavoriteListResult>('/api/favorite/list', params);
  }
}
