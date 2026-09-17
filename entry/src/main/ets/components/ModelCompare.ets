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
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private providers: string[] = ['全部', 'Anthropic', 'OpenAI', 'Google', '智谱AI', '月之暗面', 'DeepSeek', '阿里云', '小米', 'Meta'];

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
              ForEach(this.providers, (provider: string, idx: number) => {
                Text(provider)
                  .fontSize(12).fontWeight(this.selectedProvider === provider ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.selectedProvider === provider ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(14)
                  .backgroundColor(this.selectedProvider === provider ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .margin({ right: 6 })
                  .onClick(() => { this.selectedProvider = provider; this.sortModels(); })
              }, (provider: string, idx: number) => 'prov_' + idx.toString())
            }.padding({ left: 16 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').margin({ top: 10, bottom: 6 })

          // ── Sort toggles ──
          Row() {
            ForEach(
              [{ key: 'overall', label: '综合' }, { key: 'price', label: '价格' }, { key: 'coding', label: '编程' }, { key: 'reasoning', label: '推理' }, { key: 'chinese', label: '中文' }],
              (sort: Record<string, string>, idx: number) => {
                Text(sort.label)
                  .fontSize(11).fontWeight(this.sortBy === sort.key ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.sortBy === sort.key ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 }).borderRadius(12)
                  .backgroundColor(this.sortBy === sort.key ? ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '10') : Color.Transparent)
                  .margin({ right: 4 })
                  .onClick(() => { this.sortBy = sort.key; this.sortModels(); })
              }, (sort: Record<string, string>, idx: number) => 'sort_' + sort.key)
            Blank()
            Text(this.showChart ? '▼ 图表' : '▶ 图表').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode))
              .margin({ right: 8 })
              .onClick(() => { this.showChart = !this.showChart; })
            Text(this.isLandscape ? '↺ 竖屏' : '↻ 横屏').fontSize(11)
              .fontColor(ColorTokens.primary(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), radius: 10 })
              .onClick(() => { this.toggleOrientation(); })
          }.width('100%').padding({ left: 16, right: 16, bottom: 6 })

          // ── Overview bar chart ──
          if (this.showChart) {
            Column() {
              Row() {
                Text('📊 综合排名').fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              }.width('100%').padding({ left: 16, top: 4 })

              Column() {
                ForEach([...this.models].sort((a, b) => b.overall - a.overall).slice(0, 10), (m: ModelPrice, i: number) => {
                  Row() {
                    Text((i + 1).toString()).fontSize(10).fontWeight(FontWeight.Bold)
                      .fontColor(i < 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                      .width(18)
                    Text(m.name).fontSize(11).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                      .width(100).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row()
                      .width((m.overall / 100) * 120).height(10).borderRadius(5)
                      .backgroundColor(i < 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                      .margin({ left: 8 })
                    Text(m.overall.toString()).fontSize(11).fontWeight(FontWeight.Bold)
                      .fontColor(i < 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
                      .margin({ left: 6 })
                  }.width('100%').padding({ top: 3, bottom: 3 })
                }, (m: ModelPrice, i: number) => 'mb_' + m.name)
              }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
              .margin({ left: 16, right: 16, top: 4 })
            }
          }

          // ── Model cards ──
          ForEach(this.models, (model: ModelPrice, index: number) => {
            Column() {
              // Header row: rank + name + provider
              Row() {
                Text((index + 1).toString())
                  .fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                  .width(20).height(20).borderRadius(6)
                  .backgroundColor(index < 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.primary(this.isDarkMode))
                  .textAlign(TextAlign.Center)
                Text(model.name)
                  .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                  .layoutWeight(1).margin({ left: 8 }).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(model.provider)
                  .fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(4)
              }.width('100%')

              // Price row
              Row() {
                Text('¥' + model.inputPrice.toFixed(1) + ' → ¥' + model.outputPrice.toFixed(1))
                  .fontSize(12).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                Text(' /百万').fontSize(10).fontColor(ColorTokens.textDisabled(this.isDarkMode))
                if (model.contextWindow >= 1000000) {
                  Text('1M').fontSize(9).fontColor(ColorTokens.success(this.isDarkMode))
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor(ColorTokens.withAlpha(ColorTokens.success(this.isDarkMode), '15')).borderRadius(3)
                    .margin({ left: 6 })
                } else if (model.contextWindow >= 256000) {
                  Text('256K').fontSize(9).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor(ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '20')).borderRadius(3)
                    .margin({ left: 6 })
                }
              }.margin({ top: 8 })

              // Dimension bars
              // 亮色：多彩（靛蓝/天空蓝/紫/红） · 深色：极简黑白（靠明度强度区分维度）
              Row() {
                this.dimBar('综合', model.overall, this.dimColor('overall'), 0.45)
                this.dimBar('编程', model.coding, this.dimColor('coding'), 0.45)
              }.width('100%').margin({ top: 8 })
              Row() {
                this.dimBar('推理', model.reasoning, this.dimColor('reasoning'), 0.45)
                this.dimBar('中文', model.chinese, this.dimColor('chinese'), 0.45)
              }.width('100%').margin({ top: 4 })

              // Note
              if (model.note) {
                Text(model.note)
                  .fontSize(10).fontColor(ColorTokens.textDisabled(this.isDarkMode)).lineHeight(14)
                  .margin({ top: 8 }).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%').padding(14)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .margin({ left: 16, right: 16, top: 5, bottom: 5 })
            .shadow({ radius: 6, color: this.isDarkMode ? '#33FFFFFF' : '#0A000000', offsetX: 0, offsetY: 2 })
            .border({ width: 1, color: this.isDarkMode ? ColorTokens.DIVIDER_DARK : '#06000000', radius: 14 })
          }, (model: ModelPrice, index: number) => 'mdl_' + index.toString())

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%')
  }

  // 维度条颜色：亮色多彩（4色区分） · 深色极简（明度阶梯：白→近白→浅灰→中灰）
  dimColor(dim: string): string {
    if (this.isDarkMode) {
      switch (dim) {
        case 'overall': return '#FFFFFF';   // 纯白（最强）
        case 'coding': return '#E8E8EC';    // 近白
        case 'reasoning': return '#C0C0C5'; // 浅灰
        case 'chinese': return '#8A8A93';   // 中灰（最弱）
        default: return '#FFFFFF';
      }
    } else {
      switch (dim) {
        case 'overall': return ColorTokens.primary(false);
        case 'coding': return ColorTokens.ACCENT_SKY_LIGHT;
        case 'reasoning': return ColorTokens.PURPLE;
        case 'chinese': return ColorTokens.ERROR_LIGHT;
        default: return ColorTokens.primary(false);
      }
    }
  }

  @Builder
  dimBar(label: string, score: number, color: string, ratio: number) {
    Column() {
      Row() {
        Text(label).fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode)).width(26)
        Row()
          .width((score / 100) * 120).height(7).borderRadius(4)
          .backgroundColor(score >= 90 ? color : score >= 80 ? ColorTokens.withAlpha(color, 'CC') : ColorTokens.withAlpha(color, '80'))
        Text(score.toString()).fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(score >= 90 ? color : ColorTokens.textSecondary(this.isDarkMode))
          .margin({ left: 6 })
      }
    }
  }
}
