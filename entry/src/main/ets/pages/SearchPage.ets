import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceService, TagCount } from '../services/ResourceService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State results: ResourceItemModel[] = [];
  @State popularTags: TagCount[] = [];
  @State sortMode: SortMode = 'default';
  private resourceService: ResourceService = ResourceService.getInstance();

  aboutToAppear(): void {
    this.popularTags = this.resourceService.getAllTags();
    const params = router.getParams() as Record<string, Object>;
    if (params && params['keyword']) {
      const kw = params['keyword'] as string;
      this.keyword = kw;
      this.results = this.resourceService.searchResources(kw);
    }
  }

  searchByTag(tag: string): void {
    this.keyword = tag;
    this.results = this.resourceService.searchResources(tag);
    this.sortMode = 'default';
  }

  onSearch(value: string): void {
    this.keyword = value;
    if (!value.trim()) {
      this.results = [];
      this.sortMode = 'default';
    } else {
      this.results = this.resourceService.searchResources(value);
    }
  }

  getSortedResults(): ResourceItemModel[] {
    if (this.sortMode === 'name') {
      return [...this.results].sort((a, b) => a.title.localeCompare(b.title));
    } else if (this.sortMode === 'rating') {
      return [...this.results].sort((a, b) => b.rating - a.rating);
    } else if (this.sortMode === 'date') {
      return [...this.results].sort((a, b) => b.publishDate.localeCompare(a.publishDate));
    }
    return this.results;
  }

  build() {
    Column() {
      // Search header
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })

        TextInput({ text: this.keyword, placeholder: '搜标签、标题、作者...' })
          .fontSize(14)
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ColorTokens.BG_INPUT)
          .borderRadius(20)
          .padding({ left: 12 })
          .margin({ left: 8, right: 12 })
          .onChange((value: string) => { this.onSearch(value); })

        if (this.keyword.length > 0) {
          Text('✕')
            .fontSize(18)
            .fontColor(ColorTokens.TEXT_HINT)
            .onClick(() => { this.onSearch(''); })
        }
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Tag cloud — always visible until keyword entered
          if (!this.keyword.trim() && this.popularTags.length > 0) {
            Row() {
              Text('🏷️ 热门标签').fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.TEXT_PRIMARY)
            }.width('100%').padding({ left: 16, top: 16 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.popularTags, (item: TagCount) => {
                Text(item.tag)
                  .fontSize(12)
                  .fontColor(ColorTokens.PRIMARY)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                  .borderRadius(14)
                  .margin({ right: 8, top: 8 })
                  .onClick(() => { this.searchByTag(item.tag); })
              })
            }.width('100%').padding({ left: 16, right: 16, bottom: 12 })
          }

          // Empty state
          if (this.keyword.trim().length === 0) {
            Column() {
              Text('🔍').fontSize(48).margin({ top: 60 })
              Text('搜索资源、标签、作者').fontSize(16)
                .fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
              Text('直接点击上方标签即可快速检索').fontSize(13)
                .fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
            }.width('100%')
          } else if (this.results.length === 0) {
            Column() {
              Text('😔').fontSize(48).margin({ top: 60 })
              Text('未找到「' + this.keyword + '」相关资源').fontSize(16)
                .fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
              Text('试试其他关键词或点击热门标签').fontSize(13)
                .fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
            }.width('100%')
          } else {
            // Results count
            Row() {
              Text('找到 ' + this.results.length.toString() + ' 个结果').fontSize(13)
                .fontColor(ColorTokens.TEXT_HINT)
              Blank()
              Text('标签: ' + this.keyword).fontSize(11)
                .fontColor(ColorTokens.PRIMARY)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                .borderRadius(8)
            }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 4 })

            // Sort chips
            Row() {
              SortChip({ label: '默认', active: this.sortMode === 'default',
                onSort: () => { this.sortMode = 'default'; } })
              SortChip({ label: '按名称', active: this.sortMode === 'name',
                onSort: () => { this.sortMode = 'name'; } })
              SortChip({ label: '按评分', active: this.sortMode === 'rating',
                onSort: () => { this.sortMode = 'rating'; } })
              SortChip({ label: '按时间', active: this.sortMode === 'date',
                onSort: () => { this.sortMode = 'date'; } })
            }
            .width('100%').padding({ left: 16, right: 16, bottom: 8 })

            List() {
              ForEach(this.getSortedResults(), (item: ResourceItemModel) => {
                ListItem() {
                  ResourceCard({
                    resource: item,
                    onTap: () => {
                      router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                    }
                  })
                }
              }, (item: ResourceItemModel) => item.id.toString())
            }
            .layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: ColorTokens.DIVIDER, startMargin: 76, endMargin: 16 })
          }

          Column().height(40)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(12)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.active ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => { this.onSort(); })
  }
}
