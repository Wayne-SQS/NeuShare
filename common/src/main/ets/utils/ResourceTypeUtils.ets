// ============================================================
// ResourceTypeUtils - 资源类型工具类
// 统一提供 typeEmoji 和 typeColor 逻辑
// 消除 ResourceCard 和 DetailPage 中的重复代码
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';

export class ResourceTypeUtils {
  /** 根据资源类型返回对应 emoji 图标 */
  static typeEmoji(type: string): string {
    switch (type) {
      case 'video': return '🎬';
      case 'book': return '📖';
      case 'software': return '💻';
      case 'tutorial': return '📝';
      default: return '📄';
    }
  }

  /** 根据资源类型返回对应颜色 */
  static typeColor(type: string): string {
    return ColorTokens.forType(type);
  }
}
