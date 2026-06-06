import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Entry
@Component
struct CategoryPage {
  private filterTags: string[] = ['学科', '考研', '期末速成'];
  @State resources: ResourceItemModel[] = [];
  @State categoryTitle: string = '';
  @State categoryDesc: string = '';
  @State filterTag: string = '';
  @State showFilters: boolean = false;
  @State searchKeyword: string = '';
  @State sortMode: SortMode = 'default';
  private categoryId: number = 1;
  private resourceService: ResourceService = ResourceService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.categoryId = params['categoryId'] as number;
      this.categoryTitle = params['categoryTitle'] as string;
    }
    const cat = this.resourceService.getCategoryById(this.categoryId);
    if (cat) {
      this.categoryDesc = cat.description;
    }
    this.resources = this.resourceService.getResourcesByCategory(this.categoryId);
    this.checkFilters();
  }

  checkFilters(): void {
    this.showFilters = this.resources.some(r =>
      r.tags.some(t => t === '学科' || t === '考研' || t === '期末速成')
    );
    if (this.showFilters && !this.filterTag) {
      this.filterTag = '学科';
    }
  }

  getFilteredResources(): ResourceItemModel[] {
    let result = this.resources;
    // Tag filter
    if (this.filterTag) {
      result = result.filter(r => r.tags.includes(this.filterTag));
    }
    // Search
    if (this.searchKeyword.trim()) {
      const kw = this.searchKeyword.toLowerCase().trim();
      result = result.filter(r =>
        r.title.toLowerCase().includes(kw) ||
        r.tags.some(t => t.toLowerCase().includes(kw)) ||
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
      // Header
      Row() {
        Text('←')
          .fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Column() {
          Text(this.categoryTitle)
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          if (this.categoryDesc) {
            Text(this.categoryDesc)
              .fontSize(11).fontColor(ColorTokens.TEXT_HINT).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }.layoutWeight(1).margin({ left: 12, right: 8 }).alignItems(HorizontalAlign.Start)
        Text(this.getFilteredResources().length.toString() + '个')
          .fontSize(13).fontColor(ColorTokens.TEXT_HINT)
      }
      .width('100%').height(52).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      // Search bar
      Row() {
        Text('🔍').fontSize(14)
        TextInput({ text: this.searchKeyword, placeholder: '搜索' + this.categoryTitle + '资源...' })
          .fontSize(13).layoutWeight(1).height(36)
          .backgroundColor('#00000000')
          .padding({ left: 8 })
          .onChange((value: string) => { this.searchKeyword = value; })
        if (this.searchKeyword) {
          Text('✕').fontSize(14).fontColor(ColorTokens.TEXT_HINT)
            .onClick(() => { this.searchKeyword = ''; })
        }
      }
      .width('100%').height(44).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_INPUT)
      .borderRadius(22)
      .margin({ left: 16, right: 16, top: 10 })

      // Sort + filter row
      Row() {
        // Sort chips
        Scroll() {
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
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1)

        // Tag filter pills — only show if category has tagged resources
        if (this.showFilters && this.filterTags.length > 0) {
          Row() {
            ForEach(this.filterTags, (tag: string) => {
              Text(tag === '学科' ? '学科' : tag === '考研' ? '考研' : '期末速成')
                .fontSize(11).fontWeight(this.filterTag === tag ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.filterTag === tag ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_PRIMARY)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor(this.filterTag === tag ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
                .borderRadius(16)
                .margin({ left: 6 })
                .onClick(() => { this.filterTag = tag; })
            })
            if (this.filterTag) {
              Text('全部')
                .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
                .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                .border({ width: 1, color: ColorTokens.DIVIDER, radius: 14 })
                .margin({ left: 6 })
                .onClick(() => { this.filterTag = ''; })
            }
          }
        }
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 6 })

      // Content
      if (this.getFilteredResources().length === 0) {
        Column() {
          Text(this.searchKeyword ? '🔍' : '📭').fontSize(48).margin({ top: 80 })
          Text(this.searchKeyword ? '未找到「' + this.searchKeyword + '」相关资源' :
            (this.filterTag ? '该分类下暂无匹配资源' : '暂无资源'))
            .fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
          Text(this.searchKeyword ? '试试其他关键词' :
            (this.filterTag ? '试试切换其他筛选条件' : '该分类下暂无资源，敬请期待'))
            .fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.getFilteredResources(), (item: ResourceItemModel) => {
            ListItem() {
              ResourceCard({
                resource: item,
                onTap: () => {
                  router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                }
              })
            }
          })
        }
        .layoutWeight(1).divider({ strokeWidth: 0 })
        .margin({ top: 4 })
      }
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
