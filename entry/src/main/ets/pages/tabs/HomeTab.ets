import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { ResourceService } from '../../services/ResourceService';
import { CommunityService } from '../../services/CommunityService';
import { Post } from '../../models/PostModel';
import { CategoryItem, BannerItem, ResourceItem } from '../../models/ResourceModel';
import { CurriculumCourse } from '../../services/CurriculumService';
import { BannerSwiper } from '../../components/BannerSwiper';
import { SearchBar } from '../../components/SearchBar';
import { CourseRecommendCard } from '../../components/CourseRecommendCard';
import { ResourceCard } from '../../components/ResourceCard';

@Component
export struct HomeTab {
  @Prop categories: CategoryItem[] = [];
  @Prop allBanners: BannerItem[] = [];
  @Prop courseRecommendations: CurriculumCourse[] = [];
  @Prop userGrade: string = '';
  @Prop recommendedPost: Post | null = null;
  @Prop favoriteCount: number = 0;
  @Prop historyCount: number = 0;
  @State hotResources: ResourceItem[] = [];
  @State hotResourcesLoading: boolean = true;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSwitchTab?: (index: number) => void;
  private resourceService: ResourceService = ResourceService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.loadHotResources();
  }

  async loadHotResources(): Promise<void> {
    this.hotResourcesLoading = true;
    try {
      this.hotResources = await this.resourceService.fetchHotResources(8);
    } catch (e) {
      console.error('loadHotResources failed: ' + JSON.stringify(e));
    }
    this.hotResourcesLoading = false;
  }

  build() {
    Scroll() {
      Column() {
        // Search
        SearchBar({
          placeholder: '搜索学习资源...',
          onSearch: () => { router.pushUrl({ url: 'pages/SearchPage' }); }
        }).margin({ top: 8, left: 24, right: 24 })

        // Banner
        BannerSwiper({
          banners: this.allBanners,
          onBannerTap: (item: BannerItem) => {
            if (item.linkType === 'post') {
              router.pushUrl({ url: 'pages/CommunityPage', params: { highlightPostId: item.linkValue } });
            } else {
              const catId = parseInt(item.linkValue);
              const cat = this.categories.find(c => c.id === catId);
              router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: catId, categoryTitle: cat?.title || '' } });
            }
          }
        }).margin({ top: 12, left: 24, right: 24 })

        // Developer-recommended post
        if (this.recommendedPost) {
          Row() {
            Row() {
              Text('⚡').fontSize(22)
              Column() {
                Text(this.recommendedPost.title)
                  .fontSize(15).fontWeight(FontWeight.Bold)
                  .fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.recommendedPost.author + ' · ' + this.recommendedPost.createdAt)
                  .fontSize(11).fontColor(this.isDarkMode ? '#0E0E10BB' : '#FFFFFFBB').margin({ top: 3 })
              }.layoutWeight(1).margin({ left: 10 })
              Text('查看 ›').fontSize(12).fontColor(this.isDarkMode ? '#0E0E10CC' : '#FFFFFFCC').fontWeight(FontWeight.Medium)
            }.width('100%').padding(14)
          }
          .width('100%')
          .margin({ left: 24, right: 24, top: 8 })
          .linearGradient({ direction: GradientDirection.Right, colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.ACCENT_TEAL_LIGHT, 1]] })
          .borderRadius(14)
          .shadow({ radius: 8, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '30'), offsetX: 0, offsetY: 3 })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }

        // Community entry
        Row() {
          Row() {
            Text('💬').fontSize(22)
            Column() {
              Text('学习社区').fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('发帖 · 讨论 · 推荐').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.margin({ left: 10 })
            Blank()
            Text('进入 ›').fontSize(12).fontColor(ColorTokens.primary(this.isDarkMode))
          }.width('100%').padding(14)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
          .margin({ left: 24, right: 24, top: 8 })
          .shadow({ radius: 8, color: ColorTokens.SHADOW_MEDIUM, offsetX: 0, offsetY: 2 })
          .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 14 })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }

        // Course recommendations
        if (this.courseRecommendations.length > 0) {
          Row() {
            Text(this.userGrade ? `${this.userGrade} · 为你推荐` : '课程推荐')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
            Blank()
            Row() {
              Text(this.userGrade || '').fontSize(11).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(8)
            }
          }.width('100%').padding({ left: 24, right: 24 }).margin({ top: 20 })

          ForEach(this.courseRecommendations, (course: CurriculumCourse) => {
            CourseRecommendCard({
              courseName: course.name, 
              courseEmoji: course.emoji, 
              courseDesc: course.description,
              searchKeyword: course.name
            })
          })
        }

        // Postgrad entry (大三/大四)
        if (this.userGrade === '大三' || this.userGrade === '大四') {
          Row() {
            Row() {
              Text('🎓').fontSize(30)
              Column() {
                Text('考研指南').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                Text('报名流程 · 科目攻略 · 院校选择 · 备考规划').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
              }.margin({ left: 14 })
              Blank()
              Text('查看 ›').fontSize(13).fontColor(ColorTokens.primary(this.isDarkMode))
            }.width('100%').padding(18)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(16)
            .margin({ left: 24, right: 24, top: 10 })
            .shadow({ radius: 12, color: ColorTokens.SHADOW_MEDIUM, offsetX: 0, offsetY: 3 })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 16 })
            .onClick(() => { router.pushUrl({ url: 'pages/PostgradGuidePage' }); })
          }.width('100%')
        }

        // Model compare
        Row() {
          Row() {
            Text('🤖').fontSize(30)
            Column() {
              Text('AI模型价格对比').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('DeepSeek · Claude · GPT · 千问 · Kimi · 小米MiMo').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.margin({ left: 14 })
            Blank()
            Text('查看 ›').fontSize(13).fontColor(ColorTokens.primary(this.isDarkMode))
          }.width('100%').padding(18)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(16)
          .margin({ left: 24, right: 24, top: 10 })
          .shadow({ radius: 12, color: ColorTokens.SHADOW_MEDIUM, offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 16 })
          .onClick(() => { router.pushUrl({ url: 'pages/ModelComparePage' }); })
        }.width('100%')

        // Hot resources
        if (this.hotResources.length > 0) {
          Row() {
            Text('🔥 热门资源')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
            Blank()
            Text(this.hotResources.length.toString() + '个')
              .fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode))
          }
          .width('100%').padding({ left: 24, right: 24 }).margin({ top: 20 })

          Grid() {
            ForEach(this.hotResources, (item: ResourceItem) => {
              GridItem() {
                ResourceCard({
                  resource: item,
                  onTap: () => {
                    router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                  }
                })
              }
            }, (item: ResourceItem) => item.id.toString())
          }
          .columnsTemplate(new BpType<string>({
            sm: '1fr', md: '1fr 1fr', lg: '1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr'
          }).getValue(this.currentBreakpoint) ?? '1fr')
          .rowsGap(8).columnsGap(8)
          .width('100%').padding({ left: 20, right: 20 })
        } else if (!this.hotResourcesLoading) {
          Row() {
            Text('暂无资源').fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode))
          }
          .width('100%').padding(20).justifyContent(FlexAlign.Center)
        }

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }
}
