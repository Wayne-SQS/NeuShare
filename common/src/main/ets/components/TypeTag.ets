// ============================================================
// TypeTag — 资源类型标签组件
// 亮色模式：多彩胶囊 / 深色模式：字母缩写细边框
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';
import { FontScale, Radii, Spacing } from '../theme/DesignTokens';

@Component
export struct TypeTag {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop type: string = 'default'; // video | book | software | tutorial | default

  private get isDark(): boolean {
    return this.isDarkMode;
  }

  build() {
    if (this.isDark) {
      // ── 深色模式：字母缩写 + 细边框 ─────────
      Text(ColorTokens.typeAbbreviation(this.type))
        .fontSize(FontScale.TINY)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.TEXT_SECONDARY_DARK)
        .letterSpacing(1)
        .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
        .borderRadius(Radii.SM)
        .border({ width: 0.5, color: ColorTokens.DIVIDER_DARK })
        .backgroundColor(ColorTokens.BG_CARD_DARK)
    } else {
      // ── 亮色模式：多彩胶囊 ──────────────────
      Text(this.getTypeLabel())
        .fontSize(FontScale.MICRO)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.TEXT_WHITE)
        .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.XS, bottom: Spacing.XS })
        .borderRadius(Radii.CARD)
        .backgroundColor(ColorTokens.typeColor(this.type, false))
    }
  }

  private getTypeLabel(): string {
    switch (this.type) {
      case 'video': return '视频';
      case 'book': return '书籍';
      case 'software': return '软件';
      case 'tutorial': return '笔记';
      default: return '其他';
    }
  }
}
