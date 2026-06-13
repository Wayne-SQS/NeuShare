// ============================================================
// TypeTag — 资源类型标签组件
// 亮色模式：多彩胶囊 / 深色模式：字母缩写细边框
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';

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
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.TEXT_SECONDARY_DARK)
        .letterSpacing(1)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(6)
        .border({ width: 0.5, color: ColorTokens.DIVIDER_DARK })
        .backgroundColor(ColorTokens.BG_CARD_DARK)
    } else {
      // ── 亮色模式：多彩胶囊 ──────────────────
      Text(this.getTypeLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.TEXT_WHITE)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
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
