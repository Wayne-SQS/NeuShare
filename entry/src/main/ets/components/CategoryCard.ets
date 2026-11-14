import { ColorTokens, FontScale, Radii, Spacing, ControlSize, Elevation } from '@neushare/common';
import { CategoryItem } from '../models/ResourceModel';

@Component
export struct CategoryCard {
  @Prop category: CategoryItem;
  @State tapped: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onTap: () => void = () => {};

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(ControlSize.ICON_LG + Spacing.SM).height(ControlSize.ICON_LG + Spacing.SM).borderRadius(Radii.XXL)
          .backgroundColor(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '1A') : ColorTokens.withAlpha(this.category.color, '1A'))
        Text(this.category.title.substring(0, 1))
          .fontSize(FontScale.SECTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.category.color)
      }

      Text(this.category.title)
        .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: Spacing.SM })

      Text(this.category.description)
        .fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode))
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: Spacing.XS }).textAlign(TextAlign.Center).lineHeight(FontScale.BODY)
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG, left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(Radii.CARD)
    .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
    .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.border(this.isDarkMode), radius: Radii.CARD })
    .scale({ x: this.tapped ? 0.95 : 1, y: this.tapped ? 0.95 : 1 })
    .animation({ curve: Curve.EaseOut, duration: 200 })
    .hoverEffect(HoverEffect.Auto)
    .transition(TransitionEffect.OPACITY.animation({ curve: Curve.EaseOut, duration: 300 }))
    .onClick(() => { this.onTap(); })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.tapped = true;
      } else {
        this.tapped = false;
      }
    })
  }
}
