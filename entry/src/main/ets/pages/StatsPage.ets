import router from '@ohos.router';
import { ColorTokens, BreakpointTypeEnum } from '@neushare/common';
import { StatsApi, StatsOverview, DistributionItem, TopResourceItem } from '../api/StatsApi';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct StatsPage {
  @State stats: StatsOverview | null = null;
  @State loading: boolean = true;
  @State loadError: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private statsApi: StatsApi = new StatsApi();

  async aboutToAppear(): Promise<void> {
    await this.loadStats();
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
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('📊 数据统计').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 24, right: 24 }).backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36).color(ColorTokens.primary(this.isDarkMode))
          Text('加载数据...').fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.loadError || !this.stats) {
        Column() {
          Text('📭').fontSize(48)
          Text('加载失败').fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ top: 12 })
          Text('请确认后端服务已启动').fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 6 })
          Text('重试').fontSize(14).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE).fontWeight(FontWeight.Bold)
            .padding({ left: 24, right: 24, top: 10, bottom: 10 })
            .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(20).margin({ top: 20 })
            .onClick(() => { this.loadStats(); })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // Overview cards
            Row() {
              this.OverviewCard('📚', '资源', this.stats!.totalResources.toString())
              this.OverviewCard('👥', '用户', this.stats!.totalUsers.toString())
              this.OverviewCard('💬', '评论', this.stats!.totalComments.toString())
            }
            .width('100%').padding({ left: 12, right: 12 }).margin({ top: 12 })
            Row() {
              this.OverviewCard('👁️', '浏览', this.formatNumber(this.stats!.totalViews))
              this.OverviewCard('❤️', '点赞', this.formatNumber(this.stats!.totalLikes))
              this.OverviewCard('⭐', '收藏', this.formatNumber(this.stats!.totalFavorites))
            }
            .width('100%').padding({ left: 12, right: 12 })

            // Category distribution
            if (this.stats!.categoryDistribution.length > 0) {
              this.SectionTitle('📂 分类分布')
              Column() {
                ForEach(this.stats!.categoryDistribution, (item: DistributionItem) => {
                  this.BarRow(item, this.maxCount(this.stats!.categoryDistribution))
                })
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(14).margin({ left: 12, right: 12, top: 6 })
            }

            // Type distribution
            if (this.stats!.typeDistribution.length > 0) {
              this.SectionTitle('📝 类型分布')
              Column() {
                ForEach(this.stats!.typeDistribution, (item: DistributionItem) => {
                  this.BarRowType(item, this.maxCount(this.stats!.typeDistribution))
                })
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(14).margin({ left: 12, right: 12, top: 6 })
            }

            // Source distribution
            if (this.stats!.sourceDistribution.length > 0) {
              this.SectionTitle('🔗 来源网站 Top 10')
              Column() {
                const topSources = this.stats!.sourceDistribution.slice(0, 10);
                ForEach(topSources, (item: DistributionItem) => {
                  this.BarRowSource(item, this.maxCount(topSources))
                })
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(14).margin({ left: 12, right: 12, top: 6 })
            }

            // Top 10 hot resources
            if (this.stats!.topResources.length > 0) {
              this.SectionTitle('🔥 热门资源 Top 10')
              Column() {
                ForEach(this.stats!.topResources, (item: TopResourceItem, index: number) => {
                  this.TopRow(item, index + 1)
                })
              }
              .width('100%').padding(12).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .borderRadius(14).margin({ left: 12, right: 12, top: 6 })
            }

            Column().height(40)
          }
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }

  @Builder
  OverviewCard(emoji: string, label: string, value: string) {
    Column() {
      Text(emoji).fontSize(24)
      Text(value).fontSize(20).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ top: 4 })
      Text(label).fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
    }
    .layoutWeight(1).padding({ top: 14, bottom: 14 })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
    .margin({ left: 4, right: 4 }).alignItems(HorizontalAlign.Center)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      .width('100%').padding({ left: 24, right: 24, top: 18, bottom: 4 })
  }

  @Builder
  BarRow(item: DistributionItem, maxCount: number) {
    Row() {
      Text(item.name).fontSize(13).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(70).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 140)).height(16)
        .borderRadius(8)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.PURPLE, 1]] })
      Text(item.count.toString()).fontSize(12).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  BarRowType(item: DistributionItem, maxCount: number) {
    Row() {
      Text(this.typeLabel(item.name)).fontSize(13).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(70).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 140)).height(16)
        .borderRadius(8)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.SUCCESS_LIGHT, 1]] })
      Text(item.count.toString()).fontSize(12).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  BarRowSource(item: DistributionItem, maxCount: number) {
    Row() {
      Text(item.name).fontSize(13).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width(80).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row()
        .width(Math.max(4, (item.count / maxCount) * 120)).height(16)
        .borderRadius(8)
        .linearGradient({ direction: GradientDirection.Right,
          colors: [[ColorTokens.WARNING_LIGHT, 0], [ColorTokens.ERROR_LIGHT, 1]] })
      Text(item.count.toString()).fontSize(12).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  TopRow(item: TopResourceItem, rank: number) {
    Row() {
      Text(rank.toString())
        .fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(rank <= 3 ? (rank === 1 ? ColorTokens.WARNING_LIGHT : rank === 2 ? ColorTokens.textHint(this.isDarkMode) : ColorTokens.WARNING_LIGHT) : ColorTokens.textHint(this.isDarkMode))
        .width(24).textAlign(TextAlign.Center)
      Column() {
        Text(item.title).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('👁 ' + this.formatNumber(item.viewCount)).fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
          Text(' ❤ ' + this.formatNumber(item.likeCount)).fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
          Text(' ⭐ ' + this.formatNumber(item.favoriteCount)).fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
        }.margin({ top: 2 })
      }
      .layoutWeight(1).margin({ left: 8 })
    }
    .width('100%').padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: rank < 10 ? 1 : 0 }, color: ColorTokens.divider(this.isDarkMode) })
  }

  private typeLabel(type: string): string {
    const labels: Record<string, string> = {
      'document': '📄 文档', 'video': '🎬 视频',
      'image': '🖼️ 图片', 'other': '📦 其他',
      'tutorial': '📝 教程', 'book': '📖 书籍',
      'software': '💻 软件'
    };
    return labels[type] || type;
  }

  private formatNumber(n: number): string {
    if (n >= 10000) return (n / 10000).toFixed(1) + 'w';
    if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
    return n.toString();
  }
}
