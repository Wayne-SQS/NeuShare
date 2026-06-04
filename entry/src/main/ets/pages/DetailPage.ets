import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils } from '@neushare/common';
import { DataService } from '../services/DataService';
import { FavoriteService } from '../services/FavoriteService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';
import { Context } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
struct DetailPage {
  @State resource: ResourceItemModel | null = null;
  @State relatedResources: ResourceItemModel[] = [];
  @State isFavorited: boolean = false;
  private resourceId: number = 0;
  private dataService: DataService = DataService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.resourceId = params['resourceId'] as number;
    }
    const res = this.dataService.getResourceById(this.resourceId);
    if (res) {
      this.resource = res;
      this.relatedResources = this.dataService.getRelatedResources(res, 5);
      const context = getContext(this) as Context;
      await this.favoriteService.init(context);
      this.isFavorited = await this.favoriteService.isFavorite(this.resourceId);
      await this.favoriteService.addHistory(this.resourceId);
    }
  }

  async toggleFavorite(): Promise<void> {
    const isFav = await this.favoriteService.toggleFavorite(this.resourceId);
    this.isFavorited = isFav;
  }

  openExternalUrl(url: string): void {
    if (!url || url.trim().length === 0) return;
    const ctx = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browser'],
      uri: url
    };
    try {
      ctx.startAbility(want);
    } catch (err) {
      // Silently fail
    }
  }

  build() {
    Column() {
      if (!this.resource) {
        Column() { Text('加载中...').fontSize(16).fontColor(ColorTokens.TEXT_HINT) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // Header
            Row() {
              Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY).onClick(() => { router.back(); })
              Blank()
              Text(this.isFavorited ? '★' : '☆')
                .fontSize(28).fontColor(ColorTokens.ACCENT)
                .onClick(() => { this.toggleFavorite(); })
            }
            .width('100%').height(48).padding({ left: 16, right: 16 })
            .backgroundColor(ColorTokens.BG_CARD)

            // Type hero
            Stack({ alignContent: Alignment.Center }) {
              Column()
                .width('100%').height(140)
                .backgroundColor(ResourceTypeUtils.typeColor(this.resource.type) + '10')
              Text(ResourceTypeUtils.typeEmoji(this.resource.type)).fontSize(56)
            }
            .width('100%')

            // Info card
            Column() {
              Text(this.resource.title)
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.TEXT_PRIMARY).width('100%')

              Row() {
                Text(this.resource.author).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
                Text(' · ').fontColor(ColorTokens.TEXT_DISABLED)
                Text(this.resource.publishDate).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
                Text(' · ').fontColor(ColorTokens.TEXT_DISABLED)
                Text('★ ' + this.resource.rating.toFixed(1)).fontSize(13).fontColor(ColorTokens.ACCENT)
              }.margin({ top: 8 })

              Row() {
                Text('来源：' + this.resource.source)
                  .fontSize(13).fontColor(ColorTokens.PRIMARY).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }.margin({ top: 4 })

              // Tags
              Row() {
                ForEach(this.resource.tags, (tag: string) => {
                  Text(tag)
                    .fontSize(11).fontColor(ColorTokens.PRIMARY)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                    .borderRadius(10).margin({ right: 8, top: 8 })
                })
              }.width('100%')

              // Divider
              Row().width('100%').height(1).backgroundColor(ColorTokens.DIVIDER).margin({ top: 16, bottom: 16 })

              // Description
              Text('📖 资源介绍')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text(this.resource.description)
                .fontSize(14).fontColor(ColorTokens.TEXT_SECONDARY)
                .lineHeight(22).margin({ top: 8 })
            }
            .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD)

            // Related
            if (this.relatedResources.length > 0) {
              Text('📌 相关推荐')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                .width('100%').padding({ left: 16, top: 24, bottom: 4 })

              ForEach(this.relatedResources, (item: ResourceItemModel) => {
                ResourceCard({
                  resource: item,
                  onTap: () => {
                    router.replaceUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                  }
                })
              })
            }

            Column().height(20)
          }
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
      }

      // Bottom action
      if (this.resource) {
        Row() {
          if (this.resource.url && this.resource.url.trim().length > 0) {
            Button('访问资源')
              .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_WHITE)
              .backgroundColor(this.resource.url ? ColorTokens.PRIMARY : ColorTokens.TEXT_DISABLED)
              .borderRadius(14)
              .shadow({ radius: 8, color: ColorTokens.PRIMARY + '40', offsetX: 0, offsetY: 4 })
              .scale({ x: 0.97, y: 0.97 })
              .animation({ curve: Curve.Spring, duration: 120 })
              .onClick(() => { this.openExternalUrl(this.resource!.url); })
          } else {
            Button('暂无链接')
              .width('100%').height(48).fontSize(16)
              .backgroundColor(ColorTokens.TEXT_DISABLED).borderRadius(12).enabled(false)
          }
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .backgroundColor(ColorTokens.BG_CARD)
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
