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

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /**
   * 处理 401 未授权响应：清除 token 并跳转登录页
   * 使用 Promise 锁防止并发 401 多次跳转
   */
  private static handling401Promise: Promise<void> | null = null;

  private async handleUnauthorized(): Promise<void> {
    if (HttpClient.handling401Promise) {
      // 已有 401 处理进行中，等待其完成即可
      await HttpClient.handling401Promise;
      return;
    }
    HttpClient.handling401Promise = (async () => {
      await this.authStore.logout();
      try {
        router.replaceUrl({ url: 'pages/LoginPage' });
      } catch (e) {
        console.error('handleUnauthorized redirect failed: ' + JSON.stringify(e));
      }
    })();
    try {
      await HttpClient.handling401Promise;
    } finally {
      HttpClient.handling401Promise = null;
    }
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
      throw new Error('HTTP GET failed: ' + path + ' — ' + JSON.stringify(e));
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
      throw new Error('HTTP POST failed: ' + path + ' — ' + JSON.stringify(e));
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
      throw new Error('HTTP POST failed: ' + path + ' — ' + JSON.stringify(e));
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
      throw new Error('HTTP PUT failed: ' + path + ' — ' + JSON.stringify(e));
    }
  }

  /**
   * POST multipart/form-data 上传（文件 + 字段）
   * 对应后端 @RequestParam 字段 + MultipartFile file
   */
  async postFormData<T>(path: string, fields: Record<string, string>, fileUri?: string, fileKey: string = 'file'): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const token = await this.authStore.getToken();
      const headers: Record<string, string> = {};
      // 注意：不要手动设置 Content-Type: multipart/form-data
      // ArkTS HTTP 库在传 multiFormDataList 时会自动加上正确的 Content-Type + boundary
      if (token) {
        headers['Authorization'] = 'Bearer ' + token;
      }

      const formData: Array<http.MultiFormData> = [];
      // 文本字段
      const fieldKeys = Object.keys(fields);
      for (let i = 0; i < fieldKeys.length; i++) {
        formData.push({ name: fieldKeys[i], data: fields[fieldKeys[i]], contentType: '' });
      }
      // 文件字段（可选）
      if (fileUri && fileUri.length > 0) {
        formData.push({ name: fileKey, filePath: fileUri, contentType: '' });
      }

      const resp = await httpRequest.request(BASE_URL + path, {
        method: http.RequestMethod.POST,
        header: headers,
        multiFormDataList: formData,
        connectTimeout: 30000,
        readTimeout: 30000
      });
      const body = JSON.parse(resp.result as string) as ApiResponse<T>;
      httpRequest.destroy();
      return this.checkAuth(body);
    } catch (e) {
      httpRequest.destroy();
      throw new Error('HTTP POST FormData failed: ' + path + ' — ' + JSON.stringify(e));
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
      throw new Error('HTTP PUT failed: ' + path + ' — ' + JSON.stringify(e));
    }
  }

  /**
   * DELETE 请求，参数通过 URL 查询字符串传递（后端 @RequestParam）
   */
  async deleteWithParams<T>(path: string, params: Object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const headers = await this.getHeaders(true);
      const url = BASE_URL + path + this.buildQueryString(params);
      const resp = await httpRequest.request(url, {
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
      throw new Error('HTTP DELETE failed: ' + path + ' — ' + JSON.stringify(e));
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
      throw new Error('HTTP DELETE failed: ' + path + ' — ' + JSON.stringify(e));
    }
  }
}
