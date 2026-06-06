export interface Post {
  id: string;
  title: string;
  content: string;
  author: string;
  tags: string[];
  createdAt: string;
  recommended: boolean;
  likes: number;
  favorites: number;
  commentsCount: number;
}

export function hotness(post: Post): number {
  return post.likes * 3 + post.commentsCount * 2 + post.favorites * 1;
}
