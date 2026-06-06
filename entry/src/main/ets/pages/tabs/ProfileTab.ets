import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';

@Component
export struct ProfileTab {
  @Prop favoriteCount: number = 0;
  @Prop historyCount: number = 0;

  build() {
    Column() {
      Row() {
        Text('我的').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      }
      .width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Avatar card
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(64).height(64).borderRadius(32).backgroundColor(ColorTokens.BG_AVATAR)
              Text('👤').fontSize(32)
            }
            Column() {
              Text('软件学院学子').fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('NEU Software College').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.margin({ left: 14 })
            Blank()
            Text('›').fontSize(22).fontColor(ColorTokens.TEXT_DISABLED)
          }
          .width('100%').padding(18)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 16 })
          .onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })

          // Stats
          Row() {
            Column() {
              Text(this.favoriteCount.toString()).fontSize(26).fontWeight(FontWeight.Bold).fontColor(ColorTokens.PRIMARY)
              Text('收藏').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.width('50%').onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })

            Column() {
              Text(this.historyCount.toString()).fontSize(26).fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
              Text('浏览记录').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.width('50%').onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })
          }
          .width('100%').padding(16)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 10 })

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
