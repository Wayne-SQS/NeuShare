import router from '@ohos.router';
import { ColorTokens, FontScale, Radii, Spacing, ControlSize, Elevation } from '@neushare/common';

@Component
export struct CourseRecommendCard {
  @Prop courseName: string = '';
  @Prop courseDesc: string = '';
  @Prop searchKeyword: string = '';
  @State pressed: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(ControlSize.INPUT).height(ControlSize.INPUT).borderRadius(Radii.CARD)
          .backgroundColor(ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '18'))
        Text(this.courseName.substring(0, 1))
          .fontSize(FontScale.SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.primary(this.isDarkMode))
      }

      Column() {
        Text(this.courseName)
          .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.courseDesc)
          .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: Spacing.XXS })
      }
      .layoutWeight(1).margin({ left: Spacing.MD })

      Text('查看').fontSize(FontScale.LABEL).fontColor(ColorTokens.primary(this.isDarkMode)).fontWeight(FontWeight.Medium)
    }
    .width('100%').padding(Spacing.LG).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(Radii.CARD).margin({ left: Spacing.XS, right: Spacing.XS, top: Spacing.XS, bottom: Spacing.XS })
    .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.border(this.isDarkMode), radius: Radii.CARD })
    .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
    .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
    .animation({ curve: Curve.EaseOut, duration: 200 })
    .hoverEffect(HoverEffect.Auto)
    .transition(TransitionEffect.OPACITY.animation({ curve: Curve.EaseOut, duration: 300 }))
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
