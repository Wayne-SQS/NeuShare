import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';

@Component
export struct CourseRecommendCard {
  @Prop courseName: string = '';
  @Prop courseEmoji: string = '📖';
  @Prop courseDesc: string = '';
  @Prop searchKeyword: string = '';
  @State pressed: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(44).height(44).borderRadius(14)
          .backgroundColor(ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '18'))
        Text(this.courseEmoji).fontSize(22)
      }

      Column() {
        Text(this.courseName)
          .fontSize(15).fontWeight(FontWeight.Bolder).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.courseDesc)
          .fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1).margin({ left: 12 })

      Text('查看 ›').fontSize(12).fontColor(ColorTokens.primary(this.isDarkMode)).fontWeight(FontWeight.Bold)
    }
    .width('100%').padding(14).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(14).margin({ left: 4, right: 4, top: 4, bottom: 4 })
    .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 14 })
    .shadow({ radius: 4, color: ColorTokens.SHADOW_LIGHT, offsetX: 0, offsetY: 1 })
    .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
    .animation({ curve: Curve.FastOutSlowIn, duration: 120 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/SearchPage',
        params: { keyword: this.searchKeyword || this.courseName }
      });
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) { this.pressed = true; }
      else { this.pressed = false; }
    })
  }
}
