import { HttpClient, ApiResponse, PageData } from '@neushare/common';

// ── 通知 VO（对齐后端 NotificationVO） ──────────
export interface NotificationItem {
  id: number;
  userId: number;
  fromUserId: number;
  type: string;          // audit / comment / follow / like / favorite
  title: string;
  content: string;
  resourceId: number;
  isRead: number;        // 0=未读, 1=已读
  createTime: string;
  // 触发者信息
  fromUsername: string;
  fromNickname: string;
  fromAvatarUrl: string;
}

// ── 分页数据（统一用 common/PageData） ──────────
export type NotificationPageData = PageData<NotificationItem>;

export class NotificationApi {
  private http: HttpClient = HttpClient.getInstance();

  // ── 获取通知列表（分页 + 可选类型筛选） ──────
  async getList(pageNum: number = 1, pageSize: number = 10, type?: string): Promise<ApiResponse<NotificationPageData>> {
    const params: Record<string, Object> = {
      pageNum: pageNum,
      pageSize: pageSize
    };
    if (type) {
      params['type'] = type;
    }
    return this.http.get<NotificationPageData>('/api/notification/list', params);
  }

  // ── 获取未读数量 ────────────────────────────
  async getUnreadCount(): Promise<ApiResponse<number>> {
    return this.http.get<number>('/api/notification/unread');
  }

  // ── 标记单条已读 ────────────────────────────
  async markAsRead(id: number): Promise<ApiResponse<null>> {
    return this.http.put<null>('/api/notification/read/' + id);
  }

  // ── 标记全部已读 ────────────────────────────
  async markAllAsRead(): Promise<ApiResponse<null>> {
    return this.http.put<null>('/api/notification/read-all');
  }

  // ── 删除单条通知 ────────────────────────────
  async deleteNotification(id: number): Promise<ApiResponse<null>> {
    return this.http.del<null>('/api/notification/delete/' + id);
  }
}
