import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointTypeEnum, BlurPerformance, BreakpointSystem } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { CommunityService } from '../services/CommunityService';
import { Post } from '../models/PostModel';
import { CategoryItem, BannerItem } from '../models/ResourceModel';
import { CurriculumCourse, CurriculumService } from '../services/CurriculumService';
import { AuthApi } from '../api/AuthApi';
import { GradeService } from '../services/GradeService';
import { HomeTab } from './tabs/HomeTab';
import { CategoryTab } from './tabs/CategoryTab';
import { SearchTab } from './tabs/SearchTab';
import { ProfileTab } from './tabs/ProfileTab';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State categories: CategoryItem[] = [];
  @State banners: BannerItem[] = [];
  @State favoriteCount: number = 0;
  @State historyCount: number = 0;
  @State userGrade: string = '';
  @State courseRecommendations: CurriculumCourse[] = [];
  @State recommendedPost: Post | null = null;
  @State allBanners: BannerItem[] = [];
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private tabsController: TabsController = new TabsController();
  private resourceService: ResourceService = ResourceService.getInstance();
  private curriculumService: CurriculumService = CurriculumService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();
  private authApi: AuthApi = new AuthApi();
  private authStore: AuthStore = AuthStore.getInstance();
  private gradeService: GradeService = GradeService.getInstance();
  private breakpointSystem: BreakpointSystem = BreakpointSystem.getInstance();

  async aboutToAppear(): Promise<void> {
    // 对齐 QuickStart：在页面渲染后注册 mediaQuery 断点检测
    this.breakpointSystem.register();
    BlurPerformance.init();
    BlurPerformance.detectDeviceCapability();
    this.categories = this.resourceService.getLocalCategories();
    this.banners = this.resourceService.getLocalBanners();
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.authStore.init(context);
    await this.gradeService.init(context);
    await this.loadStats();
    await this.loadGradeData();
    await this.buildBannerList();
    this.refreshFromApi();
  }

  onPageShow(): void {
    this.loadStats();
    this.loadGradeData();
    this.loadRecommendedPost();
    this.buildBannerList();
    this.refreshFromApi();
  }

  async refreshFromApi(): Promise<void> {
    try {
      const results = await Promise.all([
        this.resourceService.fetchCategories(),
        this.resourceService.fetchBanners()
      ]);
      this.categories = results[0];
      this.banners = results[1];
      await this.buildBannerList();
    } catch (e) {
      console.error('refreshFromApi failed: ' + JSON.stringify(e));
    }
  }

  async loadStats(): Promise<void> {
    const favIds = await this.favoriteService.getFavoriteIds();
    this.favoriteCount = favIds.size;
    const historyIds = await this.favoriteService.getHistory();
    this.historyCount = historyIds.length;
  }

  async loadGradeData(): Promise<void> {
    const loggedIn = await this.authStore.isLoggedIn();
    if (loggedIn) {
      try {
        const resp = await this.authApi.getInfo();
        if (resp.code === 200 && resp.data) {
          const gradeNum: number = resp.data.grade || 0;
          const labels: string[] = ['', '大一', '大二', '大三', '大四'];
          this.userGrade = (gradeNum >= 1 && gradeNum <= 4) ? labels[gradeNum] : '';
        }
      } catch (e) {
        this.userGrade = '';
      }
    }
    // 兜底：后端年级为空时，从本地 GradeService 读取
    if (!this.userGrade) {
      try {
        const localGrade = await this.gradeService.getGrade();
        if (localGrade) {
          this.userGrade = localGrade;
        }
      } catch (e) {
        console.error('loadGradeData local fallback failed: ' + JSON.stringify(e));
      }
    }
    if (this.userGrade) {
      this.courseRecommendations = this.curriculumService.getCourseRecommendations(this.userGrade, 6);
    }
  }

  async loadRecommendedPost(): Promise<void> {
    this.recommendedPost = await this.communityService.getRecommendedPost();
  }

  async buildBannerList(): Promise<void> {
    this.allBanners = this.banners;
  }

  private isVerticalMode(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.LG ||
           this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  build() {
    Stack() {
      Tabs({
        barPosition: this.isVerticalMode() ? BarPosition.Start : BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          Column() {
            HomeTab({
              categories: this.categories, allBanners: this.allBanners,
              courseRecommendations: this.courseRecommendations,
              userGrade: this.userGrade, recommendedPost: this.recommendedPost
            })
          }
          .width('100%').height('100%')
        }.tabBar(this.tabBarBuilder('首页', 0, '🏠'))

        TabContent() {
          Column() {
            CategoryTab({ categories: this.categories })
          }
          .width('100%').height('100%')
        }.tabBar(this.tabBarBuilder('分类', 1, '📂'))

        TabContent() {
          Column() {
            SearchTab()
          }
          .width('100%').height('100%')
        }.tabBar(this.tabBarBuilder('搜索', 2, '🔍'))

        TabContent() {
          Column() {
            ProfileTab({ favoriteCount: this.favoriteCount, historyCount: this.historyCount })
          }
          .width('100%').height('100%')
        }.tabBar(this.tabBarBuilder('我的', 3, '👤'))
      }
      .vertical(this.isVerticalMode())
      .barWidth(this.isVerticalMode() ? 64 : undefined)
      .barHeight(this.isVerticalMode() ? undefined : 56)
      .barMode(this.isVerticalMode() ? BarMode.Fixed : BarMode.Fixed)
      .scrollable(false)
      .onChange((index: number) => { this.currentTab = index; })
      .width('100%').height('100%')
      .backgroundColor(ColorTokens.bgPage(this.isDarkMode))

      // ── 悬浮上传按钮（所有模式） ──
      Column() {
        Text('+').fontSize(28).fontColor(ColorTokens.TEXT_WHITE).fontWeight(FontWeight.Bold)
      }
      .width(52).height(52).borderRadius(26)
      .backgroundColor(ColorTokens.primary(this.isDarkMode))
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .shadow({ radius: 8, color: ColorTokens.SHADOW_MEDIUM, offsetY: 4 })
      .position({ x: this.isVerticalMode() ? '92%' : '80%', y: '85%' })
      .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
    }
    .width('100%').height('100%')
  }

  @Builder
  tabBarBuilder(label: string, index: number, icon: string) {
    Column() {
      Text(icon).fontSize(22)
      if (this.isVerticalMode()) {
        Text(label).fontSize(10)
          .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === index ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
          .margin({ top: 4 })
      } else {
        Text(label).fontSize(12)
          .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === index ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
          .margin({ top: 2 })
        if (this.currentTab === index) {
          Row().width(16).height(3).borderRadius(2)
            .backgroundColor(ColorTokens.primary(this.isDarkMode)).margin({ top: 3 })
        }
      }
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentTab = index;
      this.tabsController.changeIndex(index);
    })
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
