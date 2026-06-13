import { ResourceItem, CategoryItem, BannerItem, adaptResource, adaptCategory, adaptBanner } from '../models/ResourceModel';
import { ResourceApi } from '../api/ResourceApi';
import { BannerApi } from '../api/BannerApi';
import { FavoriteApi } from '../api/FavoriteApi';
import categoriesData from '../data/categories.json';
import resourcesData from '../data/resources.json';
import bannersData from '../data/banners.json';

export interface TagCount {
  tag: string;
  count: number;
}

export interface ResourcePageResult {
  items: ResourceItem[];
  total: number;
}

export class ResourceService {
  private static instance: ResourceService;
  private localCategories: CategoryItem[] = [];
  private localResources: ResourceItem[] = [];
  private localBanners: BannerItem[] = [];
  private resourceApi: ResourceApi = new ResourceApi();
  private bannerApi: BannerApi = new BannerApi();
  private favoriteApi: FavoriteApi = new FavoriteApi();

  // 缓存：API 获取的数据
  private cachedCategories: CategoryItem[] | null = null;
  private cachedBanners: BannerItem[] | null = null;

  private constructor() {
    this.localCategories = categoriesData as CategoryItem[];
    this.localResources = resourcesData as ResourceItem[];
    this.localBanners = bannersData as BannerItem[];
  }

  static getInstance(): ResourceService {
    if (!ResourceService.instance) {
      ResourceService.instance = new ResourceService();
    }
    return ResourceService.instance;
  }

  // ===== 本地离线方法（JSON fallback） =====
  getLocalCategories(): CategoryItem[] { return this.localCategories; }
  getLocalBanners(): BannerItem[] { return this.localBanners; }
  getLocalResources(): ResourceItem[] { return this.localResources; }
  getLocalResourcesByCategory(categoryId: number): ResourceItem[] {
    return this.localResources.filter(r => r.categoryId === categoryId);
  }
  getLocalResourceById(id: number): ResourceItem | undefined {
    return this.localResources.find(r => r.id === id);
  }
  getLocalCategoryById(id: number): CategoryItem | undefined {
    return this.localCategories.find(c => c.id === id);
  }
  searchLocalResources(keyword: string): ResourceItem[] {
    if (!keyword.trim()) return [];
    const kw = keyword.toLowerCase().trim();
    return this.localResources.filter(r =>
      r.title.toLowerCase().includes(kw) ||
      r.tags.some(t => t.toLowerCase().includes(kw)) ||
      r.description.toLowerCase().includes(kw) ||
      r.author.toLowerCase().includes(kw)
    );
  }
  getLocalAllTags(): TagCount[] {
    const tagMap: Record<string, number> = {};
    for (const r of this.localResources) {
      for (const t of r.tags) {
        if (t === '学科' || t === '考研' || t === '期末速成') continue;
        tagMap[t] = (tagMap[t] || 0) + 1;
      }
    }
    const result: TagCount[] = [];
    const keys: string[] = Object.keys(tagMap);
    for (let i = 0; i < keys.length; i++) {
      const tag = keys[i];
      const count = tagMap[tag];
      result.push({ tag: tag, count: count });
    }
    result.sort((a: TagCount, b: TagCount) => b.count - a.count);
    return result.slice(0, 30);
  }

  // ===== 异步 API 方法（在线优先，离线降级） =====

  async fetchCategories(): Promise<CategoryItem[]> {
    try {
      const resp = await this.resourceApi.getCategories();
      if (resp.code === 200 && resp.data) {
        const mapped: CategoryItem[] = [];
        for (let i = 0; i < resp.data.length; i++) {
          mapped.push(adaptCategory(resp.data[i]));
        }
        this.cachedCategories = mapped;
        return this.cachedCategories as CategoryItem[];
      }
    } catch (e) {
      console.error('fetchCategories failed, fallback to local: ' + JSON.stringify(e));
    }
    return this.cachedCategories || this.localCategories;
  }

  async fetchBanners(): Promise<BannerItem[]> {
    try {
      const resp = await this.bannerApi.getList();
      if (resp.code === 200 && resp.data) {
        const mapped: BannerItem[] = [];
        for (let i = 0; i < resp.data.length; i++) {
          mapped.push(adaptBanner(resp.data[i]));
        }
        this.cachedBanners = mapped;
        return this.cachedBanners as BannerItem[];
      }
    } catch (e) {
      console.error('fetchBanners failed, fallback to local: ' + JSON.stringify(e));
    }
    return this.cachedBanners || this.localBanners;
  }

  async fetchResourcesByCategory(categoryId: number, pageNum: number, pageSize: number): Promise<ResourcePageResult> {
    try {
      const resp = await this.resourceApi.getList({ pageNum: pageNum, pageSize: pageSize, categoryId: categoryId, status: 1 });
      if (resp.code === 200 && resp.data) {
        const items: ResourceItem[] = [];
        for (let i = 0; i < resp.data.records.length; i++) {
          items.push(adaptResource(resp.data.records[i]));
        }
        const result: ResourcePageResult = { items: items, total: resp.data.total };
        return result;
      }
    } catch (e) {
      console.error('fetchResourcesByCategory failed, fallback to local: ' + JSON.stringify(e));
    }
    // fallback 到本地
    const localItems = this.getLocalResourcesByCategory(categoryId);
    const fallbackResult: ResourcePageResult = { items: localItems, total: localItems.length };
    return fallbackResult;
  }

  async fetchResourceDetail(id: number): Promise<ResourceItem | null> {
    try {
      const resp = await this.resourceApi.getDetail(id);
      if (resp.code === 200 && resp.data) {
        return adaptResource(resp.data);
      }
    } catch (e) {
      console.error('fetchResourceDetail failed, fallback to local: ' + JSON.stringify(e));
    }
    return this.getLocalResourceById(id) || null;
  }

  async fetchHotResources(count: number): Promise<ResourceItem[]> {
    try {
      const resp = await this.resourceApi.getHot(count);
      if (resp.code === 200 && resp.data) {
        const items: ResourceItem[] = [];
        for (let i = 0; i < resp.data.length; i++) {
          items.push(adaptResource(resp.data[i]));
        }
        return items;
      }
    } catch (e) {
      console.error('fetchHotResources failed, fallback to local: ' + JSON.stringify(e));
    }
    return this.localResources.slice(0, count);
  }

  async searchResources(keyword: string): Promise<ResourceItem[]> {
    if (!keyword.trim()) return [];
    try {
      const resp = await this.resourceApi.search(keyword);
      if (resp.code === 200 && resp.data) {
        const items: ResourceItem[] = [];
        for (let i = 0; i < resp.data.length; i++) {
          items.push(adaptResource(resp.data[i]));
        }
        return items;
      }
    } catch (e) {
      console.error('searchResources failed, fallback to local: ' + JSON.stringify(e));
    }
    return this.searchLocalResources(keyword);
  }

  async likeResource(id: number): Promise<boolean> {
    try {
      const resp = await this.resourceApi.like(id);
      return resp.code === 200;
    } catch (e) {
      return false;
    }
  }

  async unlikeResource(id: number): Promise<boolean> {
    try {
      const resp = await this.resourceApi.unlike(id);
      return resp.code === 200;
    } catch (e) {
      return false;
    }
  }

  async addFavorite(id: number): Promise<boolean> {
    try {
      const resp = await this.favoriteApi.add(id);
      return resp.code === 200;
    } catch (e) {
      return false;
    }
  }

  async removeFavorite(id: number): Promise<boolean> {
    try {
      const resp = await this.favoriteApi.remove(id);
      return resp.code === 200;
    } catch (e) {
      return false;
    }
  }

  async checkFavorite(id: number): Promise<boolean> {
    try {
      const resp = await this.favoriteApi.check(id);
      if (resp.code === 200 && resp.data) {
        return resp.data.isFavorite;
      }
    } catch (e) {
      console.error('checkFavorite failed: ' + JSON.stringify(e));
    }
    return false;
  }
}
