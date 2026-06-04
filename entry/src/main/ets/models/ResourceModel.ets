export interface ResourceItem {
  id: number
  title: string
  categoryId: number
  cover: string
  source: string
  tags: string[]
  description: string
  url: string
  type: 'video' | 'book' | 'software' | 'tutorial'
  author: string
  publishDate: string
  rating: number
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
