import { PostApi, PostVO } from '../api/PostApi';
import { PageData } from '@neushare/common';
import { Post, toPost } from '../models/PostModel';
import promptAction from '@ohos.promptAction';

interface PostListResult {
  posts: Post[];
  total: number;
}

interface CreatePostBody {
  title: string;
  content: string;
  tags: string;
  imageUrls: string;
  files: string;
}

export class CommunityService {
  private static instance: CommunityService;
  private postApi: PostApi = new PostApi();

  private constructor() {}

  static getInstance(): CommunityService {
    if (!CommunityService.instance) {
      CommunityService.instance = new CommunityService();
    }
    return CommunityService.instance;
  }



  async getPostList(pageNum: number = 1, pageSize: number = 20, tag?: string, keyword?: string, sortBy?: string): Promise<PostListResult> {
    try {
      const res = await this.postApi.getPostList(pageNum, pageSize, tag, keyword, sortBy);
      if (res.code === 200 && res.data) {
        const pageData = res.data as PageData<PostVO>;
        const posts = (pageData.records || []).map(vo => toPost(vo));
        const result: PostListResult = { posts: posts, total: pageData.total };
        return result;
      }
      const emptyResult: PostListResult = { posts: [], total: 0 };
      return emptyResult;
    } catch (e) {
      console.error('CommunityService.getPostList failed: ' + JSON.stringify(e));
      const emptyResult: PostListResult = { posts: [], total: 0 };
      return emptyResult;
    }
  }

  async getPostDetail(id: number): Promise<Post | null> {
    try {
      const res = await this.postApi.getPostDetail(id);
      if (res.code === 200 && res.data) {
        const post = toPost(res.data as PostVO);
        // Check like/favorite status
        try {
          const likeRes = await this.postApi.checkLiked(id);
          post.isLiked = likeRes.code === 200 && likeRes.data === true;
        } catch { post.isLiked = false; }
        try {
          const favRes = await this.postApi.checkFavorited(id);
          post.isFavorited = favRes.code === 200 && favRes.data === true;
        } catch { post.isFavorited = false; }
        return post;
      }
      return null;
    } catch (e) {
      console.error('CommunityService.getPostDetail failed: ' + JSON.stringify(e));
      return null;
    }
  }

  async createPost(title: string, content: string, tags: string[], imageUrls: string[], files: Object[]): Promise<boolean> {
    try {
      const body: CreatePostBody = {
        title: title,
        content: content,
        tags: JSON.stringify(tags),
        imageUrls: JSON.stringify(imageUrls),
        files: JSON.stringify(files)
      };
      const res = await this.postApi.createPost(body);
      if (res.code === 200) {
        return true;
      }
      promptAction.showToast({ message: '发布失败，请重试', duration: 2000 });
      return false;
    } catch (e) {
      console.error('CommunityService.createPost failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '发布失败，请检查网络', duration: 2000 });
      return false;
    }
  }

  async likePost(postId: number, isLiked: boolean): Promise<boolean> {
    try {
      const res = isLiked ? await this.postApi.unlikePost(postId) : await this.postApi.likePost(postId);
      if (res.code === 200) {
        return true;
      }
      // 幂等处理：后端返回"已点赞"/"未点赞"说明状态已一致，视为成功
      const msg = res.message || '';
      if (msg.includes('已点赞') || msg.includes('未点赞')) {
        return true;
      }
      promptAction.showToast({ message: isLiked ? '取消点赞失败，请重试' : '点赞失败，请重试', duration: 2000 });
      return false;
    } catch (e) {
      console.error('CommunityService.likePost failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '操作失败，请检查网络', duration: 2000 });
      return false;
    }
  }

  async favoritePost(postId: number, isFavorited: boolean): Promise<boolean> {
    try {
      const res = isFavorited ? await this.postApi.unfavoritePost(postId) : await this.postApi.favoritePost(postId);
      if (res.code === 200) {
        return true;
      }
      // 幂等处理：后端返回"已收藏"/"未收藏"说明状态已一致，视为成功
      const msg = res.message || '';
      if (msg.includes('已收藏') || msg.includes('未收藏')) {
        return true;
      }
      promptAction.showToast({ message: isFavorited ? '取消收藏失败，请重试' : '收藏失败，请重试', duration: 2000 });
      return false;
    } catch (e) {
      console.error('CommunityService.favoritePost failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '操作失败，请检查网络', duration: 2000 });
      return false;
    }
  }

  async recommendPost(postId: number): Promise<boolean> {
    try {
      const res = await this.postApi.recommendPost(postId);
      if (res.code === 200) {
        return true;
      }
      promptAction.showToast({ message: '推荐失败，请重试', duration: 2000 });
      return false;
    } catch (e) {
      console.error('CommunityService.recommendPost failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '推荐失败，请检查网络', duration: 2000 });
      return false;
    }
  }

  async deletePost(postId: number): Promise<boolean> {
    try {
      const res = await this.postApi.deletePost(postId);
      if (res.code === 200) {
        return true;
      }
      promptAction.showToast({ message: '删除失败，请重试', duration: 2000 });
      return false;
    } catch (e) {
      console.error('CommunityService.deletePost failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '删除失败，请检查网络', duration: 2000 });
      return false;
    }
  }

  async getHotPosts(count: number = 3): Promise<Post[]> {
    try {
      const res = await this.postApi.getHotPosts(count);
      if (res.code === 200 && res.data) {
        return (res.data as PostVO[]).map(vo => toPost(vo));
      }
      return [];
    } catch (e) {
      console.error('CommunityService.getHotPosts failed: ' + JSON.stringify(e));
      return [];
    }
  }

  // Backward compatibility: getAllPosts returns first page
  async getAllPosts(): Promise<Post[]> {
    const result = await this.getPostList(1, 50);
    return result.posts;
  }

  // Backward compatibility: getRecommendedPost
  async getRecommendedPost(): Promise<Post | null> {
    const result = await this.getPostList(1, 20);
    return result.posts.find(p => p.isRecommended) || null;
  }
}
