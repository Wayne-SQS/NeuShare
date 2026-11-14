// ============================================================
// PageHeader — 单独使用的页面标题区
// 供需要自定义滚动 / 分栏布局、无法整体套 PageScaffold 的页面复用
// ============================================================
import router from '@ohos.router';
import { ColorTokens } from '../theme/ColorTokens';
import { ControlSize, FontScale, Spacing } from '../theme/DesignTokens';

@Component
export struct PageHeader {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = true;
  @Prop showDivider: boolean = true;
  /** 右侧操作文案（如「+ 上传」），为空则不显示 */
  @Prop actionText: string = '';
  onBack: () => void = () => { router.back(); };
  onAction: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Text('返回')
          .fontSize(FontScale.BODY_SM)
          .fontColor(ColorTokens.textSecondary(this.isDarkMode))
          .width(ControlSize.TOUCH)
          .height(ControlSize.TOUCH)
          .textAlign(TextAlign.Start)
          .onClick(() => { this.onBack(); })
      }
      Column() {
        Text(this.title)
          .fontSize(FontScale.HERO)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(FontScale.CAPTION)
            .fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: Spacing.XXS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.actionText) {
        Text(this.actionText)
          .fontSize(FontScale.BODY_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.primary(this.isDarkMode))
          .height(ControlSize.TOUCH)
          .padding({ left: Spacing.SM, right: Spacing.XS })
          .textAlign(TextAlign.End)
          .onClick(() => { this.onAction(); })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: ControlSize.HEADER })
    .padding({ left: this.showBack ? Spacing.SM : Spacing.PAGE, right: Spacing.PAGE })
    .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .border(this.showDivider ? { width: { bottom: 1 }, color: ColorTokens.border(this.isDarkMode) } : { width: 0 })
  }
}
