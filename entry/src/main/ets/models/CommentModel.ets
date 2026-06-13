export interface CommentItem {
  id: number;
  resourceId: number;
  userId: number;
  username: string;
  avatarUrl: string;
  content: string;
  parentId: number;
  children: CommentItem[];
  createTime: string;
}
