import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceService } from '../../services/ResourceService';
import { CommunityService } from '../../services/CommunityService';
import { Post } from '../../models/PostModel';
import { CategoryItem, BannerItem, ResourceItem } from '../../models/ResourceModel';
import { CurriculumCourse } from '../../services/CurriculumService';
import { BannerSwiper } from '../../components/BannerSwiper';
import { SearchBar } from '../../components/SearchBar';
import { CourseRecommendCard } from '../../components/CourseRecommendCard';

@Component
export struct HomeTab {
  @Prop categories: CategoryItem[] = [];
  @Prop allBanners: BannerItem[] = [];
  @Prop courseRecommendations: CurriculumCourse[] = [];
  @Prop userGrade: string = '';
  @Prop recommendedPost: Post | null = null;
  @Prop favoriteCount: number = 0;
  @Prop historyCount: number = 0;
  onSwitchTab?: (index: number) => void;

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
            } else {
              const catId = parseInt(item.linkValue);
              const cat = this.categories.find(c => c.id === catId);
              router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: catId, categoryTitle: cat?.title || '' } });
            }
          }
        }).margin({ top: 12 })

        // Developer-recommended post
        if (this.recommendedPost) {
          Row() {
            Row() {
              Text('⚡').fontSize(22)
              Column() {
                Text(this.recommendedPost.title)
                  .fontSize(15).fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF').maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.recommendedPost.author + ' · ' + this.recommendedPost.createdAt)
                  .fontSize(11).fontColor('#FFFFFFBB').margin({ top: 3 })
              }.layoutWeight(1).margin({ left: 10 })
              Text('查看 ›').fontSize(12).fontColor('#FFFFFFCC').fontWeight(FontWeight.Medium)
            }.width('100%').padding(14)
          }
          .width('100%')
          .margin({ left: 16, right: 16, top: 8 })
          .linearGradient({ direction: GradientDirection.Right, colors: [[ColorTokens.PRIMARY, 0], ['#4A6594', 1]] })
          .borderRadius(14)
          .shadow({ radius: 8, color: ColorTokens.PRIMARY + '30', offsetX: 0, offsetY: 3 })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }

        // Community entry
        Row() {
          Row() {
            Text('💬').fontSize(22)
            Column() {
              Text('学习社区').fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('发帖 · 讨论 · 推荐').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })
            }.margin({ left: 10 })
            Blank()
            Text('进入 ›').fontSize(12).fontColor(ColorTokens.ACCENT)
          }.width('100%').padding(14)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 8 })
          .shadow({ radius: 6, color: '#08000000', offsetX: 0, offsetY: 1 })
          .border({ width: 1, color: '#0A000000', radius: 14 })
          .onClick(() => { router.pushUrl({ url: 'pages/CommunityPage' }); })
        }

        // Course recommendations
        if (this.courseRecommendations.length > 0) {
          Row() {
            Text(this.userGrade ? `${this.userGrade} · 为你推荐` : '课程推荐')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
            Blank()
            Row() {
              Text(this.userGrade || '').fontSize(11).fontColor('#FFFFFF')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(ColorTokens.PRIMARY).borderRadius(8)
            }
          }.width('100%').padding({ left: 16, right: 16 }).margin({ top: 20 })

          ForEach(this.courseRecommendations, (course: CurriculumCourse) => {
            CourseRecommendCard({
              courseName: course.name, courseEmoji: course.emoji, courseDesc: course.description,
              categoryId: course.categoryIds.length > 0 ? course.categoryIds[0] : 1,
              categoryTitle: course.name
            })
          })
        }

        // Postgrad entry (大三/大四)
        if (this.userGrade === '大三' || this.userGrade === '大四') {
          Row() {
            Row() {
              Text('🎓').fontSize(30)
              Column() {
                Text('考研指南').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                Text('报名流程 · 科目攻略 · 院校选择 · 备考规划').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })
              }.margin({ left: 14 })
              Blank()
              Text('查看 ›').fontSize(13).fontColor(ColorTokens.ACCENT)
            }.width('100%').padding(18)
            .backgroundColor('#FDF6EE').borderRadius(16)
            .margin({ left: 16, right: 16, top: 10 })
            .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 3 })
            .border({ width: 1, color: '#0A000000', radius: 16 })
            .onClick(() => { router.pushUrl({ url: 'pages/PostgradGuidePage' }); })
          }.width('100%')
        }

        // Model compare
        Row() {
          Row() {
            Text('🤖').fontSize(30)
            Column() {
              Text('AI模型价格对比').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('DeepSeek · Claude · GPT · 千问 · Kimi · 小米MiMo').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })
            }.margin({ left: 14 })
            Blank()
            Text('查看 ›').fontSize(13).fontColor(ColorTokens.ACCENT)
          }.width('100%').padding(18)
          .backgroundColor('#FFFFFFF0').borderRadius(16)
          .margin({ left: 16, right: 16, top: 10 })
          .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: '#0A000000', radius: 16 })
          .onClick(() => { router.pushUrl({ url: 'pages/ModelComparePage' }); })
        }.width('100%')

        Column().height(80)
      }
    }
    .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
  }
}
