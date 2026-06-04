import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

const STORE_NAME = 'neushare_preferences';
const FAVORITES_KEY = 'favorite_ids';
const HISTORY_KEY = 'history_ids';
const MAX_HISTORY = 20;

export class FavoriteService {
  private static instance: FavoriteService;
  private prefs: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService();
    }
    return FavoriteService.instance;
  }

  async init(context: Context): Promise<void> {
    this.prefs = await preferences.getPreferences(context, STORE_NAME);
  }

  async getFavoriteIds(): Promise<Set<number>> {
    if (!this.prefs) return new Set();
    const str = await this.prefs.get(FAVORITES_KEY, '[]') as string;
    return new Set(JSON.parse(str));
  }

  async toggleFavorite(id: number): Promise<boolean> {
    if (!this.prefs) return false;
    const ids = await this.getFavoriteIds();
    if (ids.has(id)) {
      ids.delete(id);
    } else {
      ids.add(id);
    }
    await this.prefs.put(FAVORITES_KEY, JSON.stringify(Array.from(ids)));
    await this.prefs.flush();
    return ids.has(id);
  }

  async isFavorite(id: number): Promise<boolean> {
    const ids = await this.getFavoriteIds();
    return ids.has(id);
  }

  async getHistory(): Promise<number[]> {
    if (!this.prefs) return [];
    const str = await this.prefs.get(HISTORY_KEY, '[]') as string;
    return JSON.parse(str);
  }

  async addHistory(id: number): Promise<void> {
    if (!this.prefs) return;
    let history = await this.getHistory();
    history = history.filter(h => h !== id);
    history.unshift(id);
    if (history.length > MAX_HISTORY) {
      history = history.slice(0, MAX_HISTORY);
    }
    await this.prefs.put(HISTORY_KEY, JSON.stringify(history));
    await this.prefs.flush();
  }
}
