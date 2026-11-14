import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, BlurPerformance, FontScale, Spacing, EmptyState, GridLayout } from '@neushare/common';
import { CategoryItem } from '../../models/ResourceModel';
import { CategoryCard } from '../../components/CategoryCard';

@Component
export struct CategoryTab {
  @Prop categories: CategoryItem[] = [];
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State appearOpacity: number = 0;

  aboutToAppear(): void {
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 576, lg: 656, xl: 900 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Column() {
            Text('全部分类')
              .fontSize(FontScale.HERO).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .width('100%').padding({ left: Spacing.PAGE, top: Spacing.LG })
            Text(this.categories.length.toString() + ' 个学习分类')
              .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textHint(this.isDarkMode))
              .width('100%').padding({ left: Spacing.PAGE, top: Spacing.XXS })

            if (this.categories.length === 0) {
              EmptyState({ message: '暂无分类', hint: '请稍后重试' })
            } else {
              GridRow({
                columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
                gutter: { x: Spacing.SM, y: Spacing.SM },
                breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
              }) {
                ForEach(this.categories, (item: CategoryItem) => {
                  GridCol({ span: 1 }) {
                    CategoryCard({
                      category: item,
                      onTap: () => {
                        router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: item.id, categoryTitle: item.title } });
                      }
                    })
                  }
                }, (item: CategoryItem) => item.id.toString())
              }
              .width('100%')
              .padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })
            }

            Column().height(80)
          }
          .constraintSize({ maxWidth: this.maxContentWidth() })
          .width('100%')
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
      .onScrollFrameBegin(() => { BlurPerformance.onScrollStart(); return { offsetRemain: 0 }; })
      .onScrollStop(() => { BlurPerformance.onScrollStop(); })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').layoutWeight(1)
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }
}
