// ============================================================
// StateView — 数据页面三态视图（加载中 / 空数据 / 失败重试）
// 空数据与失败态复用 EmptyState，保证全站文案与间距一致
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';
import { ControlSize, FontScale, Spacing } from '../theme/DesignTokens';
import { EmptyState } from './EmptyState';

export enum ViewState {
  LOADING = 'loading',
  EMPTY = 'empty',
  ERROR = 'error'
}

@Component
export struct StateView {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop state: string = ViewState.LOADING;
  @Prop message: string = '';
  @Prop hint: string = '';
  @Prop retryText: string = '重试';
  onRetry: () => void = () => {};

  build() {
    Column() {
      if (this.state === ViewState.LOADING) {
        LoadingProgress()
          .width(ControlSize.TOUCH)
          .height(ControlSize.TOUCH)
          .color(ColorTokens.primary(this.isDarkMode))
        Text(this.message || '加载中')
          .fontSize(FontScale.CAPTION)
          .fontColor(ColorTokens.textHint(this.isDarkMode))
          .margin({ top: Spacing.MD })
      } else {
        EmptyState({
          icon: '',
          message: this.message,
          hint: this.hint,
          actionText: this.state === ViewState.ERROR ? this.retryText : '',
          onAction: this.onRetry
        })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 160 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
