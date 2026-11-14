import router from '@ohos.router';
import { ColorTokens, BreakpointTypeEnum, FontScale, Radii, Spacing, Elevation, GridLayout, PageHeader, StateView, ViewState } from '@neushare/common';
import { StatsApi, StatsOverview, DistributionItem, TopResourceItem } from '../api/StatsApi';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct StatsPage {
  @State stats: StatsOverview | null = null;
  @State loading: boolean = true;
  @State loadError: boolean = false;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private statsApi: StatsApi = new StatsApi();

  async aboutToAppear(): Promise<void> {
    await this.loadStats();
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  async loadStats(): Promise<void> {
    this.loading = true;
    this.loadError = false;
    try {
      const resp = await this.statsApi.getOverview();
      if (resp.code === 200 && resp.data) {
        this.stats = resp.data;
      } else {
        this.loadError = true;
      }
    } catch (e) {
      console.error('loadStats failed: ' + JSON.stringify(e));
      this.loadError = true;
    }
    this.loading = false;
  }

  private maxCount(items: DistributionItem[]): number {
    if (items.length === 0) return 1;
    let max = 0;
    for (let i = 0; i < items.length; i++) {
      if (items[i].count > max) max = items[i].count;
    }
    return max;
  }

  build() {
    Column() {
      PageHeader({ title: '数据统计' })

      if (this.loading) {
        StateView({ state: ViewState.LOADING, message: '正在加载统计数据' })
          .layoutWeight(1)
      } else if (this.loadError || !this.stats) {
        StateView({
          state: ViewState.ERROR,
          message: '统计数据加载失败',
          hint: '请确认后端服务可用后重试',
          onRetry: () => { this.loadStats(); }
        }).layoutWeight(1)
      } else if (this.stats!.totalResources === 0) {
        StateView({
          state: ViewState.EMPTY,
          message: '暂无统计数据',
          hint: '有资源上传后这里会显示统计结果'
        }).layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // Overview cards
            GridRow({
              columns: { xs: 2, sm: 2, md: 3, lg: 3, xl: 6 },
              gutter: { x: Spacing.SM, y: Spacing.SM },
              breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
            }) {
              GridCol({ span: 1 }) { this.OverviewCard('资源', this.stats!.totalResources.toString()) }
              GridCol({ span: 1 }) { this.OverviewCard('用户', this.stats!.totalUsers.toString()) }
              GridCol({ span: 1 }) { this.OverviewCard('评论', this.stats!.totalComments.toString()) }
              GridCol({ span: 1 }) { this.OverviewCard('浏览', this.formatNumber(this.stats!.totalViews)) }
              GridCol({ span: 1 }) { this.OverviewCard('点赞', this.formatNumber(this.stats!.totalLikes)) }
              GridCol({ span: 1 }) { this.OverviewCard('收藏', this.formatNumber(this.stats!.totalFavorites)) }
            }
            .width('100%').padding({ left: Spacing.MD, right: Spacing.MD }).margin({ top: Spacing.MD })

            // Recent uploads & pending
            Row() {
              Column() {
                Text('近7天新增').fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
                Text(this.stats!.recentUploads.toString()).fontSize(FontScale.TITLE_MD).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.primary(this.isDarkMode)).margin({ top: 2 })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Center)
              Column() {
                Text('待审核').fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
                Text(this.stats!.pendingResources.toString()).fontSize(FontScale.TITLE_MD).fontWeight(FontWeight.Bold)
                  .fontColor(this.stats!.pendingResources > 0 ? ColorTokens.warning(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                  .margin({ top: 2 })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Center)
            }
            .width('100%').padding({ top: 14, bottom: 14 }).margin({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
            .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })

            // Category distribution
            if (this.stats!.categoryDistribution.length > 0) {
              this.SectionTitle('分类分布')
              Column() {
                ForEach(this.stats!.categoryDistribution, (item: DistributionItem, idx: number) => {
                  this.BarRow(item, this.maxCount(this.stats!.categoryDistribution))
                }, (item: DistributionItem, idx: number) => 'cdist_' + idx.toString())
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(Radii.CARD).border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD }).margin({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
            }

            // Type distribution
            if (this.stats!.typeDistribution.length > 0) {
              this.SectionTitle('类型分布')
              Column() {
                ForEach(this.stats!.typeDistribution, (item: DistributionItem, idx: number) => {
                  this.BarRowType(item, this.maxCount(this.stats!.typeDistribution))
                }, (item: DistributionItem, idx: number) => 'tdist_' + idx.toString())
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(Radii.CARD).border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD }).margin({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
            }

            // Source distribution
            if (this.stats!.sourceDistribution.length > 0) {
              this.SectionTitle('来源网站 Top 10')
              Column() {
                ForEach(this.stats!.sourceDistribution.slice(0, 10), (item: DistributionItem, idx: number) => {
                  this.BarRowSource(item, this.maxCount(this.stats!.sourceDistribution))
                }, (item: DistributionItem, idx: number) => 'sdist_' + idx.toString())
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(Radii.CARD).border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD }).margin({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
            }

            // Top 10 hot resources
            if (this.stats!.topResources.length > 0) {
              this.SectionTitle('热门资源 Top 10')
              Column() {
                ForEach(this.stats!.topResources, (item: TopResourceItem, index: number) => {
                  this.TopRow(item, index + 1)
                }, (item: TopResourceItem, index: number) => 'top_' + item.id.toString())
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(Radii.CARD).border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD }).margin({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM })
            }

            Column().height(40)
          }
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
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

  @Builder
  OverviewCard(label: string, value: string) {
    Column() {
      Text(value).fontSize(FontScale.TITLE_SM).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
      Text(label).fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: Spacing.XXS })
    }
    .width('100%').padding({ top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
    .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      .width('100%').padding({ left: Spacing.XXL, right: Spacing.XXL, top: Spacing.LG, bottom: Spacing.XS })
  }

  @Builder
  BarRow(item: DistributionItem, maxCount: number) {
    Row() {
      Text(item.name).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(70).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 140)).height(16)
        .borderRadius(Radii.MD)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.PURPLE, 1]] })
      Text(item.count.toString()).fontSize(FontScale.LABEL).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  BarRowType(item: DistributionItem, maxCount: number) {
    Row() {
      Text(this.typeLabel(item.name)).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(70).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 140)).height(16)
        .borderRadius(Radii.MD)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.SUCCESS_LIGHT, 1]] })
      Text(item.count.toString()).fontSize(FontScale.LABEL).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  BarRowSource(item: DistributionItem, maxCount: number) {
    Row() {
      Text(item.name).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(80).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 120)).height(16)
        .borderRadius(Radii.MD)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.warning(this.isDarkMode), 0], [ColorTokens.error(this.isDarkMode), 1]] })
      Text(item.count.toString()).fontSize(FontScale.LABEL).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  TopRow(item: TopResourceItem, rank: number) {
    Row() {
      Text(rank.toString())
        .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
        .fontColor(rank <= 3 ? (rank === 1 ? ColorTokens.warning(this.isDarkMode) : rank === 2 ? ColorTokens.textHint(this.isDarkMode) : ColorTokens.warning(this.isDarkMode)) : ColorTokens.textHint(this.isDarkMode))
        .width(24).textAlign(TextAlign.Center)
      Column() {
        Text(item.title).fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('浏览 ' + this.formatNumber(item.viewCount)).fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode))
          Text('赞 ' + this.formatNumber(item.likeCount)).fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 8 })
          Text('收藏 ' + this.formatNumber(item.favoriteCount)).fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 8 })
        }.margin({ top: 2 })
      }
      .layoutWeight(1).margin({ left: 8 })
    }
    .width('100%').padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: rank < 10 ? 1 : 0 }, color: ColorTokens.divider(this.isDarkMode) })
  }

  private typeLabel(type: string): string {
    const labels: Record<string, string> = {
      'document': '文档', 'video': '视频',
      'image': '图片', 'other': '其他',
      'tutorial': '教程', 'book': '书籍',
      'software': '软件'
    };
    return labels[type] || type;
  }

  private formatNumber(n: number): string {
    if (n >= 10000) return (n / 10000).toFixed(1) + 'w';
    if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
    return n.toString();
  }
}
