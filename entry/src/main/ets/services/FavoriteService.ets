import { Context } from '@ohos.abilityAccessCtrl';
import { PreferencesStore, AuthStore } from '@neushare/common';
import { FavoriteApi } from '../api/FavoriteApi';
import { ResourceItem, adaptResource } from '../models/ResourceModel';

const FAVORITES_KEY = 'favorite_ids';
const HISTORY_KEY = 'history_ids';
const MAX_HISTORY = 20;

export interface FavoriteResourceResult {
  items: ResourceItem[];
  total: number;
}

export class FavoriteService {
  private static instance: FavoriteService;
  private store: PreferencesStore = new PreferencesStore('neushare_preferences');
  private favoriteApi: FavoriteApi = new FavoriteApi();
  private authStore: AuthStore = AuthStore.getInstance();

  private constructor() {}

  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService();
    }
    return FavoriteService.instance;
  }

  async init(context: Context): Promise<void> {
    await this.store.init(context);
  }

  private async isLoggedIn(): Promise<boolean> {
    return await this.authStore.isLoggedIn();
  }

  // ===== 本地存储方法（离线 fallback） =====

  async getLocalFavoriteIds(): Promise<Set<number>> {
    const str = await this.store.get<string>(FAVORITES_KEY, '[]');
    try {
      return new Set(JSON.parse(str) as number[]);
    } catch {
      return new Set();
    }
  }

  private async saveLocalFavoriteIds(ids: Set<number>): Promise<void> {
    await this.store.set(FAVORITES_KEY, JSON.stringify(Array.from(ids)));
  }

  async getFavoriteIds(): Promise<Set<number>> {
    if (await this.isLoggedIn()) {
      try {
        const resp = await this.favoriteApi.getList(1, 1000);
        if (resp.code === 200 && resp.data) {
          const ids = new Set<number>();
          const records = resp.data.records;
          for (let i = 0; i < records.length; i++) {
            ids.add(records[i].resourceId);
          }
          // 同步到本地缓存
          await this.saveLocalFavoriteIds(ids);
          return ids;
        }
      } catch (e) {
        console.error('getFavoriteIds from API failed, fallback to local: ' + JSON.stringify(e));
      }
    }
    return this.getLocalFavoriteIds();
  }

  async toggleFavorite(id: number): Promise<boolean> {
    const isFav = await this.isFavorite(id);
    if (await this.isLoggedIn()) {
      try {
        if (isFav) {
          const resp = await this.favoriteApi.remove(id);
          if (resp.code === 200) {
            // 更新本地缓存
            const ids = await this.getLocalFavoriteIds();
            ids.delete(id);
            await this.saveLocalFavoriteIds(ids);
            return false;
          }
        } else {
          const resp = await this.favoriteApi.add(id);
          if (resp.code === 200) {
            // 更新本地缓存
            const ids = await this.getLocalFavoriteIds();
            ids.add(id);
            await this.saveLocalFavoriteIds(ids);
            return true;
          }
        }
      } catch (e) {
        console.error('toggleFavorite API failed, fallback to local: ' + JSON.stringify(e));
      }
    }
    // 离线或 API 失败，本地操作
    const ids = await this.getLocalFavoriteIds();
    if (ids.has(id)) { ids.delete(id); } else { ids.add(id); }
    await this.saveLocalFavoriteIds(ids);
    return ids.has(id);
  }

  async isFavorite(id: number): Promise<boolean> {
    if (await this.isLoggedIn()) {
      try {
        const resp = await this.favoriteApi.check(id);
        if (resp.code === 200 && resp.data) {
          return resp.data.isFavorite;
        }
      } catch (e) {
        console.error('isFavorite API failed, fallback to local: ' + JSON.stringify(e));
      }
    }
    const ids = await this.getLocalFavoriteIds();
    return ids.has(id);
  }

  async getFavoriteResources(pageNum: number, pageSize: number): Promise<FavoriteResourceResult> {
    if (await this.isLoggedIn()) {
      try {
        const resp = await this.favoriteApi.getList(pageNum, pageSize);
        if (resp.code === 200 && resp.data) {
          const items: ResourceItem[] = [];
          const records = resp.data.records;
          for (let i = 0; i < records.length; i++) {
            if (records[i].resource) {
              items.push(adaptResource(records[i].resource));
            }
          }
          const result: FavoriteResourceResult = { items: items, total: resp.data.total };
          return result;
        }
      } catch (e) {
        console.error('getFavoriteResources API failed, fallback to local: ' + JSON.stringify(e));
      }
    }
    // fallback: 本地 ID 匹配
    const ids = await this.getLocalFavoriteIds();
    const fallbackResult: FavoriteResourceResult = { items: [], total: ids.size };
    return fallbackResult;
  }

  // ===== 浏览历史（纯本地） =====

  async getHistory(): Promise<number[]> {
    const str = await this.store.get<string>(HISTORY_KEY, '[]');
    try { return JSON.parse(str) as number[]; } catch { return []; }
  }

  async addHistory(id: number): Promise<void> {
    let history = await this.getHistory();
    history = history.filter(h => h !== id);
    history.unshift(id);
    if (history.length > MAX_HISTORY) {
      history = history.slice(0, MAX_HISTORY);
    }
    await this.store.set(HISTORY_KEY, JSON.stringify(history));
  }

  // ===== 登录后本地收藏合并到云端 =====

  /**
   * 将本地离线收藏合并到云端。
   * 逐个调用 FavoriteApi.add()，成功后更新本地缓存。
   * 登录成功后调用此方法。
   */
  async mergeLocalFavoritesToCloud(): Promise<void> {
    if (!(await this.isLoggedIn())) return;
    const localIds = await this.getLocalFavoriteIds();
    if (localIds.size === 0) return;
    // 获取云端已有收藏
    let cloudIds = new Set<number>();
    try {
      const resp = await this.favoriteApi.getList(1, 1000);
      if (resp.code === 200 && resp.data) {
        const records = resp.data.records;
        for (let i = 0; i < records.length; i++) {
          cloudIds.add(records[i].resourceId);
        }
      }
    } catch (e) {
      console.error('mergeLocalFavoritesToCloud: get cloud list failed: ' + JSON.stringify(e));
      return;
    }
    // 只合并云端没有的
    const toMerge: number[] = [];
    localIds.forEach(id => {
      if (!cloudIds.has(id)) { toMerge.push(id); }
    });
    for (let i = 0; i < toMerge.length; i++) {
      try {
        await this.favoriteApi.add(toMerge[i]);
        cloudIds.add(toMerge[i]);
      } catch (e) {
        console.error('mergeLocalFavoritesToCloud: add failed for id ' + toMerge[i]);
      }
    }
    // 更新本地缓存为合并后的完整集合
    await this.saveLocalFavoriteIds(cloudIds);
  }
}
