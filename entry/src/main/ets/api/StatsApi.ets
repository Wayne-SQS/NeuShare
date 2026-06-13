import { HttpClient, ApiResponse } from '@neushare/common';

export interface DistributionItem {
  name: string;
  count: number;
}

export interface TopResourceItem {
  id: number;
  title: string;
  type: string;
  viewCount: number;
  likeCount: number;
  favoriteCount: number;
}

export interface StatsOverview {
  totalResources: number;
  totalUsers: number;
  totalComments: number;
  totalFavorites: number;
  totalLikes: number;
  totalViews: number;
  pendingResources: number;
  categoryDistribution: DistributionItem[];
  typeDistribution: DistributionItem[];
  sourceDistribution: DistributionItem[];
  topResources: TopResourceItem[];
  recentUploads: number;
}

export class StatsApi {
  private http: HttpClient = HttpClient.getInstance();

  async getOverview(): Promise<ApiResponse<StatsOverview>> {
    return this.http.get<StatsOverview>('/api/stats/overview');
  }
}
