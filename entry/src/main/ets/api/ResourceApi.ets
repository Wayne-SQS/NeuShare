import { HttpClient, ApiResponse } from '@neushare/common';
import { ResourceVO, CategoryVO } from '../models/ResourceModel';

interface ResourceGetListQuery {
  pageNum: number;
  pageSize: number;
  categoryId?: number;
  keyword?: string;
  status?: number;
}

interface ResourceHotParams {
  limit: number;
}

interface ResourceSearchParams {
  keyword: string;
}

export class ResourceApi {
  private http: HttpClient = HttpClient.getInstance();

  async getList(params: ResourceListParams): Promise<ApiResponse<ResourceListResult>> {
    const queryParams: ResourceGetListQuery = {
      pageNum: params.pageNum,
      pageSize: params.pageSize
    };
    if (params.categoryId) { queryParams.categoryId = params.categoryId; }
    if (params.keyword) { queryParams.keyword = params.keyword; }
    if (params.status !== undefined) { queryParams.status = params.status; }
    return this.http.get<ResourceListResult>('/api/resource/list', queryParams);
  }

  async getDetail(id: number): Promise<ApiResponse<ResourceVO>> {
    return this.http.get<ResourceVO>('/api/resource/detail/' + id);
  }

  async getHot(limit: number): Promise<ApiResponse<ResourceVO[]>> {
    const params: ResourceHotParams = { limit: limit };
    return this.http.get<ResourceVO[]>('/api/resource/hot', params);
  }

  async search(keyword: string): Promise<ApiResponse<ResourceVO[]>> {
    const params: ResourceSearchParams = { keyword: keyword };
    return this.http.get<ResourceVO[]>('/api/resource/search', params);
  }

  async getCategories(): Promise<ApiResponse<CategoryVO[]>> {
    return this.http.get<CategoryVO[]>('/api/category/list');
  }

  async create(data: ResourceCreateData): Promise<ApiResponse<null>> {
    return this.http.post<null>('/api/resource/create', data);
  }

  async deleteResource(id: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/resource/delete/' + id);
  }

  async like(id: number): Promise<ApiResponse<null>> {
    return this.http.post<null>('/api/resource/like/' + id);
  }

  async unlike(id: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/resource/like/' + id);
  }

  async getUserResources(): Promise<ApiResponse<ResourceVO[]>> {
    return this.http.get<ResourceVO[]>('/api/resource/user');
  }
}

export interface ResourceListParams {
  pageNum: number;
  pageSize: number;
  categoryId?: number;
  keyword?: string;
  status?: number;
}

export interface ResourceListResult {
  current: number;
  pages: number;
  records: ResourceVO[];
  size: number;
  total: number;
}

export interface ResourceCreateData {
  title: string;
  categoryId: number;
  type: string;
  description: string;
  contentUrl: string;
  coverUrl: string;
}
