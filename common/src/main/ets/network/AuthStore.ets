import { PreferencesStore } from '../services/PreferencesStore';
import { Context } from '@ohos.abilityAccessCtrl';
import http from '@ohos.net.http';

const TOKEN_KEY = 'auth_token';
const USER_KEY = 'auth_user';
const BASE_URL: string = 'http://10.0.2.2:8080';

export class AuthStore {
  private static instance: AuthStore;
  private store: PreferencesStore = new PreferencesStore('neushare_auth');
  private tokenValue: string = '';
  private userValue: Record<string, Object> | null = null;

  private constructor() {}

  static getInstance(): AuthStore {
    if (!AuthStore.instance) {
      AuthStore.instance = new AuthStore();
    }
    return AuthStore.instance;
  }

  async init(context: Context): Promise<void> {
    await this.store.init(context);
    this.tokenValue = await this.store.get('auth_token', '') as string;
    const userStr = await this.store.get('auth_user', '') as string;
    if (userStr) {
      try {
        this.userValue = JSON.parse(userStr) as Record<string, Object>;
      } catch (e) {
        this.userValue = null;
      }
    }
  }

  async getToken(): Promise<string> {
    if (!this.tokenValue) {
      this.tokenValue = await this.store.get(TOKEN_KEY, '') as string;
    }
    return this.tokenValue;
  }

  async setToken(token: string): Promise<void> {
    this.tokenValue = token;
    await this.store.set(TOKEN_KEY, token);
  }

  async getUser(): Promise<Record<string, Object> | null> {
    if (!this.userValue) {
      const userStr = await this.store.get(USER_KEY, '') as string;
      if (userStr) {
        try {
          this.userValue = JSON.parse(userStr) as Record<string, Object>;
        } catch (e) {
          this.userValue = null;
        }
      }
    }
    return this.userValue;
  }

  async setUser(user: Record<string, Object>): Promise<void> {
    this.userValue = user;
    await this.store.set(USER_KEY, JSON.stringify(user));
  }

  async isLoggedIn(): Promise<boolean> {
    const token = await this.getToken();
    return token.length > 0;
  }

  async saveLogin(token: string, user: Object): Promise<void> {
    await this.setToken(token);
    await this.store.set(USER_KEY, JSON.stringify(user));
    this.userValue = user as Record<string, Object>;
  }

  async logout(): Promise<void> {
    this.tokenValue = '';
    this.userValue = null;
    await this.store.set(TOKEN_KEY, '');
    await this.store.set(USER_KEY, '');
  }

  /**
   * 验证当前 Token 是否有效（调用 /api/auth/info）
   * 返回 true 表示有效，false 表示无效或过期
   */
  async validateToken(): Promise<boolean> {
    const token = await this.getToken();
    if (!token) return false;
    try {
      const httpRequest = http.createHttp();
      const resp = await httpRequest.request(BASE_URL + '/api/auth/info', {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token
        },
        connectTimeout: 5000,
        readTimeout: 5000
      });
      httpRequest.destroy();
      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      const code = body['code'] as number;
      if (code === 200) {
        // Token 有效，更新用户信息
        if (body['data']) {
          await this.setUser(body['data'] as Record<string, Object>);
        }
        return true;
      }
      // 401 或其他错误码，Token 无效
      await this.logout();
      return false;
    } catch (e) {
      // 网络错误，无法验证，保留 token（可能离线）
      console.error('validateToken network error: ' + JSON.stringify(e));
      return true;
    }
  }
}
