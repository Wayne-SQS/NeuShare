import { ColorTokens, FontScale, Radii } from '@neushare/common';

@Component
export struct GradePill {
  @Prop label: string = '';
  @Prop isSelected: boolean = false;
  @State pressed: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(FontScale.SUBTITLE)
      .fontWeight(this.isSelected ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.isSelected ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
      .padding({ left: 22, right: 22, top: 12, bottom: 12 })
      .backgroundColor(this.isSelected ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(Radii.HUGE)
      .shadow(this.isSelected ? {
        radius: 8,
        color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'),
        offsetX: 0,
        offsetY: 4
      } : { radius: 0, color: ColorTokens.TRANSPARENT, offsetX: 0, offsetY: 0 })
      .scale({ x: this.pressed ? 0.95 : 1, y: this.pressed ? 0.95 : 1 })
      .animation({ curve: Curve.EaseOut, duration: 200 })
      .onClick(() => { this.onTap(); })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressed = true;
        } else {
          this.pressed = false;
        }
      })
  }
}
