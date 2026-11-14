// ============================================================
// PageScaffold — 统一下层页面骨架
// 结构：安全区 → 顶部标题区 → 内容区
// 说明：底部 Tab 由 Index 的 Tabs 组件负责，本容器只保证内容区自适应
// ============================================================
import router from '@ohos.router';
import { ColorTokens } from '../theme/ColorTokens';
import { ControlSize, FontScale, Spacing, Layout } from '../theme/DesignTokens';
import { BreakpointType, BreakpointTypeEnum } from '../utils/BreakpointSystem';

@Component
export struct PageScaffold {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  /** 状态栏高度（vp），由 EntryAbility 写入 AppStorage */
  @StorageLink('topSafeAreaVp') topSafeArea: number = 0;

  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = true;
  @Prop showHeader: boolean = true;
  @Prop showDivider: boolean = true;
  /** 内容是否可滚动；表单类页面保持可滚动 */
  @Prop scrollable: boolean = true;
  onBack: () => void = () => { router.back(); };

  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
    Column().width('100%')
  }

  private maxContentWidth(): number {
    return new BreakpointType<number>({
      xs: Layout.CONTENT_MAX_SM,
      sm: Layout.CONTENT_MAX_SM,
      md: Layout.CONTENT_MAX_MD,
      lg: Layout.CONTENT_MAX_LG,
      xl: Layout.CONTENT_MAX_XL
    }).getValue(this.currentBreakpoint) ?? Layout.CONTENT_MAX_SM;
  }

  build() {
    Column() {
      if (this.showHeader) {
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
        }
        .width('100%')
        .constraintSize({ minHeight: ControlSize.HEADER })
        .padding({ left: this.showBack ? Spacing.SM : Spacing.PAGE, right: Spacing.PAGE })
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
        .border(this.showDivider ? { width: { bottom: 1 }, color: ColorTokens.border(this.isDarkMode) } : { width: 0 })
      }

      if (this.scrollable) {
        Scroll() {
          Column() {
            this.content()
          }
          .width('100%')
          .constraintSize({ maxWidth: this.maxContentWidth() })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .align(Alignment.Top)
      } else {
        Column() {
          this.content()
        }
        .width('100%')
        .layoutWeight(1)
        .constraintSize({ maxWidth: this.maxContentWidth() })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.topSafeArea })
    .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
