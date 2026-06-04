import { ResourceItem, CategoryItem, BannerItem } from '../models/ResourceModel';
import categoriesData from '../data/categories.json';
import resourcesData from '../data/resources.json';
import bannersData from '../data/banners.json';

export class DataService {
  private static instance: DataService;
  private categories: CategoryItem[] = [];
  private resources: ResourceItem[] = [];
  private banners: BannerItem[] = [];

  private constructor() {
    this.categories = categoriesData as CategoryItem[];
    this.resources = resourcesData as ResourceItem[];
    this.banners = bannersData as BannerItem[];
  }

  static getInstance(): DataService {
    if (!DataService.instance) {
      DataService.instance = new DataService();
    }
    return DataService.instance;
  }

  getCategories(): CategoryItem[] {
    return this.categories;
  }

  getBanners(): BannerItem[] {
    return this.banners;
  }

  getAllResources(): ResourceItem[] {
    return this.resources;
  }

  getResourcesByCategory(categoryId: number): ResourceItem[] {
    return this.resources.filter(r => r.categoryId === categoryId);
  }

  getResourceById(id: number): ResourceItem | undefined {
    return this.resources.find(r => r.id === id);
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

  getCategoryById(id: number): CategoryItem | undefined {
    return this.categories.find(c => c.id === id);
  }

  getRelatedResources(resource: ResourceItem, count: number = 5): ResourceItem[] {
    return this.resources
      .filter(r => r.categoryId === resource.categoryId && r.id !== resource.id)
      .slice(0, count);
  }

  getPopularResources(count: number = 5): ResourceItem[] {
    return [...this.resources]
      .sort((a, b) => b.rating - a.rating)
      .slice(0, count);
  }
}
