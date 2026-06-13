import { ColorTokens } from '@neushare/common';

// ===== 前端展示模型（页面使用） =====

export interface ResourceItem {
  id: number
  title: string
  categoryId: number
  cover: string
  source: string
  tags: string[]
  description: string
  url: string
  type: string
  author: string
  publishDate: string
  rating: number
  likeCount: number
  viewCount: number
  uploadAvatar: string
}

export interface CategoryItem {
  id: number
  title: string
  icon: string
  color: string
  description: string
}

export interface BannerItem {
  id: number
  title: string
  subtitle: string
  emoji: string
  gradientStart: string
  gradientEnd: string
  imageUrl: string
  linkType: string
  linkValue: string
}

// ===== 后端 VO 模型（API 返回） =====

export interface ResourceVO {
  id: number
  title: string
  categoryId: number
  type: string
  contentUrl: string
  coverUrl: string
  description: string
  source: string
  tags: string
  uploadNickname: string
  uploadUsername: string
  uploadAvatar: string
  likeCount: number
  viewCount: number
  status: number
  createTime: string
}

export interface CategoryVO {
  id: number
  name: string
  icon: string
  sort: number
  createTime: string
}

export interface BannerVO {
  id: number
  title: string
  imageUrl: string
  linkUrl: string
  sort: number
  status: number
  createTime: string
}

// ===== 适配函数：后端 VO → 前端展示模型 =====

export function adaptResource(vo: ResourceVO): ResourceItem {
  let tags: string[] = [];
  if (vo.tags) {
    if (typeof vo.tags === 'string') {
      try { tags = JSON.parse(vo.tags); } catch { tags = vo.tags.split(','); }
    } else if (Array.isArray(vo.tags)) {
      const rawArr: Object[] = vo.tags as Object[];
      const strArr: string[] = [];
      for (let j = 0; j < rawArr.length; j++) {
        strArr.push(String(rawArr[j]));
      }
      tags = strArr;
    }
  }
  return {
    id: vo.id,
    title: vo.title,
    categoryId: vo.categoryId,
    cover: vo.coverUrl || '',
    source: vo.source || '',
    tags: tags,
    description: vo.description || '',
    url: vo.contentUrl || '',
    type: vo.type || 'tutorial',
    author: vo.uploadNickname || vo.uploadUsername || '',
    publishDate: vo.createTime || '',
    rating: vo.likeCount > 0 ? Math.min(vo.likeCount / 10, 5.0) : 0,
    likeCount: vo.likeCount || 0,
    viewCount: vo.viewCount || 0,
    uploadAvatar: vo.uploadAvatar || ''
  };
}

export function adaptCategory(vo: CategoryVO): CategoryItem {
  const colors: string[] = ColorTokens.BANNER_COLORS;
  const icons: string[] = ['📚', '💻', '🎬', '📝', '🔬'];
  return {
    id: vo.id,
    title: vo.name,
    icon: vo.icon || icons[vo.id % icons.length],
    color: colors[vo.id % colors.length],
    description: ''
  };
}

export function adaptBanner(vo: BannerVO): BannerItem {
  const emojis: string[] = ['📚', '🎓', '💡', '🔬', '📖'];
  const colors: string[] = ColorTokens.BANNER_COLORS;
  // 判断 linkUrl 是分类 ID（纯数字）还是外部 URL
  const isCategoryId = /^\d+$/.test(vo.linkUrl || '');
  return {
    id: vo.id,
    title: vo.title,
    subtitle: '',
    emoji: emojis[vo.id % emojis.length],
    gradientStart: colors[vo.id % colors.length],
    gradientEnd: colors[(vo.id + 1) % colors.length],
    imageUrl: vo.imageUrl || '',
    linkType: isCategoryId ? 'category' : 'external',
    linkValue: vo.linkUrl || ''
  };
}
