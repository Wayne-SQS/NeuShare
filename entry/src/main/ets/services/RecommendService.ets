import { PreferencesStore } from '@neushare/common';
import { Context } from '@ohos.abilityAccessCtrl';
import { ResourceService } from './ResourceService';
import { FavoriteService } from './FavoriteService';
import { ResourceItem } from '../models/ResourceModel';

export interface ScoredResource {
  resource: ResourceItem;
  score: number;
}

/**
 * 端侧推荐引擎
 * 基于用户收藏和浏览历史，使用内容相似度推荐
 * 零网络依赖，完全本地计算
 */
export class RecommendService {
  private static instance: RecommendService;
  private store: PreferencesStore = new PreferencesStore('neushare_recommend');
  private resourceService: ResourceService = ResourceService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();

  private constructor() {}

  static getInstance(): RecommendService {
    if (!RecommendService.instance) {
      RecommendService.instance = new RecommendService();
    }
    return RecommendService.instance;
  }

  async init(context: Context): Promise<void> {
    await this.store.init(context);
  }

  /**
   * 获取推荐资源列表
   * 算法：基于收藏和浏览历史的标签偏好 + 分类偏好，计算每个资源的推荐分数
   */
  async getRecommendations(count: number): Promise<ResourceItem[]> {
    const allResources = this.resourceService.getLocalResources();
    if (allResources.length === 0) return [];

    // 获取用户行为数据
    const favoriteIds = await this.favoriteService.getFavoriteIds();
    const historyIds = await this.favoriteService.getHistory();

    // 如果用户没有任何行为数据，返回热门资源
    if (favoriteIds.size === 0 && historyIds.length === 0) {
      return this.getPopularResources(allResources, count);
    }

    // 计算标签偏好权重
    const tagWeights: Record<string, number> = {};
    const categoryWeights: Record<number, number> = {};

    // 收藏的资源权重更高
    favoriteIds.forEach(id => {
      const r = this.resourceService.getLocalResourceById(id);
      if (r) {
        this.addWeights(tagWeights, categoryWeights, r, 3.0);
      }
    });

    // 浏览历史权重较低
    for (let i = 0; i < historyIds.length; i++) {
      const r = this.resourceService.getLocalResourceById(historyIds[i]);
      if (r) {
        // 越近的浏览记录权重越高
        const recency = 1.0 - (i / Math.max(historyIds.length, 1)) * 0.5;
        this.addWeights(tagWeights, categoryWeights, r, recency);
      }
    }

    // 计算每个资源的推荐分数
    const scored: ScoredResource[] = [];
    const interactedIds = new Set<number>();
    favoriteIds.forEach(id => interactedIds.add(id));
    historyIds.forEach(id => interactedIds.add(id));

    for (let i = 0; i < allResources.length; i++) {
      const r = allResources[i];
      // 排除已交互过的资源
      if (interactedIds.has(r.id)) continue;

      let score = 0;

      // 分类匹配
      if (categoryWeights[r.categoryId]) {
        score += categoryWeights[r.categoryId] * 2.0;
      }

      // 标签匹配
      if (r.tags && r.tags.length > 0) {
        for (let j = 0; j < r.tags.length; j++) {
          if (tagWeights[r.tags[j]]) {
            score += tagWeights[r.tags[j]] * 1.5;
          }
        }
      }

      // 热度加分（点赞数和浏览数）
      score += (r.likeCount || 0) * 0.1;
      score += (r.viewCount || 0) * 0.01;

      // 随机扰动，避免推荐列表完全固定
      score += Math.random() * 0.5;

      const entry: ScoredResource = { resource: r, score: score };
      scored.push(entry);
    }

    // 按分数降序排序
    scored.sort((a: ScoredResource, b: ScoredResource) => b.score - a.score);

    const result: ResourceItem[] = [];
    const limit = Math.min(count, scored.length);
    for (let i = 0; i < limit; i++) {
      result.push(scored[i].resource);
    }
    return result;
  }

  /**
   * 获取"猜你喜欢"推荐（首页用）
   */
  async getGuessYouLike(count: number): Promise<ResourceItem[]> {
    return this.getRecommendations(count);
  }

  /**
   * 获取相似资源推荐（详情页用）
   */
  getSimilarResources(resourceId: number, count: number): ResourceItem[] {
    const target = this.resourceService.getLocalResourceById(resourceId);
    if (!target) return [];

    const allResources = this.resourceService.getLocalResources();
    const scored: ScoredResource[] = [];

    for (let i = 0; i < allResources.length; i++) {
      const r = allResources[i];
      if (r.id === resourceId) continue;

      let score = 0;

      // 同分类加分
      if (r.categoryId === target.categoryId) {
        score += 3.0;
      }

      // 标签重叠加分
      if (target.tags && r.tags && target.tags.length > 0 && r.tags.length > 0) {
        for (let j = 0; j < target.tags.length; j++) {
          if (r.tags.includes(target.tags[j])) {
            score += 2.0;
          }
        }
      }

      // 同类型加分
      if (r.type === target.type) {
        score += 1.0;
      }

      // 热度加分
      score += (r.likeCount || 0) * 0.05;

      const entry: ScoredResource = { resource: r, score: score };
      scored.push(entry);
    }

    scored.sort((a: ScoredResource, b: ScoredResource) => b.score - a.score);
    return scored.slice(0, count).map(s => s.resource);
  }

  // ===== 私有方法 =====

  private addWeights(tagWeights: Record<string, number>, categoryWeights: Record<number, number>,
    resource: ResourceItem, weight: number): void {
    // 标签权重
    if (resource.tags && resource.tags.length > 0) {
      for (let i = 0; i < resource.tags.length; i++) {
        const tag = resource.tags[i];
        tagWeights[tag] = (tagWeights[tag] || 0) + weight;
      }
    }
    // 分类权重
    categoryWeights[resource.categoryId] = (categoryWeights[resource.categoryId] || 0) + weight;
  }

  private getPopularResources(resources: ResourceItem[], count: number): ResourceItem[] {
    // 按点赞数排序作为热门推荐
    const sorted = [...resources].sort((a, b) => (b.likeCount || 0) - (a.likeCount || 0));
    return sorted.slice(0, count);
  }
}
