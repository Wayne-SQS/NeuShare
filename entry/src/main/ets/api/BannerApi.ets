import { HttpClient, ApiResponse } from '@neushare/common';
import { BannerVO } from '../models/ResourceModel';

export class BannerApi {
  private http: HttpClient = HttpClient.getInstance();

  async getList(): Promise<ApiResponse<BannerVO[]>> {
    return this.http.get<BannerVO[]>('/api/banner/list');
  }
}
