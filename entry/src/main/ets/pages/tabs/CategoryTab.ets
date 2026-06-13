import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { CategoryItem } from '../../models/ResourceModel';
import { CategoryCard } from '../../components/CategoryCard';

@Component
export struct CategoryTab {
  @Prop categories: CategoryItem[] = [];
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;

  private columnsTemplate(): string {
    return new BpType<string>({ sm: '1fr 1fr', md: '1fr 1fr 1fr', lg: '1fr 1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr';
  }

  build() {
    Scroll() {
      Column() {
        Text('全部学习分类')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          .width('100%').padding({ left: 16, top: 16 })

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
        .padding({ left: 12, right: 12, top: 8 })

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }
}
