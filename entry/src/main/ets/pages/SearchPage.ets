import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { DataService } from '../services/DataService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State results: ResourceItemModel[] = [];
  private dataService: DataService = DataService.getInstance();

  onSearch(value: string): void {
    this.keyword = value;
    if (!value.trim()) {
      this.results = [];
    } else {
      this.results = this.dataService.searchResources(value);
    }
  }

  build() {
    Column() {
      // Search header
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })

        TextInput({ text: this.keyword, placeholder: '搜索资源、标签、作者...' })
          .fontSize(14)
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ColorTokens.BG_INPUT)
          .borderRadius(20)
          .padding({ left: 12 })
          .margin({ left: 8, right: 12 })
          .onChange((value: string) => {
            this.onSearch(value);
          })

        if (this.keyword.length > 0) {
          Text('✕')
            .fontSize(18)
            .fontColor(ColorTokens.TEXT_HINT)
            .onClick(() => {
              this.onSearch('');
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      // Results
      if (this.keyword.trim().length === 0) {
        // Empty state — hints
        Column() {
          Text('🔍')
            .fontSize(48)
            .margin({ top: 100 })
          Text($r('app.string.search_empty_hint'))
            .fontSize(16)
            .fontColor(ColorTokens.TEXT_HINT)
            .margin({ top: 12 })
          Text($r('app.string.search_support_hint'))
            .fontSize(13)
            .fontColor(ColorTokens.TEXT_DISABLED)
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.results.length === 0) {
        // No results
        Column() {
          Text('😔')
            .fontSize(48)
            .margin({ top: 80 })
          Text('未找到匹配「' + this.keyword + '」的资源')
            .fontSize(16)
            .fontColor(ColorTokens.TEXT_HINT)
            .margin({ top: 12 })
          Text('试试更换关键词')
            .fontSize(13)
            .fontColor(ColorTokens.TEXT_DISABLED)
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // Results list
        Column() {
          Text('找到 ' + this.results.length + ' 个结果')
            .fontSize(13)
            .fontColor(ColorTokens.TEXT_HINT)
            .padding({ left: 16, top: 12, bottom: 4 })
            .width('100%')

          List() {
            ForEach(this.results, (item: ResourceItemModel) => {
              ListItem() {
                ResourceCard({
                  resource: item,
                  onTap: () => {
                    router.pushUrl({
                      url: 'pages/DetailPage',
                      params: { resourceId: item.id }
                    });
                  }
                })
              }
            }, (item: ResourceItemModel) => item.id.toString())
          }
          .layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: ColorTokens.DIVIDER, startMargin: 76, endMargin: 16 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.BG_PAGE)
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
  }
}
