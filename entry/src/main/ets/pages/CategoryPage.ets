import router from '@ohos.router';
import { ColorTokens, BreakpointTypeEnum, FontScale, Radii, Spacing, ControlSize, Elevation, GridLayout, PageHeader, EmptyState, StateView, ViewState } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Entry
@Component
struct CategoryPage {
  @State filterTags: string[] = [];
  @State resources: ResourceItemModel[] = [];
  @State categoryTitle: string = '';
  @State categoryDesc: string = '';
  @State filterTag: string = '';
  @State showFilters: boolean = false;
  @State searchKeyword: string = '';
  @State sortMode: SortMode = 'default';
  @State isLoading: boolean = false;
  @State loadFailed: boolean = false;
  @State totalCount: number = 0;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('topSafeAreaVp') topSafeArea: number = 0;
  private categoryId: number = 1;
  private resourceService: ResourceService = ResourceService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.categoryId = params['categoryId'] as number;
      this.categoryTitle = params['categoryTitle'] as string;
    }
    const cat = this.resourceService.getLocalCategoryById(this.categoryId);
    if (cat) {
      this.categoryDesc = cat.description;
    }
    // 先加载本地数据
    this.resources = this.resourceService.getLocalResourcesByCategory(this.categoryId);
    this.checkFilters();
    // 再从后端加载
    this.loadFromApi();
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  async loadFromApi(): Promise<void> {
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const result = await this.resourceService.fetchResourcesByCategory(this.categoryId, 1, 100);
      this.resources = result.items;
      this.totalCount = result.total;
      this.checkFilters();
    } catch (e) {
      console.error('loadFromApi failed: ' + JSON.stringify(e));
      // 已有本地兜底数据时不打断浏览，仅标记失败以便重试
      this.loadFailed = this.resources.length === 0;
    }
    this.isLoading = false;
  }

  checkFilters(): void {
    // 从当前资源中动态收集所有标签，按出现频率排序
    const tagCount: Record<string, number> = {};
    for (let i = 0; i < this.resources.length; i++) {
      const r = this.resources[i];
      if (r.tags && r.tags.length > 0) {
        for (let j = 0; j < r.tags.length; j++) {
          const t = r.tags[j];
          tagCount[t] = (tagCount[t] || 0) + 1;
        }
      }
    }
    let sorted = Object.keys(tagCount).sort((a, b) => tagCount[b] - tagCount[a]);
    // 降级：如果当前资源没有标签，使用全局标签列表
    if (sorted.length === 0) {
      const globalTags = this.resourceService.getLocalAllTags();
      sorted = globalTags.map(t => t.tag);
    }
    this.filterTags = sorted;
    this.showFilters = sorted.length > 0;
    // 默认选中出现频率最高的标签
    if (this.showFilters && !this.filterTag) {
      this.filterTag = sorted[0];
    }
  }

  getFilteredResources(): ResourceItemModel[] {
    let result = this.resources;
    // Tag filter
    if (this.filterTag) {
      result = result.filter(r => r.tags && r.tags.includes(this.filterTag));
    }
    // Search
    if (this.searchKeyword.trim()) {
      const kw = this.searchKeyword.toLowerCase().trim();
      result = result.filter(r =>
        r.title.toLowerCase().includes(kw) ||
        (r.tags && r.tags.some(t => t.toLowerCase().includes(kw))) ||
        r.description.toLowerCase().includes(kw) ||
        r.author.toLowerCase().includes(kw)
      );
    }
    // Sort
    if (this.sortMode === 'name') {
      result = [...result].sort((a, b) => a.title.localeCompare(b.title));
    } else if (this.sortMode === 'rating') {
      result = [...result].sort((a, b) => b.rating - a.rating);
    } else if (this.sortMode === 'date') {
      result = [...result].sort((a, b) => b.publishDate.localeCompare(a.publishDate));
    }
    return result;
  }

  build() {
    Column() {
      PageHeader({
        title: this.categoryTitle,
        subtitle: this.categoryDesc,
        actionText: this.getFilteredResources().length.toString() + ' 个'
      })

      // Search bar
      Row() {
        TextInput({ text: this.searchKeyword, placeholder: '搜索' + this.categoryTitle + '资源...' })
          .fontSize(FontScale.CAPTION).layoutWeight(1).height(ControlSize.BUTTON)
          .backgroundColor(ColorTokens.TRANSPARENT)
          .padding({ left: Spacing.SM })
          .onChange((value: string) => { this.searchKeyword = value; })
        if (this.searchKeyword) {
          Text('清除').fontSize(FontScale.CAPTION).fontColor(ColorTokens.textHint(this.isDarkMode))
            .height(ControlSize.TOUCH).padding({ left: Spacing.SM, right: Spacing.SM })
            .textAlign(TextAlign.Center)
            .onClick(() => { this.searchKeyword = ''; })
        }
      }
      .width('100%').height(ControlSize.INPUT).padding({ left: Spacing.MD, right: Spacing.MD })
      .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(Radii.INPUT)
      .margin({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })

      // Sort + tag filters
      Scroll() {
        Row() {
          SortChip({ label: '默认', active: this.sortMode === 'default', onSort: () => { this.sortMode = 'default'; } })
          SortChip({ label: '按名称', active: this.sortMode === 'name', onSort: () => { this.sortMode = 'name'; } })
          SortChip({ label: '按评分', active: this.sortMode === 'rating', onSort: () => { this.sortMode = 'rating'; } })
          SortChip({ label: '按时间', active: this.sortMode === 'date', onSort: () => { this.sortMode = 'date'; } })

          if (this.showFilters && this.filterTags.length > 0) {
            ForEach(this.filterTags, (tag: string, idx: number) => {
              Text(tag)
                .fontSize(FontScale.MICRO).fontWeight(this.filterTag === tag ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.filterTag === tag ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                .backgroundColor(this.filterTag === tag ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                .borderRadius(Radii.SM)
                .margin({ right: Spacing.SM })
                .onClick(() => { this.filterTag = tag; })
            }, (tag: string, idx: number) => 'ftag_' + idx.toString())
            if (this.filterTag) {
              Text('全部')
                .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
                .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.SM })
                .margin({ right: Spacing.SM })
                .onClick(() => { this.filterTag = ''; })
            }
          }
        }
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      .width('100%').padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM, bottom: Spacing.SM })

      // Content
      if (this.isLoading && this.resources.length === 0) {
        StateView({ state: ViewState.LOADING, message: '正在加载资源' }).layoutWeight(1)
      } else if (this.loadFailed) {
        StateView({
          state: ViewState.ERROR,
          message: '资源加载失败',
          hint: '请检查网络后重试',
          onRetry: () => { this.loadFromApi(); }
        }).layoutWeight(1)
      } else if (this.getFilteredResources().length === 0) {
        EmptyState({
          message: this.searchKeyword ? '未找到「' + this.searchKeyword + '」相关资源' :
            (this.filterTag ? '该分类下暂无匹配资源' : '暂无资源'),
          hint: this.searchKeyword ? '试试其他关键词' :
            (this.filterTag ? '试试切换其他筛选条件' : '该分类下暂无资源，敬请期待')
        }).layoutWeight(1)
      } else {
        Scroll() {
          GridRow({
            columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
            gutter: { x: Spacing.MD, y: Spacing.MD },
            breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
          }) {
            ForEach(this.getFilteredResources(), (item: ResourceItemModel) => {
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
          .width('100%').padding({ left: Spacing.PAGE, right: Spacing.PAGE, bottom: Spacing.HUGE })
        }
        .width('100%').layoutWeight(1).align(Alignment.Top)
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .padding({ top: this.topSafeArea })
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
      .fontSize(FontScale.LABEL)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(Radii.SM)
      .margin({ right: 8 })
      .onClick(() => { this.onSort(); })
  }
}
