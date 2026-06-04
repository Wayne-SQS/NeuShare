import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { DataService } from '../services/DataService';
import { FavoriteService } from '../services/FavoriteService';
import { CategoryItem, BannerItem, ResourceItem } from '../models/ResourceModel';
import { BannerSwiper } from '../components/BannerSwiper';
import { CategoryCard } from '../components/CategoryCard';
import { SearchBar } from '../components/SearchBar';
import { ResourceCard } from '../components/ResourceCard';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State categories: CategoryItem[] = [];
  @State banners: BannerItem[] = [];
  @State popularResources: ResourceItem[] = [];
  @State favoriteCount: number = 0;
  @State historyCount: number = 0;
  private dataService: DataService = DataService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();

  async aboutToAppear(): Promise<void> {
    this.categories = this.dataService.getCategories();
    this.banners = this.dataService.getBanners();
    this.popularResources = this.dataService.getPopularResources(5);
    const context = getContext(this) as Context;
    await this.favoriteService.init(context);
    await this.loadStats();
  }

  onPageShow(): void {
    this.loadStats();
  }

  async loadStats(): Promise<void> {
    const favIds = await this.favoriteService.getFavoriteIds();
    this.favoriteCount = favIds.size;
    const historyIds = await this.favoriteService.getHistory();
    this.historyCount = historyIds.length;
  }

  build() {
    Tabs({ index: this.currentTab }) {
      TabContent() { this.homePage() }
        .tabBar(this.tab('首页', 0))

      TabContent() { this.categoryGrid() }
        .tabBar(this.tab('分类', 1))

      TabContent() { this.searchTab() }
        .tabBar(this.tab('搜索', 2))

      TabContent() { this.profileTab() }
        .tabBar(this.tab('我的', 3))
    }
    .barHeight(56)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => { this.currentTab = index; })
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.BG_PAGE)
    .animation({ curve: Curve.EaseOut, duration: 200 })
  }

  @Builder
  tab(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(index === this.currentTab ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
      if (index === this.currentTab) {
        Row()
          .width(16).height(3).borderRadius(2)
          .backgroundColor(ColorTokens.PRIMARY)
          .margin({ top: 4 })
      }
    }
    .width('25%').height(52).justifyContent(FlexAlign.Center)
  }

  // ── Home ────────────────────────────────────
  @Builder
  homePage() {
    Scroll() {
      Column() {
        // Search
        SearchBar({
          placeholder: '搜索学习资源...',
          onSearch: () => { router.pushUrl({ url: 'pages/SearchPage' }); }
        }).margin({ top: 8, left: 16, right: 16 })

        // Banner
        BannerSwiper({
          banners: this.banners,
          onBannerTap: (item: BannerItem) => {
            const catId = parseInt(item.linkValue);
            const cat = this.categories.find(c => c.id === catId);
            router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: catId, categoryTitle: cat?.title || '' } });
          }
        }).margin({ top: 12 })

        // Categories section
        Row() {
          Text('学习分类')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          Blank()
          Text('全部 ›')
            .fontSize(13).fontColor(ColorTokens.ACCENT)
            .onClick(() => { this.currentTab = 1; })
        }
        .width('100%').padding({ left: 16, right: 16 }).margin({ top: 24 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
          ForEach(this.categories, (item: CategoryItem) => {
            CategoryCard({
              category: item,
              onTap: () => {
                router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: item.id, categoryTitle: item.title } });
              }
            }).margin({ top: 8 })
          })
        }.width('100%').padding({ left: 8, right: 8 })

        // Popular section
        if (this.popularResources.length > 0) {
          Row() {
            Text('热门推荐')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          }
          .width('100%').padding({ left: 16, right: 16 }).margin({ top: 28, bottom: 4 })

          ForEach(this.popularResources, (item: ResourceItem) => {
            ResourceCard({
              resource: item,
              onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
            })
          })
        }

        // Model compare entry — glass card
        Row() {
          Row() {
            Text('🤖').fontSize(30)
            Column() {
              Text('AI模型价格对比')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('DeepSeek · Claude · GPT · 实时价格 + 四维评分')
                .fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })
            }.margin({ left: 14 })
            Blank()
            Text('查看 ›').fontSize(13).fontColor(ColorTokens.ACCENT)
          }
          .width('100%').padding(18)
          .backgroundColor('#FFFFFFF0').borderRadius(16)
          .margin({ left: 16, right: 16, top: 10 })
          .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: '#0A000000', radius: 16 })
          .scale({ x: 0.98, y: 0.98 })
          .animation({ curve: Curve.Spring, duration: 150 })
          .onClick(() => { router.pushUrl({ url: 'pages/ModelComparePage' }); })
        }.width('100%')

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }

  // ── Categories ──────────────────────────────
  @Builder
  categoryGrid() {
    Scroll() {
      Column() {
        Text('全部学习分类')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          .width('100%').padding({ left: 16, top: 16 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
          ForEach(this.categories, (item: CategoryItem) => {
            CategoryCard({
              category: item,
              onTap: () => {
                router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: item.id, categoryTitle: item.title } });
              }
            }).margin({ top: 8 })
          })
        }.width('100%').padding({ left: 8, right: 8 })

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }

  // ── Search ──────────────────────────────────
  @Builder
  searchTab() {
    Column() {
      SearchBar({
        placeholder: '搜索资源、标签、作者...',
        onSearch: () => { router.pushUrl({ url: 'pages/SearchPage' }); }
      }).margin({ top: 8, left: 16, right: 16 })

      Column() {
        Text('🔍').fontSize(48).margin({ top: 80 })
        Text('输入关键词搜索').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
        Text('支持搜索标题、标签、描述、作者').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
      }
      .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').layoutWeight(1)
  }

  // ── Profile ─────────────────────────────────
  @Builder
  profileTab() {
    Column() {
      Row() {
        Text('我的').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      }
      .width('100%').height(48).padding({ left: 16, right: 16 }).backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Avatar card
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(64).height(64).borderRadius(32).backgroundColor(ColorTokens.BG_AVATAR)
              Text('👤').fontSize(32)
            }
            Column() {
              Text('软件学院学子').fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('NEU Software College').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.margin({ left: 14 })
            Blank()
            Text('›').fontSize(22).fontColor(ColorTokens.TEXT_DISABLED)
          }
          .width('100%').padding(18)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 16 })
          .onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })

          // Stats
          Row() {
            Column() {
              Text(this.favoriteCount.toString()).fontSize(26).fontWeight(FontWeight.Bold).fontColor(ColorTokens.PRIMARY)
              Text('收藏').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.width('50%').onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })

            Column() {
              Text(this.historyCount.toString()).fontSize(26).fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
              Text('浏览记录').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.width('50%').onClick(() => { router.pushUrl({ url: 'pages/ProfilePage' }); })
          }
          .width('100%').padding(16)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 10 })

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
