import { HttpClient, ApiResponse, PageData } from '@neushare/common';
import { ResourceVO } from '../models/ResourceModel';

export interface UserProfile {
  id: number;
  username: string;
  role: string;
  nickname: string;
  avatarUrl: string;
  college: string;
  grade: number;
  status: number;
  resourceCount: number;
  followerCount: number;
  followingCount: number;
  totalLikesReceived: number;
}

interface UserResourcesParams {
  pageNum: number;
  pageSize: number;
}

export class UserApi {
  private httpClient: HttpClient = HttpClient.getInstance();

  async getProfile(userId: number): Promise<ApiResponse<UserProfile>> {
    return this.httpClient.get<UserProfile>('/api/user/' + userId.toString());
  }

  async getUserResources(userId: number, pageNum: number = 1, pageSize: number = 20): Promise<ApiResponse<PageData<ResourceVO>>> {
    const params: UserResourcesParams = { pageNum: pageNum, pageSize: pageSize };
    return this.httpClient.get<PageData<ResourceVO>>('/api/user/' + userId.toString() + '/resources', params);
  }
}
