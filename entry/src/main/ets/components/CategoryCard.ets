import { ColorTokens } from '@neushare/common';
import { CategoryItem } from '../models/ResourceModel';

@Component
export struct CategoryCard {
  @Prop category: CategoryItem;
  @State tapped: boolean = false;
  onTap: () => void = () => {};

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(56).height(56).borderRadius(18)
          .backgroundColor(this.category.color + '1A')
        Text(this.category.icon)
          .fontSize(28)
      }

      Text(this.category.title)
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.TEXT_PRIMARY)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 10 })

      Text(this.category.description)
        .fontSize(10).fontColor(ColorTokens.TEXT_HINT)
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 }).textAlign(TextAlign.Center).lineHeight(15)
    }
    .width('46%')
    .padding({ top: 18, bottom: 16, left: 10, right: 10 })
    .backgroundColor('#FCFCFC')
    .borderRadius(18)
    .shadow({ radius: 8, color: '#0E000000', offsetX: 0, offsetY: 2 })
    .border({ width: 1, color: '#08000000', radius: 18 })
    .scale({ x: this.tapped ? 0.95 : 1, y: this.tapped ? 0.95 : 1 })
    .animation({ curve: Curve.FastOutSlowIn, duration: 120 })
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
