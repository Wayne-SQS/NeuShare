import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';

@Component
export struct CourseRecommendCard {
  @Prop courseName: string = '';
  @Prop courseEmoji: string = '📖';
  @Prop courseDesc: string = '';
  @Prop categoryId: number = 1;
  @Prop categoryTitle: string = '';
  @State pressed: boolean = false;

  build() {
    Row() {
      // Emoji badge
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(44).height(44).borderRadius(14)
          .backgroundColor(ColorTokens.PRIMARY_LIGHT)
        Text(this.courseEmoji)
          .fontSize(22)
      }

      // Text
      Column() {
        Text(this.courseName)
          .fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.TEXT_PRIMARY)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.courseDesc)
          .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1).margin({ left: 12 })

      Text('查看 ›')
        .fontSize(12).fontColor(ColorTokens.ACCENT)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%').padding(14)
    .backgroundColor('#FCFCFC')
    .borderRadius(14)
    .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .border({ width: 1, color: '#06000000', radius: 14 })
    .margin({ left: 16, right: 16, top: 4, bottom: 4 })
    .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
    .animation({ curve: Curve.FastOutSlowIn, duration: 120 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/CategoryPage',
        params: {
          categoryId: this.categoryId,
          categoryTitle: this.categoryTitle || this.courseName
        }
      });
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else {
        this.pressed = false;
      }
    })
  }
}
