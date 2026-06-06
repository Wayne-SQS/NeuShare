import { Context } from '@ohos.abilityAccessCtrl';
import { PreferencesStore } from '@neushare/common';

const FAVORITES_KEY = 'favorite_ids';
const HISTORY_KEY = 'history_ids';
const MAX_HISTORY = 20;

export class FavoriteService {
  private static instance: FavoriteService;
  private store: PreferencesStore = new PreferencesStore('neushare_preferences');

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

  async getFavoriteIds(): Promise<Set<number>> {
    const str = await this.store.get<string>(FAVORITES_KEY, '[]');
    try {
      return new Set(JSON.parse(str));
    } catch {
      return new Set();
    }
  }

  async toggleFavorite(id: number): Promise<boolean> {
    const ids = await this.getFavoriteIds();
    if (ids.has(id)) { ids.delete(id); } else { ids.add(id); }
    await this.store.set(FAVORITES_KEY, JSON.stringify(Array.from(ids)));
    return ids.has(id);
  }

  async isFavorite(id: number): Promise<boolean> {
    const ids = await this.getFavoriteIds();
    return ids.has(id);
  }

  async getHistory(): Promise<number[]> {
    const str = await this.store.get<string>(HISTORY_KEY, '[]');
    try { return JSON.parse(str); } catch { return []; }
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
}
