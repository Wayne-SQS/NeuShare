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

interface SearchParams {
  keyword: string;
  pageNum: number;
  pageSize: number;
  sortBy: string;
}

interface UserResourcesParams {
  pageNum: number;
  pageSize: number;
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

  async search(keyword: string, pageNum: number = 1, pageSize: number = 10, sortBy: string = 'new'): Promise<ApiResponse<ResourceListResult>> {
    const params: SearchParams = {
      keyword: keyword,
      pageNum: pageNum,
      pageSize: pageSize,
      sortBy: sortBy
    };
    return this.http.get<ResourceListResult>('/api/resource/search', params);
  }

  async getCategories(): Promise<ApiResponse<CategoryVO[]>> {
    return this.http.get<CategoryVO[]>('/api/category/list');
  }

  async create(data: ResourceCreateData): Promise<ApiResponse<null>> {
    return this.http.post<null>('/api/resource/create', data);
  }

  /**
   * FormData 文件上传创建资源
   * 对接后端 POST /api/resource/create（MultipartFile file）
   * @param data 资源字段
   * @param fileUri 可选的文件 URI（来自 picker.DocumentViewPicker）
   */
  async createWithFile(data: ResourceCreateData, fileUri?: string): Promise<ApiResponse<null>> {
    const fields: Record<string, string> = {
      'title': data.title,
      'categoryId': data.categoryId.toString(),
      'type': data.type,
      'description': data.description,
      'contentUrl': data.contentUrl,
      'coverUrl': data.coverUrl,
      'source': data.source
    };
    return this.http.postFormData<null>('/api/resource/create', fields, fileUri, 'file');
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

  async getUserResources(pageNum: number = 1, pageSize: number = 10): Promise<ApiResponse<ResourceListResult>> {
    const userParams: UserResourcesParams = { pageNum: pageNum, pageSize: pageSize };
    return this.http.get<ResourceListResult>('/api/resource/user', userParams);
  }

  async checkLiked(id: number): Promise<ApiResponse<boolean>> {
    return this.http.get<boolean>('/api/resource/like/check/' + id);
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
  source: string;
}
