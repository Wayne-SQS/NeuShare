import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, BlurPerformance, FontScale, Radii, Spacing, ControlSize, SectionHeader, StateView, ViewState, GridLayout, Elevation } from '@neushare/common';
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
  @State hotResourcesFailed: boolean = false;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSwitchTab?: (index: number) => void;
  private resourceService: ResourceService = ResourceService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.loadHotResources();
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.appearOpacity = 1;
    });
  }

  async loadHotResources(): Promise<void> {
    this.hotResourcesLoading = true;
    this.hotResourcesFailed = false;
    try {
      this.hotResources = await this.resourceService.fetchHotResources(8);
    } catch (e) {
      console.error('loadHotResources failed: ' + JSON.stringify(e));
      this.hotResourcesFailed = true;
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
        }).margin({ top: 8, left: 16, right: 16 })

        // Banner
        BannerSwiper({
          banners: this.allBanners,
          onBannerTap: (item: BannerItem) => {
            if (item.linkType === 'post') {
              router.pushUrl({ url: 'pages/CommunityPage', params: { highlightPostId: item.linkValue } });
            } else if (item.linkType === 'postgrad') {
              router.pushUrl({ url: 'pages/PostgradGuidePage' });
            } else {
              const catId = parseInt(item.linkValue);
              const cat = this.categories.find(c => c.id === catId);
              router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: catId, categoryTitle: cat?.title || '' } });
            }
          }
        }).margin({ top: 12, left: 0, right: 0 })

        // Developer-recommended post
        if (this.recommendedPost) {
          Row() {
            Row() {
              Text('推荐')
                .fontSize(FontScale.MICRO)
                .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
                .backgroundColor(ColorTokens.withAlpha(ColorTokens.textOnPrimary(this.isDarkMode), '26'))
                .borderRadius(Radii.SM)
              Column() {
                Text(this.recommendedPost.title)
                  .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.textOnPrimary(this.isDarkMode)).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.recommendedPost.authorNickname + ' · ' + this.recommendedPost.createTime)
                  .fontSize(FontScale.MICRO).fontColor(ColorTokens.withAlpha(ColorTokens.textOnPrimary(this.isDarkMode), 'BB')).margin({ top: Spacing.XXS })
              }.layoutWeight(1).margin({ left: Spacing.MD }).alignItems(HorizontalAlign.Start)
              Text('查看').fontSize(FontScale.LABEL).fontColor(ColorTokens.withAlpha(ColorTokens.textOnPrimary(this.isDarkMode), 'CC')).fontWeight(FontWeight.Medium)
            }.width('100%').padding(Spacing.LG)
          }
          .width('100%')
          .margin({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })
          .linearGradient({ direction: GradientDirection.Right, colors: [[ColorTokens.primary(this.isDarkMode), 0], [ColorTokens.ACCENT_TEAL_LIGHT, 1]] })
          .borderRadius(Radii.CARD)
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '30'), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }

        // Community entry
        Row() {
          Row() {
            Row().width(3).height(ControlSize.ICON).borderRadius(Radii.XXS).backgroundColor(ColorTokens.primary(this.isDarkMode))
            Column() {
              Text('学习社区').fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('发帖 · 讨论 · 推荐').fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: Spacing.XXS })
            }.margin({ left: Spacing.MD }).alignItems(HorizontalAlign.Start)
            Blank()
            Text('进入').fontSize(FontScale.LABEL).fontColor(ColorTokens.primary(this.isDarkMode))
          }.width('100%').padding(Spacing.LG)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }
        .width('100%')
        .margin({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })

        // Course recommendations
        if (this.courseRecommendations.length > 0) {
          Row() {
            Text(this.userGrade ? `${this.userGrade} · 为你推荐` : '课程推荐')
              .fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
            Blank()
            Row() {
              Text(this.userGrade || '').fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
                .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.SM)
            }
          }.width('100%').padding({ left: Spacing.PAGE, right: Spacing.PAGE }).margin({ top: Spacing.XL })

          ForEach(this.courseRecommendations, (course: CurriculumCourse, idx: number) => {
            CourseRecommendCard({
              courseName: course.name,
              courseDesc: course.description,
              searchKeyword: course.name
            })
          }, (course: CurriculumCourse, idx: number) => 'crc_' + idx.toString())
        }

        // Postgrad entry（所有用户可见）
        Row() {
          Row() {
            Row().width(3).height(ControlSize.ICON_LG).borderRadius(Radii.XXS).backgroundColor(ColorTokens.primary(this.isDarkMode))
            Column() {
              Text('考研指南').fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('报名流程 · 科目攻略 · 院校选择 · 备考规划').fontSize(FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: Spacing.XXS })
            }.margin({ left: Spacing.MD }).layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text('查看').fontSize(FontScale.CAPTION).fontColor(ColorTokens.primary(this.isDarkMode))
          }.width('100%').padding(Spacing.LG)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
          .onClick(() => { router.pushUrl({ url: 'pages/PostgradGuidePage' }); })
        }
        .width('100%')
        .margin({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })

        // Model compare
        Row() {
          Row() {
            Row().width(3).height(ControlSize.ICON_LG).borderRadius(Radii.XXS).backgroundColor(ColorTokens.primary(this.isDarkMode))
            Column() {
              Text('AI模型价格对比').fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('DeepSeek · Claude · GPT · 千问 · Kimi · 小米MiMo').fontSize(FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: Spacing.XXS })
            }.margin({ left: Spacing.MD }).layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text('查看').fontSize(FontScale.CAPTION).fontColor(ColorTokens.primary(this.isDarkMode))
          }.width('100%').padding(Spacing.LG)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
          .onClick(() => { router.pushUrl({ url: 'pages/ModelComparePage' }); })
        }
        .width('100%')
        .margin({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })

        // Hot resources
        Column() {
          SectionHeader({
            title: '热门资源',
            actionText: this.hotResources.length > 0 ? this.hotResources.length.toString() + ' 个' : ''
          })
        }.width('100%').padding({ left: Spacing.PAGE, right: Spacing.PAGE })

        if (this.hotResourcesLoading) {
          StateView({ state: ViewState.LOADING, message: '正在加载资源' })
        } else if (this.hotResourcesFailed) {
          StateView({
            state: ViewState.ERROR,
            message: '资源加载失败',
            hint: '请检查网络后重试',
            onRetry: () => { this.loadHotResources(); }
          })
        } else if (this.hotResources.length === 0) {
          StateView({ state: ViewState.EMPTY, message: '暂无热门资源', hint: '上传的资料会在这里展示' })
        } else {
          GridRow({
            columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
            gutter: { x: Spacing.MD, y: Spacing.MD },
            breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
          }) {
            ForEach(this.hotResources, (item: ResourceItem) => {
              GridCol({ span: 1 }) {
                ResourceCard({
                  resource: item,
                  onTap: () => {
                    router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                  }
                })
              }
            }, (item: ResourceItem) => item.id.toString())
          }
          .width('100%')
          .padding({ left: Spacing.PAGE, right: Spacing.PAGE })
        }

        Column().height(80)
      }
      .width('100%')
      .constraintSize({ maxWidth: new BpType<number>({ sm: 9999, md: 576, lg: 656, xl: 900 }).getValue(this.currentBreakpoint) ?? 9999 })
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.On)
    .width('100%').height('100%')
    .opacity(this.appearOpacity)
    .animation({ curve: Curve.EaseOut, duration: 200 })
  }
}
