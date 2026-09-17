import { PostVO, PostCommentVO } from '../api/PostApi';

export interface PostFile {
  name: string;
  uri: string;
  type: string;
  size: number;
}

/** Backend JSON 中每个 file 对象的原始结构（字段可能叫 url 或 uri） */
interface RawFileItem {
  name?: string;
  uri?: string;
  url?: string;
  type?: string;
  size?: number;
}

export interface Post {
  id: number;
  userId: number;
  title: string;
  content: string;
  authorNickname: string;
  authorAvatarUrl: string;
  authorCollege: string;
  tags: string[];
  createTime: string;
  isRecommended: boolean;
  likeCount: number;
  favoriteCount: number;
  commentCount: number;
  viewCount: number;
  imageUrls: string[];
  files: PostFile[];
  status: number;
  isLiked: boolean;
  isFavorited: boolean;
}

export interface PostComment {
  id: number;
  postId: number;
  userId: number;
  content: string;
  parentId: number;
  deleted: number;
  createTime: string;
  nickname: string;
  avatarUrl: string;
  children: PostComment[];
}

export function hotness(post: Post): number {
  return post.likeCount * 3 + post.commentCount * 2 + post.favoriteCount * 1;
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

// Convert backend PostVO to local Post model
export function toPost(vo: PostVO, isLiked: boolean = false, isFavorited: boolean = false): Post {
  let tags: string[] = [];
  try { tags = JSON.parse(vo.tags || '[]') as string[]; } catch { tags = []; }

  let imageUrls: string[] = [];
  try { imageUrls = JSON.parse(vo.imageUrls || '[]') as string[]; } catch { imageUrls = []; }

  // 兼容后端返回的 url 字段（映射为 uri），并从文件名推导 type
  let rawFiles: RawFileItem[] = [];
  try { rawFiles = JSON.parse(vo.files || '[]') as RawFileItem[]; } catch { rawFiles = []; }
  const files: PostFile[] = rawFiles.map((f: RawFileItem): PostFile => {
    const name = f.name || '';
    return {
      name: name,
      uri: f.url || f.uri || '',
      type: f.type || extractFileType(name),
      size: f.size || 0
    };
  });

  return {
    id: vo.id,
    userId: vo.userId,
    title: vo.title,
    content: vo.content,
    authorNickname: vo.authorNickname || '匿名',
    authorAvatarUrl: vo.authorAvatarUrl || '',
    authorCollege: vo.authorCollege || '',
    tags: tags,
    createTime: vo.createTime || '',
    isRecommended: vo.isRecommended === 1,
    likeCount: vo.likeCount || 0,
    favoriteCount: vo.favoriteCount || 0,
    commentCount: vo.commentCount || 0,
    viewCount: vo.viewCount || 0,
    imageUrls: imageUrls,
    files: files,
    status: vo.status,
    isLiked: isLiked,
    isFavorited: isFavorited
  };
}

/** 从文件名提取扩展名作为文件类型 */
function extractFileType(filename: string): string {
  const dotIndex = filename.lastIndexOf('.');
  return dotIndex >= 0 ? filename.substring(dotIndex) : '';
}

// Convert backend PostCommentVO to local PostComment model
export function toComment(vo: PostCommentVO): PostComment {
  let children: PostComment[] = [];
  if (vo.children && vo.children.length > 0) {
    children = vo.children.map(c => toComment(c));
  }
  return {
    id: vo.id,
    postId: vo.postId,
    userId: vo.userId,
    content: vo.content,
    parentId: vo.parentId,
    deleted: vo.deleted,
    createTime: vo.createTime,
    nickname: vo.nickname || '匿名',
    avatarUrl: vo.avatarUrl || '',
    children: children
  };
}
