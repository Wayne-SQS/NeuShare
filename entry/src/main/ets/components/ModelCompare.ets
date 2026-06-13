import { ColorTokens } from '@neushare/common';
import modelPrices from '../data/modelPrices.json';
import { ModelPrice } from '../models/ModelCompareModel';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';

@Component
export struct ModelCompare {
  @State models: ModelPrice[] = [];
  @State sortBy: string = 'overall';
  @State selectedProvider: string = '全部';
  @State showChart: boolean = true;
  @State isLandscape: boolean = false;
  private providers: string[] = ['全部', 'DeepSeek', 'Anthropic', 'OpenAI', '阿里云', '月之暗面', '小米', 'MiniMax', 'Google', '智谱AI'];

  toggleOrientation(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const win = window.getLastWindow(ctx);
      win.then(w => {
        if (this.isLandscape) {
          w.setPreferredOrientation(window.Orientation.PORTRAIT);
        } else {
          w.setPreferredOrientation(window.Orientation.LANDSCAPE);
        }
        this.isLandscape = !this.isLandscape;
      });
    } catch (e) {
      console.error('Orientation toggle failed: ' + JSON.stringify(e));
    }
  }

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
      case 'reasoning': filtered.sort((a, b) => b.reasoning - a.reasoning); break;
      default: filtered.sort((a, b) => b.overall - a.overall);
    }
    this.models = filtered;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // ── Provider filter chips ──
          Scroll() {
            Row() {
              ForEach(this.providers, (provider: string) => {
                Text(provider)
                  .fontSize(12).fontWeight(this.selectedProvider === provider ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.selectedProvider === provider ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_SECONDARY)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(14)
                  .backgroundColor(this.selectedProvider === provider ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
                  .margin({ right: 6 })
                  .onClick(() => { this.selectedProvider = provider; this.sortModels(); })
              })
            }.padding({ left: 16 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').margin({ top: 10, bottom: 6 })

          // ── Sort toggles ──
          Row() {
            ForEach(
              [{ key: 'overall', label: '综合' }, { key: 'price', label: '价格' }, { key: 'coding', label: '编程' }, { key: 'reasoning', label: '推理' }, { key: 'chinese', label: '中文' }],
              (sort: Record<string, string>) => {
                Text(sort.label)
                  .fontSize(11).fontWeight(this.sortBy === sort.key ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.sortBy === sort.key ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 }).borderRadius(12)
                  .backgroundColor(this.sortBy === sort.key ? ColorTokens.PRIMARY + '10' : Color.Transparent)
                  .margin({ right: 4 })
                  .onClick(() => { this.sortBy = sort.key; this.sortModels(); })
              })
            Blank()
            Text(this.showChart ? '▼ 图表' : '▶ 图表').fontSize(11).fontColor(ColorTokens.TEXT_HINT)
              .margin({ right: 8 })
              .onClick(() => { this.showChart = !this.showChart; })
            Text(this.isLandscape ? '↺ 竖屏' : '↻ 横屏').fontSize(11)
              .fontColor(ColorTokens.PRIMARY)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .border({ width: 1, color: ColorTokens.PRIMARY + '40', radius: 10 })
              .onClick(() => { this.toggleOrientation(); })
          }.width('100%').padding({ left: 16, right: 16, bottom: 6 })

          // ── Overview bar chart ──
          if (this.showChart) {
            Column() {
              Row() {
                Text('📊 综合排名').fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              }.width('100%').padding({ left: 16, top: 4 })

              Column() {
                ForEach([...this.models].sort((a, b) => b.overall - a.overall).slice(0, 10), (m: ModelPrice, i: number) => {
                  Row() {
                    Text((i + 1).toString()).fontSize(10).fontWeight(FontWeight.Bold)
                      .fontColor(i < 3 ? ColorTokens.ACCENT : ColorTokens.TEXT_HINT)
                      .width(18)
                    Text(m.name).fontSize(11).fontColor(ColorTokens.TEXT_PRIMARY)
                      .width(100).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row()
                      .width((m.overall / 100) * 120).height(10).borderRadius(5)
                      .backgroundColor(i < 3 ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
                      .margin({ left: 8 })
                    Text(m.overall.toString()).fontSize(11).fontWeight(FontWeight.Bold)
                      .fontColor(i < 3 ? ColorTokens.ACCENT : ColorTokens.TEXT_SECONDARY)
                      .margin({ left: 6 })
                  }.width('100%').padding({ top: 3, bottom: 3 })
                })
              }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
              .margin({ left: 16, right: 16, top: 4 })
            }
          }

          // ── Model cards ──
          ForEach(this.models, (model: ModelPrice, index: number) => {
            Column() {
              // Header row: rank + name + provider
              Row() {
                Text((index + 1).toString())
                  .fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_WHITE)
                  .width(20).height(20).borderRadius(6)
                  .backgroundColor(index < 3 ? ColorTokens.ACCENT : ColorTokens.PRIMARY)
                  .textAlign(TextAlign.Center)
                Text(model.name)
                  .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                  .layoutWeight(1).margin({ left: 8 }).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(model.provider)
                  .fontSize(10).fontColor(ColorTokens.TEXT_HINT)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.BG_INPUT).borderRadius(4)
              }.width('100%')

              // Price row
              Row() {
                Text('¥' + model.inputPrice.toFixed(1) + ' → ¥' + model.outputPrice.toFixed(1))
                  .fontSize(12).fontWeight(FontWeight.Medium).fontColor(ColorTokens.TEXT_SECONDARY)
                Text(' /百万').fontSize(10).fontColor(ColorTokens.TEXT_DISABLED)
                if (model.contextWindow >= 1000000) {
                  Text('1M').fontSize(9).fontColor(ColorTokens.GREEN)
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor(ColorTokens.GREEN + '15').borderRadius(3)
                    .margin({ left: 6 })
                } else if (model.contextWindow >= 256000) {
                  Text('256K').fontSize(9).fontColor(ColorTokens.ACCENT)
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor(ColorTokens.ACCENT + '20').borderRadius(3)
                    .margin({ left: 6 })
                }
              }.margin({ top: 8 })

              // Dimension bars
              Row() {
                this.dimBar('综合', model.overall, ColorTokens.PRIMARY, 0.45)
                this.dimBar('编程', model.coding, '#3A8C6E', 0.45)
              }.width('100%').margin({ top: 8 })
              Row() {
                this.dimBar('推理', model.reasoning, '#7C5CBF', 0.45)
                this.dimBar('中文', model.chinese, '#C0392B', 0.45)
              }.width('100%').margin({ top: 4 })

              // Note
              if (model.note) {
                Text(model.note)
                  .fontSize(10).fontColor(ColorTokens.TEXT_DISABLED).lineHeight(14)
                  .margin({ top: 8 }).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%').padding(14)
            .backgroundColor('#FCFCFC').borderRadius(14)
            .margin({ left: 16, right: 16, top: 5, bottom: 5 })
            .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 2 })
            .border({ width: 1, color: '#06000000', radius: 14 })
          })

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%')
  }

  @Builder
  dimBar(label: string, score: number, color: string, ratio: number) {
    Column() {
      Row() {
        Text(label).fontSize(10).fontColor(ColorTokens.TEXT_HINT).width(26)
        Row()
          .width((score / 100) * 120).height(7).borderRadius(4)
          .backgroundColor(score >= 90 ? color : score >= 80 ? color + 'CC' : color + '80')
        Text(score.toString()).fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(score >= 90 ? color : ColorTokens.TEXT_SECONDARY)
          .margin({ left: 6 })
      }
    }
  }
}
