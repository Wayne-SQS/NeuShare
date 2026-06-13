export interface PostFile {
  name: string;
  uri: string;
  type: string;
  size: number;
}

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
  imageUrls: string[];
  files: PostFile[];
}

export function hotness(post: Post): number {
  return post.likes * 3 + post.commentsCount * 2 + post.favorites * 1;
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

export function fileIcon(type: string): string {
  const t = type.toLowerCase();
  if (t.includes('zip') || t.includes('rar') || t.includes('7z')) return '📦';
  if (t.includes('png') || t.includes('jpg') || t.includes('jpeg') || t.includes('svg') || t.includes('gif') || t.includes('webp')) return '🖼️';
  if (t.includes('md') || t.includes('txt') || t.includes('markdown')) return '📝';
  if (t.includes('doc')) return '📃';
  if (t.includes('xls')) return '📊';
  if (t.includes('ppt')) return '📽️';
  if (t.includes('pdf')) return '📕';
  if (t.includes('mp4') || t.includes('avi') || t.includes('mov')) return '🎬';
  if (t.includes('mp3') || t.includes('wav') || t.includes('flac')) return '🎵';
  return '📎';
}
