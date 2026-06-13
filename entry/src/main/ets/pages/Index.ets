import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
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
        emoji: '🔥', gradientStart: '#E74C3C', gradientEnd: '#C0392B',
        imageUrl: '', linkType: 'post', linkValue: p.id
      };
      postBanners.push(banner);
    }
    this.allBanners = [...this.banners, ...postBanners];
  }

  private sidebarWidth(): number {
    return new BpType<number>({ sm: 0, md: 64, lg: 200, xl: 240 }).getValue(this.currentBreakpoint) ?? 0;
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
        .backgroundColor(ColorTokens.BG_PAGE)
        .animation({ curve: Curve.EaseOut, duration: 200 })

        // Floating upload button
        Column() {
          Text('+').fontSize(28).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        }
        .width(52).height(52).borderRadius(26)
        .backgroundColor(ColorTokens.PRIMARY)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .shadow({ radius: 8, color: '#33000000', offsetY: 4 })
        .position({ x: '80%', y: '85%' })
        .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
      }
      .width('100%').height('100%')
    } else {
      // ─── 平板/PC：侧边栏导航 ───
      Row() {
        // 左侧导航栏
        Column() {
          // Logo / Title
          Column() {
            Text('📚').fontSize(new BpType<number>({ md: 22, lg: 28, xl: 32 }).getValue(this.currentBreakpoint) ?? 22)
            if (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
              Text('NeU Share').fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.TEXT_PRIMARY).margin({ top: 4 })
              Text('学习资源共享').fontSize(10).fontColor(ColorTokens.TEXT_HINT)
            }
          }
          .width('100%').padding({ top: 20, bottom: 20 })
          .alignItems(HorizontalAlign.Center)

          // Navigation items
          Column() {
            this.SidebarItem('🏠', '首页', 0)
            this.SidebarItem('📂', '分类', 1)
            this.SidebarItem('🔍', '搜索', 2)
            this.SidebarItem('👤', '我的', 3)
          }.layoutWeight(1)

          // Upload button
          Column() {
            Button('+ 上传资源')
              .fontSize(12).fontColor('#FFFFFF')
              .backgroundColor(ColorTokens.PRIMARY)
              .borderRadius(20).height(40)
              .width(new BpType<Length>({ md: 44, lg: '100%', xl: '100%' }).getValue(this.currentBreakpoint) ?? 44)
              .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
          }
          .width('100%').padding({ bottom: 16, left: 10, right: 10 })
        }
        .width(this.sidebarWidth()).height('100%')
        .backgroundColor(ColorTokens.BG_CARD)
        .border({ width: { right: 1 }, color: ColorTokens.DIVIDER })

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
        .backgroundColor(ColorTokens.BG_PAGE)
        .animation({ curve: Curve.EaseOut, duration: 200 })
      }
      .width('100%').height('100%')
    }
  }

  @Builder
  SidebarItem(icon: string, label: string, index: number) {
    Row() {
      Text(icon).fontSize(20)
      if (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
        Text(label).fontSize(14)
          .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === index ? ColorTokens.PRIMARY : ColorTokens.TEXT_PRIMARY)
          .margin({ left: 8 })
      }
    }
    .width('100%').height(48)
    .padding({ left: (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? 16 : 0, right: 4 })
    .justifyContent((this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? FlexAlign.Start : FlexAlign.Center)
    .borderRadius(12)
    .margin({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(this.currentTab === index ? ColorTokens.PRIMARY_LIGHT : '#00000000')
    .onClick(() => { this.currentTab = index; })
  }

  @Builder
  mobileTab(label: string, index: number) {
    Column() {
      Text(label).fontSize(12)
        .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(index === this.currentTab ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
      if (index === this.currentTab) {
        Row().width(16).height(3).borderRadius(2)
          .backgroundColor(ColorTokens.PRIMARY).margin({ top: 4 })
      }
    }.width('25%').height(52).justifyContent(FlexAlign.Center)
  }
}
