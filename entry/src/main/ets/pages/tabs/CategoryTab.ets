import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { CategoryItem } from '../../models/ResourceModel';
import { CategoryCard } from '../../components/CategoryCard';

@Component
export struct CategoryTab {
  @Prop categories: CategoryItem[] = [];

  build() {
    Scroll() {
      Column() {
        Text('全部学习分类')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          .width('100%').padding({ left: 16, top: 16 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
          ForEach(this.categories, (item: CategoryItem) => {
            CategoryCard({
              category: item,
              onTap: () => {
                router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: item.id, categoryTitle: item.title } });
              }
            }).margin({ top: 8 })
          })
        }.width('100%').padding({ left: 8, right: 8 })

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }
}
