import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';

@Component
export struct CourseRecommendCard {
  @Prop courseName: string = '';
  @Prop courseEmoji: string = '📖';
  @Prop courseDesc: string = '';
  @Prop searchKeyword: string = '';
  @State pressed: boolean = false;

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(44).height(44).borderRadius(14)
          .backgroundColor('#FF5A5F18')
        Text(this.courseEmoji).fontSize(22)
      }

      Column() {
        Text(this.courseName)
          .fontSize(15).fontWeight(FontWeight.Bolder).fontColor('#000000')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.courseDesc)
          .fontSize(11).fontColor('#888888')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1).margin({ left: 12 })

      Text('查看 ›').fontSize(12).fontColor('#FF5A5F').fontWeight(FontWeight.Bold)
    }
    .width('100%').padding(14).backgroundColor('#FFFFFF')
    .borderRadius(14).margin({ left: 16, right: 16, top: 4, bottom: 4 })
    .border({ width: 1, color: '#F0F0F0', radius: 14 })
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
