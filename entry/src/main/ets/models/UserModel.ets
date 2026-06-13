export interface UserInfo {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
  college: string;
  grade: number;
  role: string;
}

export interface UserProfile {
  id: number;
  username: string;
  nickname: string;
  avatarUrl: string;
  college: string;
  grade: number;
  resourceCount: number;
  followerCount: number;
  followingCount: number;
  createTime: string;
}
