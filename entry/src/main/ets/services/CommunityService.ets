import { Context } from '@ohos.abilityAccessCtrl';
import { PreferencesStore } from '@neushare/common';
import { Post, hotness } from '../models/PostModel';

const POSTS_KEY = 'community_posts';

export class CommunityService {
  private static instance: CommunityService;
  private store: PreferencesStore = new PreferencesStore('neushare_preferences');

  private constructor() {}

  static getInstance(): CommunityService {
    if (!CommunityService.instance) {
      CommunityService.instance = new CommunityService();
    }
    return CommunityService.instance;
  }

  async init(context: Context): Promise<void> {
    await this.store.init(context);
  }

  async getAllPosts(): Promise<Post[]> {
    const str = await this.store.get<string>(POSTS_KEY, '[]');
    try { return JSON.parse(str) as Post[]; } catch { return []; }
  }

  private async savePosts(posts: Post[]): Promise<void> {
    await this.store.set(POSTS_KEY, JSON.stringify(posts));
  }

  async createPost(post: Post): Promise<boolean> {
    const posts = await this.getAllPosts();
    posts.unshift(post);
    await this.savePosts(posts);
    return true;
  }

  async recommendPost(postId: string): Promise<boolean> {
    const posts = await this.getAllPosts();
    let found = false;
    for (let i = 0; i < posts.length; i++) {
      if (posts[i].id === postId) { posts[i].recommended = true; found = true; }
      else { posts[i].recommended = false; }
    }
    if (!found) return false;
    await this.savePosts(posts);
    return true;
  }

  async getRecommendedPost(): Promise<Post | null> {
    const posts = await this.getAllPosts();
    return posts.find(p => p.recommended) || null;
  }

  async likePost(postId: string): Promise<Post | null> {
    const posts = await this.getAllPosts();
    const idx = posts.findIndex(p => p.id === postId);
    if (idx < 0) return null;
    posts[idx].likes += 1;
    await this.savePosts(posts);
    return posts[idx];
  }

  async favoritePost(postId: string): Promise<Post | null> {
    const posts = await this.getAllPosts();
    const idx = posts.findIndex(p => p.id === postId);
    if (idx < 0) return null;
    posts[idx].favorites += 1;
    await this.savePosts(posts);
    return posts[idx];
  }

  async getHotPosts(count: number = 3): Promise<Post[]> {
    const posts = await this.getAllPosts();
    return [...posts].sort((a, b) => hotness(b) - hotness(a)).slice(0, count);
  }
}
