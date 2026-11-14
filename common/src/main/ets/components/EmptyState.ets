// ============================================================
// EmptyState - 空状态 / 失败状态占位组件
// 统一的无数据展示（中性图形 + 标题 + 说明 + 可选操作）
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';
import { ControlSize, FontScale, Radii, Spacing } from '../theme/DesignTokens';

@Component
export struct EmptyState {
  /** 可选图标文本；为空时显示中性占位图形（不使用 emoji） */
  @Prop icon: string = '';
  @Prop message: string = '';
  @Prop hint: string = '';
  @Prop actionText: string = '';
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State breathScale: number = 1;

  onAction: () => void = () => {};

  private breathTimerId: number = -1;

  aboutToAppear(): void {
    if (!this.icon) {
      return;
    }
    // 呼吸动画：1 → 1.1 → 1 循环（仅图标模式下启用）
    this.breathTimerId = setInterval(() => {
      animateTo({ duration: 1500, curve: Curve.EaseInOut }, () => {
        this.breathScale = this.breathScale === 1 ? 1.1 : 1;
      });
    }, 1600);
  }

  aboutToDisappear(): void {
    if (this.breathTimerId !== -1) {
      clearInterval(this.breathTimerId);
      this.breathTimerId = -1;
    }
  }

  build() {
    Column() {
      if (this.icon) {
        Text(this.icon)
          .fontSize(FontScale.ICON_XXL)
          .scale({ x: this.breathScale, y: this.breathScale })
          .animation({ duration: 1500, curve: Curve.EaseInOut, iterations: -1 })
      } else {
        Column()
          .width(ControlSize.ICON_LG)
          .height(ControlSize.ICON_LG)
          .borderRadius(Radii.CARD)
          .backgroundColor(ColorTokens.surfaceSecondary(this.isDarkMode))
          .border({ width: 1, color: ColorTokens.border(this.isDarkMode) })
          .scale({ x: this.breathScale, y: this.breathScale })
          .animation({ duration: 1500, curve: Curve.EaseInOut, iterations: -1 })
      }

      Text(this.message)
        .fontSize(FontScale.SUBTITLE)
        .fontColor(ColorTokens.textSecondary(this.isDarkMode))
        .margin({ top: Spacing.MD })
        .textAlign(TextAlign.Center)

      if (this.hint) {
        Text(this.hint)
          .fontSize(FontScale.CAPTION)
          .fontColor(ColorTokens.textHint(this.isDarkMode))
          .margin({ top: Spacing.XS })
          .textAlign(TextAlign.Center)
      }

      if (this.actionText) {
        Button(this.actionText)
          .fontSize(FontScale.BODY_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
          .height(ControlSize.BUTTON)
          .padding({ left: Spacing.XXL, right: Spacing.XXL })
          .backgroundColor(ColorTokens.primary(this.isDarkMode))
          .borderRadius(Radii.BUTTON)
          .margin({ top: Spacing.XL })
          .onClick(() => { this.onAction(); })
      }
    }
    .width('100%')
    .padding({ left: Spacing.PAGE, right: Spacing.PAGE })
    .justifyContent(FlexAlign.Center)
  }
}
