import { HttpClient, ApiResponse } from '@neushare/common';
import { ResourceVO } from '../models/ResourceModel';

export interface FavoriteItem {
  id: number;
  resourceId: number;
  userId: number;
  resource: ResourceVO;
  createTime: string;
}

export interface FavoriteCheckResult {
  isFavorite: boolean;
}

export interface FavoriteListResult {
  current: number;
  pages: number;
  records: FavoriteItem[];
  size: number;
  total: number;
}

interface FavoriteAddParams {
  resourceId: number;
}

interface FavoriteCheckParams {
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
    return this.http.del<null>('/api/favorite/remove?resourceId=' + resourceId);
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
