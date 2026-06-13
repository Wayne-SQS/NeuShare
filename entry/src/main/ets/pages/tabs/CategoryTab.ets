import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { CategoryItem } from '../../models/ResourceModel';
import { CategoryCard } from '../../components/CategoryCard';

@Component
export struct CategoryTab {
  @Prop categories: CategoryItem[] = [];
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  private columnsTemplate(): string {
    return new BpType<string>({ sm: '1fr 1fr', md: '1fr 1fr 1fr', lg: '1fr 1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr';
  }

  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 640, lg: 780, xl: 920 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private titleFontSize(): number {
    return new BpType<number>({ sm: 20, md: 22, lg: 26, xl: 30 }).getValue(this.currentBreakpoint) ?? 20;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Column() {
            Text('全部学习分类')
              .fontSize(this.titleFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .width('100%').padding({ left: this.contentPadding(), top: 16 })

            Grid() {
              ForEach(this.categories, (item: CategoryItem) => {
                GridItem() {
                  CategoryCard({
                    category: item,
                    onTap: () => {
                      router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: item.id, categoryTitle: item.title } });
                    }
                  })
                }
              })
            }
            .columnsTemplate(this.columnsTemplate())
            .rowsGap(8)
            .columnsGap(8)
            .width('100%')
            .padding({ left: this.contentPadding() - 4, right: this.contentPadding() - 4, top: 8 })

            Column().height(80)
          }
          .constraintSize({ maxWidth: this.maxContentWidth() })
          .width('100%')
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%').layoutWeight(1)
  }
}
