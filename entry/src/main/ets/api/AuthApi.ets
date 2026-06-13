import { HttpClient, ApiResponse } from '@neushare/common';

export interface LoginData {
  token: string;
  user: UserInfo;
}

export interface UserInfo {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
  college: string;
  grade: number;
  role: string;
}

interface LoginBody {
  username: string;
  password: string;
}

interface RegisterBody {
  username: string;
  password: string;
  nickname: string;
  college: string;
  grade: number;
}

interface UpdateInfoBody {
  nickname: string;
  avatarUrl: string;
  college: string;
  grade: number;
}

interface PasswordChangeParams {
  oldPassword: string;
  newPassword: string;
}

export class AuthApi {
  private http: HttpClient = HttpClient.getInstance();

  async login(username: string, password: string): Promise<ApiResponse<LoginData>> {
    const body: LoginBody = { username: username, password: password };
    return this.http.post<LoginData>('/api/auth/login', body);
  }

  async register(username: string, password: string, nickname: string, college: string, grade: number): Promise<ApiResponse<null>> {
    const body: RegisterBody = { username: username, password: password, nickname: nickname, college: college, grade: grade };
    return this.http.post<null>('/api/auth/register', body);
  }

  async getInfo(): Promise<ApiResponse<UserInfo>> {
    return this.http.get<UserInfo>('/api/auth/info');
  }

  async updateInfo(nickname: string, avatarUrl: string, college: string, grade: number): Promise<ApiResponse<null>> {
    const body: UpdateInfoBody = { nickname: nickname, avatarUrl: avatarUrl, college: college, grade: grade };
    return this.http.put<null>('/api/auth/info', body);
  }

  async changePassword(oldPassword: string, newPassword: string): Promise<ApiResponse<null>> {
    const params: PasswordChangeParams = { oldPassword: oldPassword, newPassword: newPassword };
    return this.http.putWithParams<null>('/api/auth/password', params);
  }
}
