// ============================================================
// SectionHeader — 区块标题（18/600），可带右侧操作文案
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';
import { FontScale, Spacing } from '../theme/DesignTokens';

@Component
export struct SectionHeader {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop actionText: string = '';
  onAction: () => void = () => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize(FontScale.SECTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (this.actionText) {
        Text(this.actionText)
          .fontSize(FontScale.CAPTION)
          .fontColor(ColorTokens.textHint(this.isDarkMode))
          .onClick(() => { this.onAction(); })
      }
    }
    .width('100%')
    .padding({ top: Spacing.XL, bottom: Spacing.SM })
  }
}
