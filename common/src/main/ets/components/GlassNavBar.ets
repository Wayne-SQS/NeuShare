// ============================================================
// GlassNavBar — 毛玻璃导航栏组件
// 亮色模式：半透明淡蓝白 + 模糊 / 深色模式：深灰 + 极细底边框
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct GlassNavBar {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop onBack: () => void = () => {};
  @Prop blurRadius: number = 40;

  private get isDark(): boolean {
    return this.isDarkMode;
  }

  private get navBg(): string {
    return this.isDark ? '#0E0E10CC' : '#F4F7FFCC';
  }

  private get navBorderColor(): string {
    return this.isDark ? ColorTokens.DIVIDER_DARK : '#4A6BFF20';
  }

  build() {
    Row() {
      if (this.showBack) {
        Text('←')
          .fontSize(20)
          .fontColor(ColorTokens.textPrimary(this.isDark))
          .padding({ right: 12 })
          .onClick(() => this.onBack())
      }

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDark))
        .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.navBg)
    .backdropBlur(this.blurRadius)
    .border({ width: { bottom: 0.5 }, color: this.navBorderColor })
  }
}
