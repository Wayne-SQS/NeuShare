import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { ResourceService, TagCount } from '../services/ResourceService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ArrayDataSource } from '../models/ArrayDataSource';
import { ResourceCard } from '../components/ResourceCard';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State results: ResourceItemModel[] = [];
  private resultsDataSource: ArrayDataSource<ResourceItemModel> = new ArrayDataSource();
  @State popularTags: TagCount[] = [];
  @State sortMode: SortMode = 'default';
  @State isSearching: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private resourceService: ResourceService = ResourceService.getInstance();

  // ── 响应式参数 ─────────────────────────────────────────
  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 640, lg: 780, xl: 920 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private titleFontSize(): number {
    return new BpType<number>({ sm: 18, md: 20, lg: 24, xl: 28 }).getValue(this.currentBreakpoint) ?? 18;
  }

  private bodyFontSize(): number {
    return new BpType<number>({ sm: 14, md: 16, lg: 18, xl: 20 }).getValue(this.currentBreakpoint) ?? 14;
  }

  private captionFontSize(): number {
    return new BpType<number>({ sm: 12, md: 13, lg: 15, xl: 17 }).getValue(this.currentBreakpoint) ?? 12;
  }

  private smallFontSize(): number {
    return new BpType<number>({ sm: 11, md: 12, lg: 14, xl: 16 }).getValue(this.currentBreakpoint) ?? 11;
  }

  private hintIconSize(): number {
    return new BpType<number>({ sm: 48, md: 60, lg: 72, xl: 84 }).getValue(this.currentBreakpoint) ?? 48;
  }

  private hintTitleSize(): number {
    return new BpType<number>({ sm: 16, md: 18, lg: 22, xl: 26 }).getValue(this.currentBreakpoint) ?? 16;
  }

  private hintDescSize(): number {
    return new BpType<number>({ sm: 13, md: 15, lg: 17, xl: 19 }).getValue(this.currentBreakpoint) ?? 13;
  }

  private headerHeight(): number {
    return new BpType<number>({ sm: 56, md: 60, lg: 64, xl: 68 }).getValue(this.currentBreakpoint) ?? 56;
  }

  aboutToAppear(): void {
    this.popularTags = this.resourceService.getLocalAllTags();
    // 优先从 router 参数读取（页面内跳转），fallback 从 AppStorage 读取（意图框架/小艺）
    const params = router.getParams() as Record<string, Object>;
    const kw = (params && params['keyword']) ? params['keyword'] as string :
      AppStorage.get<string>('searchKeyword') || '';
    // 清除 AppStorage 中的关键词，避免重复消费
    AppStorage.setOrCreate('searchKeyword', '');
    if (kw) {
      this.keyword = kw;
      this.doSearch(kw);
    }
  }

  async searchByTag(tag: string): Promise<void> {
    this.keyword = tag;
    this.sortMode = 'default';
    await this.doSearch(tag);
  }

  async onSearch(value: string): Promise<void> {
    this.keyword = value;
    if (!value.trim()) {
      this.results = [];
      this.sortMode = 'default';
    } else {
      await this.doSearch(value);
    }
  }

  async doSearch(kw: string): Promise<void> {
    this.isSearching = true;
    this.results = await this.resourceService.searchResources(kw);
    this.resultsDataSource.replaceAll(this.getSortedResults());
    this.isSearching = false;
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

  applySort(): void {
    this.resultsDataSource.replaceAll(this.getSortedResults());
  }

  build() {
    Column() {
      // Search header
      Row() {
        Text('←')
          .fontSize(this.titleFontSize())
          .fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })

        TextInput({ text: this.keyword, placeholder: '搜标签、标题、作者...' })
          .fontSize(this.bodyFontSize() + 2).fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .height(this.bodyFontSize() + 32)
          .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
          .borderRadius(24)
          .padding({ left: 14 })
          .margin({ left: 8, right: 12 })
          .onChange((value: string) => { this.onSearch(value); })

        if (this.keyword.length > 0) {
          Text('✕')
            .fontSize(this.bodyFontSize() + 4)
            .fontColor(ColorTokens.textHint(this.isDarkMode))
            .onClick(() => { this.onSearch(''); })
        }
      }
      .width('100%').height(this.headerHeight()).padding({ left: this.contentPadding(), right: this.contentPadding() })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          Column() {
          // Tag cloud — always visible until keyword entered
          if (!this.keyword.trim() && this.popularTags.length > 0) {
            Row() {
              Text('🏷️ 热门标签').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            }.width('100%').padding({ left: this.contentPadding(), top: 16 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.popularTags, (item: TagCount) => {
                Text(item.tag)
                  .fontSize(this.captionFontSize())
                  .fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  .borderRadius(14)
                  .margin({ right: 8, top: 8 })
                  .onClick(() => { this.searchByTag(item.tag); })
              })
            }.width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), bottom: 12 })
          }

          // Empty state
          if (this.keyword.trim().length === 0) {
            Column() {
              Text('🔍').fontSize(this.hintIconSize()).margin({ top: 60 })
              Text('搜索资源、标签、作者').fontSize(this.hintTitleSize())
                .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
              Text('直接点击上方标签即可快速检索').fontSize(this.hintDescSize())
                .fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
            }.width('100%')
          } else if (this.results.length === 0) {
            Column() {
              Text('😔').fontSize(this.hintIconSize()).margin({ top: 60 })
              Text('未找到「' + this.keyword + '」相关资源').fontSize(this.hintTitleSize())
                .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
              Text('试试其他关键词或点击热门标签').fontSize(this.hintDescSize())
                .fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
            }.width('100%')
          } else {
            // Results count
            Row() {
              Text('找到 ' + this.results.length.toString() + ' 个结果').fontSize(this.captionFontSize())
                .fontColor(ColorTokens.textHint(this.isDarkMode))
              Blank()
              Text('标签: ' + this.keyword).fontSize(this.smallFontSize())
                .fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                .borderRadius(8)
            }.width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), top: 12, bottom: 4 })

            // Sort chips
            Row() {
              SortChip({ label: '默认', active: this.sortMode === 'default',
                onSort: () => { this.sortMode = 'default'; this.applySort(); } })
              SortChip({ label: '按名称', active: this.sortMode === 'name',
                onSort: () => { this.sortMode = 'name'; this.applySort(); } })
              SortChip({ label: '按评分', active: this.sortMode === 'rating',
                onSort: () => { this.sortMode = 'rating'; this.applySort(); } })
              SortChip({ label: '按时间', active: this.sortMode === 'date',
                onSort: () => { this.sortMode = 'date'; this.applySort(); } })
            }
            .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), bottom: 8 })

            Grid() {
              LazyForEach(this.resultsDataSource, (item: ResourceItemModel) => {
                GridItem() {
                  ResourceCard({
                    resource: item,
                    onTap: () => {
                      router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                    }
                  })
                }
              }, (item: ResourceItemModel) => item.id.toString())
            }
            .columnsTemplate(new BpType<string>({ sm: '1fr', md: '1fr 1fr', lg: '1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr')
            .rowsGap(12)
            .columnsGap(12)
            .layoutWeight(1)
          }

          Column().height(40)
          }
          .constraintSize({ maxWidth: this.maxContentWidth() })
          .width('100%')
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(new BpType<number>({ sm: 12, md: 13, lg: 14, xl: 15 }).getValue(this.currentBreakpoint) ?? 12)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textHint(this.isDarkMode))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => { this.onSort(); })
  }
}
