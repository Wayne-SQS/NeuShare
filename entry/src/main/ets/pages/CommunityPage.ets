import router from '@ohos.router';
import curves from '@ohos.curves';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, BlurPerformance } from '@neushare/common';
import { CommunityService } from '../services/CommunityService';
import { Post, PostFile, hotness, formatFileSize, fileIcon } from '../models/PostModel';

@Entry
@Component
struct CommunityPage {
  @State posts: Post[] = [];
  @State highlightPostId: number = 0;
  @State filterTag: string = '';
  @State likeBounceId: number = 0;
  @State favBounceId: number = 0;
  @State tagPulse: string = '';
  @State breathScale: number = 1;
  @State visiblePostIds: Set<number> = new Set();
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private communityService: CommunityService = CommunityService.getInstance();
  private pageNum: number = 1;
  private hasMore: boolean = true;

  private breathTimerId: number = -1;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['highlightPostId']) {
      this.highlightPostId = params['highlightPostId'] as number;
    }

    await this.loadPosts();

    // 呼吸动画定时器
    this.breathTimerId = setInterval(() => {
      animateTo({ duration: 1500, curve: Curve.EaseInOut }, () => {
        this.breathScale = this.breathScale === 1 ? 1.1 : 1;
      });
    }, 1600);
  }

  aboutToDisappear(): void {
    if (this.breathTimerId !== -1) {
      clearInterval(this.breathTimerId);
      this.breathTimerId = -1;
    }
  }

  onPageShow(): void {
    this.loadPosts();
  }

  async loadPosts(): Promise<void> {
    this.pageNum = 1;
    this.hasMore = true;
    const result = await this.communityService.getPostList(1, 20, this.filterTag || undefined);
    this.posts = result.posts;
    this.hasMore = result.posts.length >= 20;

    // 交错入场：逐个显示帖子
    this.visiblePostIds = new Set();
    for (let i = 0; i < this.posts.length; i++) {
      setTimeout(() => {
        this.visiblePostIds.add(this.posts[i].id);
        const newSet = new Set<number>();
        this.visiblePostIds.forEach(id => newSet.add(id));
        this.visiblePostIds = newSet;
      }, i * 60);
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore) return;
    this.pageNum += 1;
    const result = await this.communityService.getPostList(this.pageNum, 20, this.filterTag || undefined);
    if (result.posts.length === 0) {
      this.hasMore = false;
      return;
    }
    this.posts = [...this.posts, ...result.posts];
    this.hasMore = result.posts.length >= 20;
  }

  getAllTags(): string[] {
    const set = new Set<string>();
    for (const p of this.posts) {
      for (const t of p.tags) {
        set.add(t);
      }
    }
    return Array.from(set).slice(0, 20);
  }

  filterByTag(tag: string): void {
    if (this.filterTag === tag) {
      this.filterTag = '';
    } else {
      this.filterTag = tag;
    }
    this.loadPosts();
  }

  async likePost(postId: number, isLiked: boolean): Promise<void> {
    await this.communityService.likePost(postId, isLiked);
    await this.loadPosts();
  }

  async favoritePost(postId: number, isFavorited: boolean): Promise<void> {
    await this.communityService.favoritePost(postId, isFavorited);
    await this.loadPosts();
  }

  async recommendPost(postId: number): Promise<void> {
    await this.communityService.recommendPost(postId);
    await this.loadPosts();
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('学习社区').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).layoutWeight(1).textAlign(TextAlign.Center)
        Text('✚ 发帖')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(14)
          .onClick(() => { router.pushUrl({ url: 'pages/CreatePostPage' }); })
      }
      .width('100%').height(52).padding({ left: 14, right: 10 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      // Tag filter pills
      if (this.getAllTags().length > 0) {
        Row() {
          Text('🏷️').fontSize(13)
          Scroll() {
            Row() {
              ForEach(this.getAllTags(), (tag: string, idx: number) => {
                Text(tag)
                  .fontSize(11)
                  .fontWeight(this.filterTag === tag ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.filterTag === tag ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.filterTag === tag ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius(12)
                  .margin({ right: 6 })
                  .scale({ x: this.tagPulse === tag ? 1.15 : 1, y: this.tagPulse === tag ? 1.15 : 1 })
                  .animation({ curve: Curve.EaseOut, duration: 200 })
                  .onClick(() => { this.filterByTag(tag); this.tagPulse = tag; setTimeout(() => { this.tagPulse = ''; }, 200); })
              }, (tag: string, idx: number) => 'cmtag_' + idx.toString())
              if (this.filterTag) {
                Text('✕ 清除').fontSize(11).fontColor(ColorTokens.error(this.isDarkMode))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
                  .onClick(() => { this.filterTag = ''; this.loadPosts(); })
              }
            }
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1)
        }
        .width('100%').padding({ left: 14, right: 10, top: 6, bottom: 6 })
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
      }

      if (this.posts.length === 0) {
        Column() {
          Text('💬').fontSize(48).margin({ top: 120 })
            .scale({ x: this.breathScale, y: this.breathScale })
            .animation({ duration: 1500, curve: Curve.EaseInOut, iterations: -1 })
          Text('还没有帖子').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
          Text('点击右上角「✚ 发帖」发布第一条帖子').fontSize(13)
            .fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ top: 4 })
        }.width('100%').layoutWeight(1)
      } else if (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
        // ─── PC：双列帖子 ───
        Grid() {
          ForEach(this.posts, (post: Post) => {
            GridItem() {
              this.PostCard(post)
            }
            .opacity(this.visiblePostIds.has(post.id) ? 1 : 0)
            .translate({ y: this.visiblePostIds.has(post.id) ? 0 : 30 })
            .animation({ duration: 200, curve: Curve.EaseOut })
          }, (post: Post) => post.id.toString())
        }
        .columnsTemplate(new BpType<string>({ lg: '1fr 1fr', xl: '1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr').rowsGap(6).columnsGap(6)
        .layoutWeight(1).padding({ left: 24, right: 24, top: 6 })
      } else {
        List() {
          ForEach(this.posts, (post: Post, index: number) => {
            ListItem() {
              this.PostCard(post)
            }
            .opacity(this.visiblePostIds.has(post.id) ? 1 : 0)
            .translate({ y: this.visiblePostIds.has(post.id) ? 0 : 30 })
            .animation({ duration: 200, curve: Curve.EaseOut })
          }, (post: Post) => post.id.toString())
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0 })
        .onScrollFrameBegin(() => { BlurPerformance.onScrollStart(); return { offsetRemain: 0 }; })
        .onScrollStop(() => { BlurPerformance.onScrollStop(); })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
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
  PostCard(post: Post) {
    Column() {
      // Author row
      Row() {
        Text('👤').fontSize(14)
        Text(post.authorNickname).fontSize(13).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        Text('·').fontSize(13).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 6, right: 6 })
        Text(post.createTime).fontSize(12).fontColor(ColorTokens.textDisabled(this.isDarkMode))

        if (hotness(post) > 0) {
          Text('🔥' + hotness(post).toString())
            .fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.warning(this.isDarkMode)).margin({ left: 8 })
        }

        Blank()

        if (post.isRecommended) {
          Text('⚡ 已推荐')
            .fontSize(11).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(8)
        } else {
          Text('推荐')
            .fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 8 })
            .onClick(() => { this.recommendPost(post.id); })
        }
      }.width('100%').margin({ bottom: 8 })

      Text(post.title)
        .fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(post.content)
        .fontSize(13).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20).width('100%').margin({ top: 6 })

      if (post.imageUrls && post.imageUrls.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(post.imageUrls.slice(0, 4), (url: string, idx: number) => {
            Image(url).width(80).height(80)
              .borderRadius(8).objectFit(ImageFit.Cover)
              .margin({ right: 6, top: 6 })
          }, (url: string, idx: number) => 'pimg_' + idx.toString())
        }.width('100%').margin({ top: 8 })
      }

      if (post.files && post.files.length > 0) {
        Row() {
          ForEach(post.files.slice(0, 5), (file: PostFile, idx: number) => {
            Row() {
              Text(fileIcon(file.type)).fontSize(13)
              Text(file.name).fontSize(11).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 100 })
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(8)
            .margin({ right: 6, top: 4 })
          }, (file: PostFile, idx: number) => 'pf_' + idx.toString() + '_' + file.name)
          if (post.files.length > 5) {
            Text('+' + (post.files.length - 5).toString())
              .fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(8)
              .margin({ top: 4 })
          }
        }.width('100%').margin({ top: 6 })
      }

      if (post.tags.length > 0) {
        Row() {
          ForEach(post.tags, (tag: string, idx: number) => {
            Text(tag)
              .fontSize(11).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
              .borderRadius(6).margin({ right: 6, top: 4 })
          }, (tag: string, idx: number) => 'ptag_' + idx.toString())
        }.width('100%').margin({ top: 8 })
      }

      // Interaction bar
      Row() {
        Row() {
          Text(post.isLiked ? '👍' : '👍').fontSize(14)
          Text(post.likeCount.toString()).fontSize(13).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .scale({ x: this.likeBounceId === post.id ? 1.3 : 1, y: this.likeBounceId === post.id ? 1.3 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 200 })
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(post.isLiked ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(14)
        .onClick(() => { this.likePost(post.id, post.isLiked); this.likeBounceId = post.id; setTimeout(() => { this.likeBounceId = 0; }, 200); })

        Row() {
          Text(post.isFavorited ? '⭐' : '⭐').fontSize(14)
          Text(post.favoriteCount.toString()).fontSize(13).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .scale({ x: this.favBounceId === post.id ? 1.3 : 1, y: this.favBounceId === post.id ? 1.3 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 200 })
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(post.isFavorited ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(14)
        .margin({ left: 8 })
        .onClick(() => { this.favoritePost(post.id, post.isFavorited); this.favBounceId = post.id; setTimeout(() => { this.favBounceId = 0; }, 300); })

        Row() {
          Text('💬').fontSize(14)
          Text(post.commentCount.toString()).fontSize(13).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .margin({ left: 8 })
      }.width('100%').margin({ top: 10 })
    }
    .width('100%').padding(16)
    .backgroundColor(this.highlightPostId === post.id ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(14)
    .margin({ left: (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? 0 : 24, right: (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? 0 : 24, top: 6, bottom: 6 })
    .shadow({ radius: 4, color: '#08000000', offsetX: 0, offsetY: 1 })
    .onClick(() => { router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: post.id } }); })
  }
}
