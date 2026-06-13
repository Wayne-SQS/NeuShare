import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum, AppTheme, ThemeMode } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { CommunityService } from '../services/CommunityService';
import { Post } from '../models/PostModel';
import { CategoryItem, BannerItem } from '../models/ResourceModel';
import { CurriculumCourse, CurriculumService } from '../services/CurriculumService';
import { AuthApi } from '../api/AuthApi';
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
  @State sidebarCollapsed: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private resourceService: ResourceService = ResourceService.getInstance();
  private curriculumService: CurriculumService = CurriculumService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();
  private authApi: AuthApi = new AuthApi();
  private authStore: AuthStore = AuthStore.getInstance();

  async aboutToAppear(): Promise<void> {
    this.categories = this.resourceService.getLocalCategories();
    this.banners = this.resourceService.getLocalBanners();
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.communityService.init(context);
    await this.authStore.init(context);
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
    if (this.userGrade) {
      this.courseRecommendations = this.curriculumService.getCourseRecommendations(this.userGrade, 6);
    }
  }

  async loadRecommendedPost(): Promise<void> {
    this.recommendedPost = await this.communityService.getRecommendedPost();
  }

  async buildBannerList(): Promise<void> {
    const hotPosts = await this.communityService.getHotPosts(3);
    const postBanners: BannerItem[] = [];
    for (let i = 0; i < hotPosts.length; i++) {
      const p = hotPosts[i];
      const banner: BannerItem = {
        id: 9000 + i, title: p.title,
        subtitle: p.author + ' · 👍' + p.likes + ' ⭐' + p.favorites + ' 💬' + p.commentsCount,
        emoji: '🔥', gradientStart: ColorTokens.primary(this.isDarkMode), gradientEnd: ColorTokens.ACCENT_PINK_LIGHT,
        imageUrl: '', linkType: 'post', linkValue: p.id
      };
      postBanners.push(banner);
    }
    this.allBanners = [...this.banners, ...postBanners];
  }

  private sidebarWidth(): number {
    if (this.sidebarCollapsed) {
      return 64;
    }
    return new BpType<number>({ sm: 0, md: 64, lg: 200, xl: 240 }).getValue(this.currentBreakpoint) ?? 0;
  }

  private sidebarShowLabels(): boolean {
    if (this.sidebarCollapsed) {
      return false;
    }
    return this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  private isLargeScreen(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.MD ||
           this.currentBreakpoint === BreakpointTypeEnum.LG ||
           this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  build() {
    if (!this.isLargeScreen()) {
      // ─── 手机：底部 Tab 栏 ───
      Stack() {
        Tabs({ index: this.currentTab }) {
          TabContent() { HomeTab({
            categories: this.categories, allBanners: this.allBanners,
            courseRecommendations: this.courseRecommendations,
            userGrade: this.userGrade, recommendedPost: this.recommendedPost
          }) }.tabBar(this.mobileTab('首页', 0))

          TabContent() { CategoryTab({ categories: this.categories }) }
            .tabBar(this.mobileTab('分类', 1))

          TabContent() { SearchTab() }
            .tabBar(this.mobileTab('搜索', 2))

          TabContent() { ProfileTab({ favoriteCount: this.favoriteCount, historyCount: this.historyCount }) }
            .tabBar(this.mobileTab('我的', 3))
        }
        .barHeight(56).barMode(BarMode.Fixed).barPosition(BarPosition.End)
        .onChange((index: number) => { this.currentTab = index; })
        .width('100%').height('100%')
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
        .animation({ curve: Curve.EaseOut, duration: 200 })

        // Floating upload button
        Column() {
          Text('+').fontSize(28).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE).fontWeight(FontWeight.Bold)
        }
        .width(52).height(52).borderRadius(26)
        .backgroundColor(ColorTokens.primary(this.isDarkMode))
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .shadow({ radius: 8, color: ColorTokens.SHADOW_MEDIUM, offsetY: 4 })
        .position({ x: '80%', y: '85%' })
        .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
      }
      .width('100%').height('100%')
    } else {
      // ─── 平板/PC：侧边栏导航 ───
      Row() {
        // 左侧导航栏
        Column() {
          // Logo / Title + 收起按钮
          Row() {
            Text('📚').fontSize(new BpType<number>({ md: 22, lg: 28, xl: 32 }).getValue(this.currentBreakpoint) ?? 22)
            if (this.sidebarShowLabels()) {
              Text('NeU Share').fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 8 })
              Text('学习资源共享').fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
            }
            Blank()
            // 收起/展开按钮
            Text(this.sidebarCollapsed ? '»' : '«')
              .fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode))
              .padding(6).borderRadius(8)
              .onClick(() => { this.sidebarCollapsed = !this.sidebarCollapsed; })
          }
          .width('100%').padding({ top: 16, bottom: 12, left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)

          // Navigation items
          Column() {
            this.SidebarItem('🏠', '首页', 0)
            this.SidebarItem('📂', '分类', 1)
            this.SidebarItem('🔍', '搜索', 2)
            this.SidebarItem('👤', '我的', 3)
          }.layoutWeight(1)

          // 底部：主题切换 + 上传按钮
          Column() {
            // 主题切换
            Row() {
              Text(this.isDarkMode ? '☀️' : '🌙').fontSize(18)
              if (this.sidebarShowLabels()) {
                Text(this.isDarkMode ? '亮色模式' : '深色模式').fontSize(12)
                  .fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 8 })
              }
            }
            .width('100%').height(40)
            .padding({ left: this.sidebarShowLabels() ? 16 : 0 })
            .justifyContent(this.sidebarShowLabels() ? FlexAlign.Start : FlexAlign.Center)
            .borderRadius(10).margin({ left: 8, right: 8, bottom: 8 })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
            .onClick(() => {
              AppTheme.getInstance().setThemeMode(this.isDarkMode ? ThemeMode.LIGHT : ThemeMode.DARK);
            })

            // Upload button
            Button('+ 上传资源')
              .fontSize(12).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
              .backgroundColor(ColorTokens.primary(this.isDarkMode))
              .borderRadius(20).height(40)
              .width(new BpType<Length>({ md: 44, lg: '100%', xl: '100%' }).getValue(this.currentBreakpoint) ?? 44)
              .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
          }
          .width('100%').padding({ bottom: 16, left: 10, right: 10 })
        }
        .width(this.sidebarWidth()).height('100%')
        .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
        .border({ width: { right: 1 }, color: ColorTokens.divider(this.isDarkMode) })

        // 右侧内容区
        Tabs({ index: this.currentTab }) {
          TabContent() { HomeTab({
            categories: this.categories, allBanners: this.allBanners,
            courseRecommendations: this.courseRecommendations,
            userGrade: this.userGrade, recommendedPost: this.recommendedPost
          }) }

          TabContent() { CategoryTab({ categories: this.categories }) }

          TabContent() { SearchTab() }

          TabContent() { ProfileTab({ favoriteCount: this.favoriteCount, historyCount: this.historyCount }) }
        }
        .barHeight(0)
        .onChange((index: number) => { this.currentTab = index; })
        .width('100%').height('100%')
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
        .animation({ curve: Curve.EaseOut, duration: 200 })
      }
      .width('100%').height('100%')
    }
  }

  @Builder
  SidebarItem(icon: string, label: string, index: number) {
    Row() {
      Text(icon).fontSize(20)
      if (this.sidebarShowLabels()) {
        Text(label).fontSize(14)
          .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === index ? (this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode)) : ColorTokens.textPrimary(this.isDarkMode))
          .margin({ left: 8 })
      }
    }
    .width('100%').height(48)
    .padding({ left: this.sidebarShowLabels() ? 16 : 0, right: 4 })
    .justifyContent(this.sidebarShowLabels() ? FlexAlign.Start : FlexAlign.Center)
    .borderRadius(12)
    .margin({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(this.currentTab === index ? ColorTokens.accentLight(this.isDarkMode) : '#00000000')
    .onClick(() => { this.currentTab = index; })
  }

  @Builder
  mobileTab(label: string, index: number) {
    Column() {
      Text(label).fontSize(12)
        .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(index === this.currentTab ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
      if (index === this.currentTab) {
        Row().width(16).height(3).borderRadius(2)
          .backgroundColor(ColorTokens.primary(this.isDarkMode)).margin({ top: 4 })
      }
    }.width('25%').height(52).justifyContent(FlexAlign.Center)
  }
}
