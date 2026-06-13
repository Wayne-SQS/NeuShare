import http from '@ohos.net.http';
import { AuthStore } from './AuthStore';
import router from '@ohos.router';

const BASE_URL: string = 'http://10.0.2.2:8080';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export class HttpClient {
  private static instance: HttpClient;
  private authStore: AuthStore = AuthStore.getInstance();
  private isHandling401: boolean = false;

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /**
   * 处理 401 未授权响应：清除 token 并跳转登录页
   */
  private async handleUnauthorized(): Promise<void> {
    if (this.isHandling401) return;
    this.isHandling401 = true;
    await this.authStore.logout();
    try {
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (e) {
      console.error('handleUnauthorized redirect failed: ' + JSON.stringify(e));
    }
    this.isHandling401 = false;
  }

  /**
   * 检查响应是否为 401，如果是则自动处理
   */
  private async checkAuth<T>(body: ApiResponse<T>): Promise<ApiResponse<T>> {
    if (body.code === 401) {
      await this.handleUnauthorized();
    }
    return body;
  }

  async setBaseUrl(url: string): Promise<void> {
    // baseUrl can be reconfigured at runtime
  }

  private async getHeaders(isJson: boolean): Promise<Record<string, string>> {
    const headers: Record<string, string> = {};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    const token = await this.authStore.getToken();
    if (token) {
      headers['Authorization'] = 'Bearer ' + token;
    }
    return headers;
  }

  /**
   * 将 params 对象拼接到 URL 查询字符串
   */
  private buildQueryString(params: Object): string {
    const parts: string[] = [];
    const obj: Record<string, Object> = params as Record<string, Object>;
    const keys: string[] = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      const value: Object = obj[key];
      if (value !== undefined && value !== null && value !== '') {
        parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(String(value)));
      }
    }
    return parts.length > 0 ? '?' + parts.join('&') : '';
  }

  async get<T>(path: string, params?: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const url = BASE_URL + path + (params ? this.buildQueryString(params) : '');
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP GET failed: ' + path);
    }
  }

  async post<T>(path: string, data?: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const resp = await httpRequest.request(BASE_URL + path, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP POST failed: ' + path);
    }
  }

  /**
   * POST 请求，参数通过 URL 查询字符串传递（后端 @RequestParam）
   */
  async postWithParams<T>(path: string, params: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const url = BASE_URL + path + this.buildQueryString(params);
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP POST failed: ' + path);
    }
  }

  /**
   * PUT 请求，参数通过 URL 查询字符串传递（后端 @RequestParam）
   */
  async putWithParams<T>(path: string, params: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const url = BASE_URL + path + this.buildQueryString(params);
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.PUT,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP PUT failed: ' + path);
    }
  }

  async put<T>(path: string, data?: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const resp = await httpRequest.request(BASE_URL + path, {
        method: http.RequestMethod.PUT,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP PUT failed: ' + path);
    }
  }

  async del<T>(path: string): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const resp = await httpRequest.request(BASE_URL + path, {
        method: http.RequestMethod.DELETE,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 5000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP DELETE failed: ' + path);
    }
  }
}
