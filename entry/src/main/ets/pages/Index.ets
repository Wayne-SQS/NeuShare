import { ColorTokens } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { GradeService } from '../services/GradeService';
import { CommunityService } from '../services/CommunityService';
import { Post } from '../models/PostModel';
import { CategoryItem, BannerItem } from '../models/ResourceModel';
import { CurriculumCourse, CurriculumService } from '../services/CurriculumService';
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
  private resourceService: ResourceService = ResourceService.getInstance();
  private curriculumService: CurriculumService = CurriculumService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private gradeService: GradeService = GradeService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();

  async aboutToAppear(): Promise<void> {
    this.categories = this.resourceService.getCategories();
    this.banners = this.resourceService.getBanners();
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.gradeService.init(context);
    await this.communityService.init(context);
    await this.loadStats();
    await this.loadGradeData();
    await this.buildBannerList();
  }

  onPageShow(): void {
    this.loadStats();
    this.loadGradeData();
    this.loadRecommendedPost();
    this.buildBannerList();
  }

  async loadStats(): Promise<void> {
    const favIds = await this.favoriteService.getFavoriteIds();
    this.favoriteCount = favIds.size;
    const historyIds = await this.favoriteService.getHistory();
    this.historyCount = historyIds.length;
  }

  async loadGradeData(): Promise<void> {
    const grade = await this.gradeService.getGrade();
    this.userGrade = grade;
    if (grade) {
      this.courseRecommendations = this.curriculumService.getCourseRecommendations(grade, 6);
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

  build() {
    Tabs({ index: this.currentTab }) {
      TabContent() { HomeTab({
        categories: this.categories, allBanners: this.allBanners,
        courseRecommendations: this.courseRecommendations,
        userGrade: this.userGrade, recommendedPost: this.recommendedPost
      }) }.tabBar(this.tab('首页', 0))

      TabContent() { CategoryTab({ categories: this.categories }) }
        .tabBar(this.tab('分类', 1))

      TabContent() { SearchTab() }
        .tabBar(this.tab('搜索', 2))

      TabContent() { ProfileTab({ favoriteCount: this.favoriteCount, historyCount: this.historyCount }) }
        .tabBar(this.tab('我的', 3))
    }
    .barHeight(56).barMode(BarMode.Fixed)
    .onChange((index: number) => { this.currentTab = index; })
    .width('100%').height('100%')
    .backgroundColor(ColorTokens.BG_PAGE)
    .animation({ curve: Curve.EaseOut, duration: 200 })
  }

  @Builder
  tab(label: string, index: number) {
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
