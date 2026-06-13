import { HttpClient, ApiResponse } from '@neushare/common';

export interface CommentItem {
  id: number;
  resourceId: number;
  userId: number;
  nickname: string;
  avatarUrl: string;
  content: string;
  parentId: number;
  deleted: number;
  children: CommentItem[];
  createTime: string;
}

interface CommentAddParams {
  resourceId: number;
  content: string;
  parentId?: number;
}

export class CommentApi {
  private http: HttpClient = HttpClient.getInstance();

  async getList(resourceId: number): Promise<ApiResponse<CommentItem[]>> {
    return this.http.get<CommentItem[]>('/api/comment/list/' + resourceId);
  }

  async add(resourceId: number, content: string, parentId: number): Promise<ApiResponse<null>> {
    const params: CommentAddParams = {
      resourceId: resourceId,
      content: content
    };
    if (parentId) { params.parentId = parentId; }
    return this.http.postWithParams<null>('/api/comment/add', params);
  }

  async deleteComment(id: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/comment/delete/' + id);
  }

  async getUserComments(): Promise<ApiResponse<CommentItem[]>> {
    return this.http.get<CommentItem[]>('/api/comment/user');
  }
}
