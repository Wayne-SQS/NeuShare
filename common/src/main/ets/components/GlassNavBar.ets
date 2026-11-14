// ============================================================
// GlassNavBar — 毛玻璃导航栏组件
// 亮色模式：半透明淡蓝白 + 模糊 / 深色模式：深灰 + 极细底边框
// 性能分级：滚动时关闭 blur / 低端设备降级为纯色
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';
import { FontScale, ControlSize, Spacing } from '../theme/DesignTokens';
import { BlurPerformance } from '../utils/BlurPerformance';

@Component
export struct GlassNavBar {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  // isScrolling 通过 @StorageProp 订阅以触发重渲染（只读订阅即可）
  @StorageProp('isScrolling') private _isScrolling: boolean = false;
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop onBack: () => void = () => {};
  @Prop blurRadius: number = 40;

  private get isDark(): boolean {
    return this.isDarkMode;
  }

  private get effectiveBlur(): number {
    return BlurPerformance.effectiveBlur(this.isDark);
  }

  private get navBg(): string {
    // 模糊关闭时使用不透明降级色
    if (this.effectiveBlur === 0 && !this.isDark) {
      return ColorTokens.GLASS_LIGHT; // 不透明淡蓝白
    }
    return this.isDark ? ColorTokens.withAlpha(ColorTokens.GLASS_DARK, 'CC') : ColorTokens.withAlpha(ColorTokens.GLASS_LIGHT, 'CC');
  }

  private get navBorderColor(): string {
    return this.isDark ? ColorTokens.DIVIDER_DARK : ColorTokens.withAlpha(ColorTokens.PRIMARY_LIGHT, '20');
  }

  build() {
    Row() {
      if (this.showBack) {
        Text('返回')
          .fontSize(FontScale.BODY_SM)
          .fontColor(ColorTokens.textPrimary(this.isDark))
          .padding({ right: Spacing.MD })
          .onClick(() => this.onBack())
      }

      Text(this.title)
        .fontSize(FontScale.SECTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDark))
        .layoutWeight(1)

      Blank()
    }
    .width('100%')
    .height(ControlSize.HEADER)
    .padding({ left: Spacing.PAGE, right: Spacing.PAGE })
    .backgroundColor(this.navBg)
    .backdropBlur(this.effectiveBlur)
    .border({ width: { bottom: 0.5 }, color: this.navBorderColor })
    .animation({ curve: Curve.EaseOut, duration: 150 })
  }
}
