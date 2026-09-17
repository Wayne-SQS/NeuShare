// ============================================================
// EmptyState - 空状态组件
// 统一的无数据占位展示（含呼吸动画）
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct EmptyState {
  @Prop icon: string = '📭';
  @Prop message: string = '';
  @Prop hint: string = '';
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State breathScale: number = 1;

  private breathTimerId: number = -1;

  aboutToAppear(): void {
    // 呼吸动画：1 → 1.1 → 1 循环
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
      Text(this.icon)
        .fontSize(48)
        .scale({ x: this.breathScale, y: this.breathScale })
        .animation({ duration: 1500, curve: Curve.EaseInOut, iterations: -1 })
        .margin({ top: 60 })
      Text(this.message)
        .fontSize(16)
        .fontColor(ColorTokens.textHint(this.isDarkMode))
        .margin({ top: 12 })
      if (this.hint) {
        Text(this.hint)
          .fontSize(13)
          .fontColor(ColorTokens.TEXT_DISABLED)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
