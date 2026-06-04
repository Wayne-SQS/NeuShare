import { ColorTokens } from '@neushare/common';
import modelPrices from '../data/modelPrices.json';
import { ModelPrice } from '../models/ModelCompareModel';

@Component
export struct ModelCompare {
  @State models: ModelPrice[] = [];
  @State sortBy: string = 'overall';
  @State selectedProvider: string = '全部';
  private providers: string[] = ['全部', 'DeepSeek', 'Anthropic', 'OpenAI', '阿里', 'Google', '智谱AI'];

  aboutToAppear(): void {
    this.models = modelPrices;
    this.sortModels();
  }

  sortModels(): void {
    const filtered = this.selectedProvider === '全部'
      ? [...modelPrices]
      : modelPrices.filter(m => m.provider === this.selectedProvider);
    switch (this.sortBy) {
      case 'price': filtered.sort((a, b) => a.inputPrice - b.inputPrice); break;
      case 'coding': filtered.sort((a, b) => b.coding - a.coding); break;
      case 'chinese': filtered.sort((a, b) => b.chinese - a.chinese); break;
      default: filtered.sort((a, b) => b.overall - a.overall);
    }
    this.models = filtered;
  }

  build() {
    Column() {
      Scroll() {
        Row() {
          ForEach(this.providers, (provider: string) => {
            Text(provider)
              .fontSize(13).fontWeight(this.selectedProvider === provider ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedProvider === provider ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_SECONDARY)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 }).borderRadius(16)
              .backgroundColor(this.selectedProvider === provider ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
              .margin({ right: 8 })
              .onClick(() => { this.selectedProvider = provider; this.sortModels(); })
          })
        }.padding({ left: 16 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').margin({ top: 12, bottom: 4 })

      Row() {
        ForEach(
          [{ key: 'overall', label: '综合' }, { key: 'price', label: '价格' }, { key: 'coding', label: '编程' }, { key: 'chinese', label: '中文' }],
          (sort: Record<string, string>) => {
            Text(sort.label)
              .fontSize(12).fontWeight(this.sortBy === sort.key ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.sortBy === sort.key ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 }).borderRadius(16)
              .backgroundColor(this.sortBy === sort.key ? ColorTokens.PRIMARY + '12' : Color.Transparent)
              .margin({ right: 6 })
              .onClick(() => { this.sortBy = sort.key; this.sortModels(); })
          })
        Blank()
      }.width('100%').padding({ left: 16, bottom: 4 })

      List() {
        ForEach(this.models, (model: ModelPrice, index: number) => {
          ListItem() {
            Column() {
              Row() {
                Text((index + 1).toString())
                  .fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_WHITE)
                  .width(22).height(22).borderRadius(7)
                  .backgroundColor(ColorTokens.RANK_COLORS[Math.min(index, ColorTokens.RANK_COLORS.length - 1)])
                  .textAlign(TextAlign.Center)

                Text(model.name)
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                  .margin({ left: 10 })

                Blank()

                Text(model.provider)
                  .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.BG_INPUT).borderRadius(6)
              }.width('100%')

              Row() {
                Text('¥' + model.inputPrice.toFixed(1) + ' / ¥' + model.outputPrice.toFixed(1))
                  .fontSize(13).fontWeight(FontWeight.Medium).fontColor(ColorTokens.TEXT_SECONDARY)
                Text(' · ' + model.priceUnit).fontSize(11).fontColor(ColorTokens.TEXT_DISABLED)
              }.margin({ top: 10 })

              Row() {
                this.bar('综合', model.overall, ColorTokens.PRIMARY)
                this.bar('编程', model.coding, ColorTokens.GREEN)
                this.bar('推理', model.reasoning, ColorTokens.PURPLE)
                this.bar('中文', model.chinese, ColorTokens.RED)
                this.bar('速度', model.speed, ColorTokens.ACCENT)
              }.width('100%').margin({ top: 10 }).justifyContent(FlexAlign.SpaceBetween)

              if (model.note) {
                Text(model.note)
                  .fontSize(11).fontColor(ColorTokens.TEXT_DISABLED)
                  .margin({ top: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%').padding(14)
            .backgroundColor('#FCFCFC').borderRadius(16)
            .margin({ left: 16, right: 16, top: 6, bottom: 6 })
            .shadow({ radius: 8, color: '#0C000000', offsetX: 0, offsetY: 2 })
            .border({ width: 1, color: '#08000000', radius: 16 })
          }
        })
      }.layoutWeight(1).divider({ strokeWidth: 0 })
    }
    .width('100%').height('100%')
  }

  @Builder
  bar(label: string, score: number, color: string) {
    Column() {
      Text(label).fontSize(10).fontColor(ColorTokens.TEXT_HINT)
      Row().width(score * 0.28).height(3).borderRadius(2).backgroundColor(color).margin({ top: 2 })
      Text(score.toString()).fontSize(10).fontWeight(FontWeight.Bold).fontColor(color).margin({ top: 2 })
    }
  }
}
