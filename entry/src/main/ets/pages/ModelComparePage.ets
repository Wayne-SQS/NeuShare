import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ModelCompare } from '../components/ModelCompare';

@Entry
@Component
struct ModelComparePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('AI 模型价格对比')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 24 })
      }
      .width('100%').height(52).padding({ left: 24, right: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      ModelCompare()
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
