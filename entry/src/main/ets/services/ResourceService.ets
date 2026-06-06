import { ResourceItem, CategoryItem, BannerItem } from '../models/ResourceModel';
import categoriesData from '../data/categories.json';
import resourcesData from '../data/resources.json';
import bannersData from '../data/banners.json';

export interface TagCount {
  tag: string;
  count: number;
}

export class ResourceService {
  private static instance: ResourceService;
  private categories: CategoryItem[] = [];
  private resources: ResourceItem[] = [];
  private banners: BannerItem[] = [];

  private constructor() {
    this.categories = categoriesData as CategoryItem[];
    this.resources = resourcesData as ResourceItem[];
    this.banners = bannersData as BannerItem[];
  }

  static getInstance(): ResourceService {
    if (!ResourceService.instance) {
      ResourceService.instance = new ResourceService();
    }
    return ResourceService.instance;
  }

  getCategories(): CategoryItem[] { return this.categories; }
  getBanners(): BannerItem[] { return this.banners; }
  getAllResources(): ResourceItem[] { return this.resources; }

  getResourcesByCategory(categoryId: number): ResourceItem[] {
    return this.resources.filter(r => r.categoryId === categoryId);
  }

  getResourceById(id: number): ResourceItem | undefined {
    return this.resources.find(r => r.id === id);
  }

  getCategoryById(id: number): CategoryItem | undefined {
    return this.categories.find(c => c.id === id);
  }

  searchResources(keyword: string): ResourceItem[] {
    if (!keyword.trim()) return [];
    const kw = keyword.toLowerCase().trim();
    return this.resources.filter(r =>
      r.title.toLowerCase().includes(kw) ||
      r.tags.some(t => t.toLowerCase().includes(kw)) ||
      r.description.toLowerCase().includes(kw) ||
      r.author.toLowerCase().includes(kw)
    );
  }

  getAllTags(): TagCount[] {
    const tagMap: Record<string, number> = {};
    for (const r of this.resources) {
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
}
