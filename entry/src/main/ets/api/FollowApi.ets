import { HttpClient, ApiResponse } from '@neushare/common';

interface FollowBody {
  userId: number;
}

export interface FollowUser {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
}

export class FollowApi {
  private http: HttpClient = HttpClient.getInstance();

  async follow(userId: number): Promise<ApiResponse<null>> {
    const body: FollowBody = { userId: userId };
    return this.http.post<null>('/api/follow/add', body);
  }

  async unfollow(userId: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/follow/remove?userId=' + userId);
  }

  async check(userId: number): Promise<ApiResponse<boolean>> {
    return this.http.get<boolean>('/api/follow/check?userId=' + userId);
  }

  async getFollowing(): Promise<ApiResponse<FollowUser[]>> {
    return this.http.get<FollowUser[]>('/api/follow/following');
  }

  async getFollowers(): Promise<ApiResponse<FollowUser[]>> {
    return this.http.get<FollowUser[]>('/api/follow/followers');
  }
}
