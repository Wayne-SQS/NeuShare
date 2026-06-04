import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ModelCompare } from '../components/ModelCompare';

@Entry
@Component
struct ModelComparePage {
  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('AI 模型价格对比')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 24 })
      }
      .width('100%').height(52).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      ModelCompare()
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
