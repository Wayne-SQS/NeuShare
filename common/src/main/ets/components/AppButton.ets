// ============================================================
// AppButton — 统一操作按钮（默认 40 高）
// primary：品牌色实心；secondary：浅底描边
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';
import { ControlSize, FontScale, Radii, Spacing } from '../theme/DesignTokens';

@Component
export struct AppButton {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop label: string = '';
  @Prop primary: boolean = true;
  @Prop enabled: boolean = true;
  @Prop height: number = ControlSize.BUTTON;
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .width('100%')
      .height(this.height)
      .fontSize(FontScale.BODY)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.primary ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
      .backgroundColor(this.primary ? ColorTokens.primary(this.isDarkMode) : ColorTokens.surfaceSecondary(this.isDarkMode))
      .borderRadius(Radii.BUTTON)
      .border(this.primary ? { width: 0 } : { width: 1, color: ColorTokens.border(this.isDarkMode) })
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .enabled(this.enabled)
      .opacity(this.enabled ? 1 : 0.5)
      .onClick(() => {
        if (this.enabled) {
          this.onTap();
        }
      })
  }
}
