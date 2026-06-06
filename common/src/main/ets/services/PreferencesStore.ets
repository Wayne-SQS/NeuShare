import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

export class PreferencesStore {
  private prefs: preferences.Preferences | null = null;
  private storeName: string;

  constructor(storeName: string) {
    this.storeName = storeName;
  }

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, this.storeName);
    } catch (e) {
      console.error('PreferencesStore init failed: ' + JSON.stringify(e));
    }
  }

  async get<T extends preferences.ValueType>(key: string, defaultValue: T): Promise<T> {
    if (!this.prefs) return defaultValue;
    try {
      const result: preferences.ValueType = await this.prefs.get(key, defaultValue);
      return result as T;
    } catch (e) {
      console.error('PreferencesStore get failed: ' + JSON.stringify(e));
      return defaultValue;
    }
  }

  async set<T extends preferences.ValueType>(key: string, value: T): Promise<void> {
    if (!this.prefs) return;
    try {
      await this.prefs.put(key, value as preferences.ValueType);
      await this.prefs.flush();
    } catch (e) {
      console.error('PreferencesStore set failed: ' + JSON.stringify(e));
    }
  }
}
