import { HttpClient, ApiResponse, PageData } from '@neushare/common';

// Backend PostVO response shape
export interface PostVO {
  id: number;
  userId: number;
  title: string;
  content: string;
  tags: string;        // JSON string like '["AI","课程"]'
  imageUrls: string;   // JSON string like '["url1","url2"]'
  files: string;       // JSON string like '[{"name":"a.pdf","uri":"...","type":".pdf","size":1024}]'
  isRecommended: number; // 0 or 1
  viewCount: number;
  likeCount: number;
  favoriteCount: number;
  commentCount: number;
  status: number;
  createTime: string;
  updateTime: string;
  authorNickname: string;
  authorAvatarUrl: string;
  authorCollege: string;
}

// Backend PostCommentVO response shape
export interface PostCommentVO {
  id: number;
  postId: number;
  userId: number;
  content: string;
  parentId: number;
  deleted: number;
  createTime: string;
  nickname: string;
  avatarUrl: string;
  children: PostCommentVO[];
}

interface PostListParams {
  pageNum: number;
  pageSize: number;
  tag?: string;
  keyword?: string;
  sortBy?: string;
}

interface HotPostsParams {
  limit: number;
}

interface UserPostsParams {
  pageNum: number;
  pageSize: number;
}

interface AddCommentParams {
  postId: number;
  content: string;
  parentId?: number;
}

export class PostApi {
  private httpClient: HttpClient = HttpClient.getInstance();

  async getPostList(pageNum: number, pageSize: number, tag?: string, keyword?: string, sortBy?: string): Promise<ApiResponse<PageData<PostVO>>> {
    const params: PostListParams = {
      pageNum: pageNum,
      pageSize: pageSize,
      tag: tag,
      keyword: keyword,
      sortBy: sortBy
    };
    return this.httpClient.get<PageData<PostVO>>('/api/post/list', params);
  }

  async getPostDetail(id: number): Promise<ApiResponse<PostVO>> {
    return this.httpClient.get<PostVO>('/api/post/detail/' + id.toString());
  }

  async getHotPosts(limit: number): Promise<ApiResponse<PostVO[]>> {
    const hotParams: HotPostsParams = { limit: limit };
    return this.httpClient.get<PostVO[]>('/api/post/hot', hotParams);
  }

  async createPost(post: Object): Promise<ApiResponse<void>> {
    return this.httpClient.post<void>('/api/post/create', post);
  }

  async updatePost(post: Object): Promise<ApiResponse<void>> {
    return this.httpClient.put<void>('/api/post/update', post);
  }

  async deletePost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.del<void>('/api/post/delete/' + id.toString());
  }

  async likePost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.post<void>('/api/post/like/' + id.toString());
  }

  async unlikePost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.del<void>('/api/post/like/' + id.toString());
  }

  async checkLiked(id: number): Promise<ApiResponse<boolean>> {
    return this.httpClient.get<boolean>('/api/post/like/check/' + id.toString());
  }

  async favoritePost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.post<void>('/api/post/favorite/' + id.toString());
  }

  async unfavoritePost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.del<void>('/api/post/favorite/' + id.toString());
  }

  async checkFavorited(id: number): Promise<ApiResponse<boolean>> {
    return this.httpClient.get<boolean>('/api/post/favorite/check/' + id.toString());
  }

  async getUserPosts(pageNum: number, pageSize: number): Promise<ApiResponse<PageData<PostVO>>> {
    const userParams: UserPostsParams = { pageNum: pageNum, pageSize: pageSize };
    return this.httpClient.get<PageData<PostVO>>('/api/post/user', userParams);
  }

  async recommendPost(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.put<void>('/api/post/recommend/' + id.toString());
  }

  async getComments(postId: number): Promise<ApiResponse<PostCommentVO[]>> {
    return this.httpClient.get<PostCommentVO[]>('/api/post/comment/list/' + postId.toString());
  }

  async addComment(postId: number, content: string, parentId?: number): Promise<ApiResponse<void>> {
    const params: AddCommentParams = {
      postId: postId,
      content: content,
      parentId: (parentId && parentId > 0) ? parentId : undefined
    };
    return this.httpClient.postWithParams<void>('/api/post/comment/add', params);
  }

  async deleteComment(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.del<void>('/api/post/comment/delete/' + id.toString());
  }

  async likeComment(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.post<void>('/api/post/comment/like/' + id.toString());
  }

  async unlikeComment(id: number): Promise<ApiResponse<void>> {
    return this.httpClient.del<void>('/api/post/comment/like/' + id.toString());
  }

  async checkCommentLiked(id: number): Promise<ApiResponse<boolean>> {
    return this.httpClient.get<boolean>('/api/post/comment/like/check/' + id.toString());
  }
}
