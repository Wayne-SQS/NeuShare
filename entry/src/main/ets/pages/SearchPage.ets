import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, FontScale, Radii, Spacing, ControlSize, Elevation, GridLayout, StateView, ViewState } from '@neushare/common';
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
  @State isSearching: boolean = false;
  @State loadFailed: boolean = false;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('topSafeAreaVp') topSafeArea: number = 0;
  private resourceService: ResourceService = ResourceService.getInstance();

  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 576, lg: 656, xl: 900 }).getValue(this.currentBreakpoint) ?? 9999;
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
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
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
    this.loadFailed = false;
    try {
      this.results = await this.resourceService.searchResources(kw);
    } catch (e) {
      console.error('[SearchPage] search failed: ' + JSON.stringify(e));
      this.results = [];
      this.loadFailed = true;
    }
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

  @Builder
  SearchHeader() {
    Row() {
      Text('返回')
        .fontSize(FontScale.BODY_SM)
        .fontColor(ColorTokens.textSecondary(this.isDarkMode))
        .height(ControlSize.TOUCH)
        .onClick(() => { router.back(); })

      TextInput({ text: this.keyword, placeholder: '搜标签、标题、作者...' })
        .fontSize(FontScale.BODY_SM)
        .layoutWeight(1)
        .height(ControlSize.INPUT)
        .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
        .borderRadius(Radii.INPUT)
        .padding({ left: Spacing.MD })
        .margin({ left: Spacing.SM, right: Spacing.SM })
        .onChange((value: string) => { this.onSearch(value); })

      if (this.keyword.length > 0) {
        Text('清除')
          .fontSize(FontScale.CAPTION)
          .fontColor(ColorTokens.textHint(this.isDarkMode))
          .height(ControlSize.TOUCH)
          .onClick(() => { this.onSearch(''); })
      }
    }
    .width('100%')
    .height(ControlSize.HEADER)
    .padding({ left: Spacing.MD, right: Spacing.PAGE })
    .backgroundColor(ColorTokens.surface(this.isDarkMode))
    .border({ width: { bottom: Elevation.BORDER_WIDTH }, color: ColorTokens.border(this.isDarkMode) })
  }

  build() {
    Column() {
      this.SearchHeader()

      Scroll() {
        Column() {
          // 热门标签：未输入关键词时展示
          if (!this.keyword.trim() && this.popularTags.length > 0) {
            Column() {
              Text('热门标签')
                .fontSize(FontScale.SECTION)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .width('100%')
                .padding({ top: Spacing.XL, bottom: Spacing.SM })

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.popularTags, (item: TagCount, idx: number) => {
                  Text(item.tag)
                    .fontSize(FontScale.CAPTION)
                    .fontColor(ColorTokens.textSecondary(this.isDarkMode))
                    .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                    .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
                    .borderRadius(Radii.SM)
                    .margin({ right: Spacing.SM, top: Spacing.SM })
                    .onClick(() => { this.searchByTag(item.tag); })
                }, (item: TagCount, idx: number) => 'ptag_' + idx.toString())
              }
              .width('100%')
              .padding({ bottom: Spacing.MD })
            }
            .width('100%')
            .padding({ left: Spacing.PAGE, right: Spacing.PAGE })
          }

          if (this.keyword.trim().length === 0) {
            StateView({ state: ViewState.EMPTY, message: '搜索资源、标签、作者', hint: '直接点击上方标签即可快速检索' })
          } else if (this.isSearching) {
            StateView({ state: ViewState.LOADING, message: '正在搜索' })
          } else if (this.loadFailed) {
            StateView({
              state: ViewState.ERROR,
              message: '搜索失败',
              hint: '请检查网络后重试',
              onRetry: () => { this.doSearch(this.keyword); }
            })
          } else if (this.results.length === 0) {
            StateView({
              state: ViewState.EMPTY,
              message: '未找到「' + this.keyword + '」相关资源',
              hint: '试试其他关键词或点击热门标签'
            })
          } else {
            Row() {
              Text('找到 ' + this.results.length.toString() + ' 个结果')
                .fontSize(FontScale.CAPTION)
                .fontColor(ColorTokens.textHint(this.isDarkMode))
              Blank()
              Text(this.keyword)
                .fontSize(FontScale.MICRO)
                .fontColor(ColorTokens.textSecondary(this.isDarkMode))
                .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
                .borderRadius(Radii.SM)
            }
            .width('100%')
            .padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.MD, bottom: Spacing.XS })

            Row() {
              SortChip({ label: '默认', active: this.sortMode === 'default', onSort: () => { this.sortMode = 'default'; } })
              SortChip({ label: '按名称', active: this.sortMode === 'name', onSort: () => { this.sortMode = 'name'; } })
              SortChip({ label: '按评分', active: this.sortMode === 'rating', onSort: () => { this.sortMode = 'rating'; } })
              SortChip({ label: '按时间', active: this.sortMode === 'date', onSort: () => { this.sortMode = 'date'; } })
            }
            .width('100%')
            .padding({ left: Spacing.PAGE, right: Spacing.PAGE, bottom: Spacing.SM })

            GridRow({
              columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
              gutter: { x: Spacing.MD, y: Spacing.MD },
              breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
            }) {
              ForEach(this.getSortedResults(), (item: ResourceItemModel) => {
                GridCol({ span: 1 }) {
                  ResourceCard({
                    resource: item,
                    onTap: () => {
                      router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                    }
                  })
                }
              }, (item: ResourceItemModel) => item.id.toString())
            }
            .width('100%')
            .padding({ left: Spacing.PAGE, right: Spacing.PAGE })
          }

          Column().height(Spacing.HUGE)
        }
        .width('100%')
        .constraintSize({ maxWidth: this.maxContentWidth() })
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
      .align(Alignment.Top)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%').height('100%')
    .padding({ top: this.topSafeArea })
    .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.9)
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(FontScale.CAPTION)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
      .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(Radii.SM)
      .margin({ right: Spacing.SM })
      .onClick(() => { this.onSort(); })
  }
}
