import { HttpClient, ApiResponse, PageData } from '@neushare/common';

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

export interface MyCommentItem {
  id: number;
  sourceId: number;
  sourceType: string;   // "resource" | "post"
  sourceTitle: string;
  content: string;
  parentId: number;
  deleted: number;
  createTime: string;
  likeCount: number;
  replyCount: number;
}

interface CommentAddParams {
  resourceId: number;
  content: string;
  parentId?: number;
}

interface MyCommentsParams {
  pageNum: number;
  pageSize: number;
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

  async getMyComments(pageNum: number, pageSize: number): Promise<ApiResponse<PageData<MyCommentItem>>> {
    const myParams: MyCommentsParams = { pageNum: pageNum, pageSize: pageSize };
    return this.http.get<PageData<MyCommentItem>>('/api/comment/my', myParams);
  }

  async likeComment(id: number): Promise<ApiResponse<null>> {
    return this.http.post<null>('/api/comment/like/' + id);
  }

  async unlikeComment(id: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/comment/like/' + id);
  }

  async checkCommentLiked(id: number): Promise<ApiResponse<boolean>> {
    return this.http.get<boolean>('/api/comment/like/check/' + id);
  }
}
