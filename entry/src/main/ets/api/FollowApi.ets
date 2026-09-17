import { HttpClient, ApiResponse, PageData } from '@neushare/common';

export interface FollowUser {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
  college: string;
}

export interface FollowCheckResult {
  isFollowing: boolean;
}

interface FollowParams {
  followedId: number;
}

interface FollowListParams {
  pageNum?: number;
  pageSize?: number;
}

export class FollowApi {
  private http: HttpClient = HttpClient.getInstance();

  async follow(followedId: number): Promise<ApiResponse<null>> {
    // 后端 @RequestParam followedId，必须用查询参数
    const params: FollowParams = { followedId: followedId };
    return this.http.postWithParams<null>('/api/follow/add', params);
  }

  async unfollow(followedId: number): Promise<ApiResponse<null>> {
    const params: FollowParams = { followedId: followedId };
    return this.http.deleteWithParams<null>('/api/follow/remove', params);
  }

  async check(followedId: number): Promise<ApiResponse<FollowCheckResult>> {
    const params: FollowParams = { followedId: followedId };
    return this.http.get<FollowCheckResult>('/api/follow/check', params);
  }

  async getFollowing(pageNum?: number): Promise<ApiResponse<PageData<FollowUser>>> {
    const params: FollowListParams = {
      pageNum: pageNum,
      pageSize: 10
    };
    return this.http.get<PageData<FollowUser>>('/api/follow/following', params);
  }

  async getFollowers(pageNum?: number): Promise<ApiResponse<PageData<FollowUser>>> {
    const params: FollowListParams = {
      pageNum: pageNum,
      pageSize: 10
    };
    return this.http.get<PageData<FollowUser>>('/api/follow/followers', params);
  }
}
