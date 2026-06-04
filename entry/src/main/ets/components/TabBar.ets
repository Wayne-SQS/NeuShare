import { ColorTokens } from '@neushare/common';

@Component
export struct TabBar {
  @Link currentTab: number;
  private tabLabels: string[] = ['首页', '分类', '搜索', '我的'];

  build() {
    Row() {
      ForEach(this.tabLabels, (label: string, index: number) => {
        Column() {
          Text(label)
            .fontSize(12)
            .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(index === this.currentTab ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
          if (index === this.currentTab) {
            Row()
              .width(16)
              .height(3)
              .borderRadius(2)
              .backgroundColor(ColorTokens.PRIMARY)
              .margin({ top: 4 })
          }
        }
        .width('25%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentTab = index;
        })
      })
    }
    .width('100%')
    .height(52)
    .backgroundColor(ColorTokens.BG_CARD)
    .padding({ bottom: 4 })
  }
}
