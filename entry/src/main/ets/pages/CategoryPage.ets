import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { DataService } from '../services/DataService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';

@Entry
@Component
struct CategoryPage {
  @State resources: ResourceItemModel[] = [];
  @State categoryTitle: string = '';
  @State categoryDesc: string = '';
  private categoryId: number = 1;
  private dataService: DataService = DataService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.categoryId = params['categoryId'] as number;
      this.categoryTitle = params['categoryTitle'] as string;
    }
    const cat = this.dataService.getCategoryById(this.categoryId);
    if (cat) {
      this.categoryDesc = cat.description;
    }
    this.resources = this.dataService.getResourcesByCategory(this.categoryId);
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Column() {
          Text(this.categoryTitle)
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          if (this.categoryDesc) {
            Text(this.categoryDesc)
              .fontSize(11).fontColor(ColorTokens.TEXT_HINT).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }.layoutWeight(1).margin({ left: 12, right: 8 }).alignItems(HorizontalAlign.Start)
        Text(this.resources.length + '个').fontSize(13).fontColor(ColorTokens.TEXT_HINT)
      }
      .width('100%').height(52).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      if (this.resources.length === 0) {
        Column() {
          Text('📭').fontSize(48).margin({ top: 80 })
          Text('暂无资源').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
          Text('该分类下暂无资源，敬请期待').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.resources, (item: ResourceItemModel) => {
            ListItem() {
              ResourceCard({
                resource: item,
                onTap: () => {
                  router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                }
              })
            }
          })
        }
        .layoutWeight(1).divider({ strokeWidth: 0 })
        .margin({ top: 4 })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
