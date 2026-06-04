// ============================================================
// EmptyState - 空状态组件
// 统一的无数据占位展示
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct EmptyState {
  @Prop icon: string = '📭';
  @Prop message: string = '';
  @Prop hint: string = '';

  build() {
    Column() {
      Text(this.icon)
        .fontSize(48)
        .margin({ top: 60 })
      Text(this.message)
        .fontSize(16)
        .fontColor(ColorTokens.TEXT_HINT)
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
