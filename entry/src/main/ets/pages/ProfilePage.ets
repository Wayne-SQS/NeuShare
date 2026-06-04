import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { DataService } from '../services/DataService';
import { FavoriteService } from '../services/FavoriteService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct ProfilePage {
  @State favorites: ResourceItemModel[] = [];
  @State historyResources: ResourceItemModel[] = [];
  @State favoriteCount: number = 0;
  @State activeTab: number = 0;
  private dataService: DataService = DataService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();

  async aboutToAppear(): Promise<void> {
    const context = getContext(this) as Context;
    await this.favoriteService.init(context);
    await this.loadData();
  }

  async onPageShow(): Promise<void> {
    await this.loadData();
  }

  async loadData(): Promise<void> {
    const favIds = await this.favoriteService.getFavoriteIds();
    this.favoriteCount = favIds.size;
    this.favorites = this.dataService.getAllResources().filter(r => favIds.has(r.id));
    const historyIds = await this.favoriteService.getHistory();
    this.historyResources = historyIds
      .map(id => this.dataService.getResourceById(id))
      .filter(r => r !== undefined) as ResourceItemModel[];
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('我的').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      }
      .width('100%').height(48).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Profile card
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(72).height(72).borderRadius(36).backgroundColor(ColorTokens.BG_AVATAR)
              Text('👤').fontSize(36)
            }
            Column() {
              Text('软件学院学子')
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('NEU Software College')
                .fontSize(13).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.margin({ left: 14 })
          }
          .width('100%').padding(20)
          .backgroundColor('#FCFCFC').borderRadius(18)
          .margin({ left: 16, right: 16, top: 16 })
          .shadow({ radius: 12, color: '#0E000000', offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: '#08000000', radius: 18 })

          // Stats cards
          Row() {
            Column() {
              Text(this.favoriteCount.toString())
                .fontSize(28).fontWeight(FontWeight.Bold).fontColor(ColorTokens.ACCENT)
              Text('我的收藏').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }
            .width('48%').padding(16)
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
            .onClick(() => { this.activeTab = 0; })

            Column() {
              Text(this.historyResources.length.toString())
                .fontSize(28).fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
              Text('浏览历史').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }
            .width('48%').padding(16)
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
            .onClick(() => { this.activeTab = 1; })
          }
          .width('100%').padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 10 })

          // Tab pills
          Row() {
            Text('收藏')
              .fontSize(14).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 0 ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 0 ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
              .onClick(() => { this.activeTab = 0; })

            Text('浏览历史')
              .fontSize(14).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 1 ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 1 ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 1; })

            Blank()
          }
          .width('100%').padding({ left: 16 }).margin({ top: 16 })

          // Content
          if (this.activeTab === 0) {
            if (this.favorites.length === 0) {
              Column() {
                Text('☆').fontSize(48).margin({ top: 60 })
                Text('还没有收藏').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
                Text('浏览资源时点击 ☆ 即可收藏').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
              }.width('100%')
            } else {
              ForEach(this.favorites, (item: ResourceItemModel) => {
                ResourceCard({
                  resource: item,
                  isFavorite: true,
                  onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                })
              })
            }
          } else {
            if (this.historyResources.length === 0) {
              Column() {
                Text('🕐').fontSize(48).margin({ top: 60 })
                Text('还没有浏览记录').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
              }.width('100%')
            } else {
              ForEach(this.historyResources, (item: ResourceItemModel) => {
                ResourceCard({
                  resource: item,
                  onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                })
              })
            }
          }

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
