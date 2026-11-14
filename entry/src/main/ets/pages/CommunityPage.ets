import router from '@ohos.router';
import curves from '@ohos.curves';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, BlurPerformance, FontScale, Radii, Spacing, ControlSize, Elevation, GridLayout, PageHeader, StateView, ViewState } from '@neushare/common';
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
  @State isLoading: boolean = false;
  @State loadFailed: boolean = false;
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
    this.isLoading = this.posts.length === 0;
    this.loadFailed = false;
    try {
      const result = await this.communityService.getPostList(1, 20, this.filterTag || undefined);
      this.posts = result.posts;
      this.hasMore = result.posts.length >= 20;
    } catch (e) {
      console.error('[CommunityPage] loadPosts failed: ' + JSON.stringify(e));
      this.loadFailed = true;
    }
    this.isLoading = false;

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
      PageHeader({
        title: '学习社区',
        actionText: '发帖',
        onAction: () => { router.pushUrl({ url: 'pages/CreatePostPage' }); }
      })

      // Tag filter pills
      if (this.getAllTags().length > 0) {
        Row() {
          Scroll() {
            Row() {
              ForEach(this.getAllTags(), (tag: string, idx: number) => {
                Text(tag)
                  .fontSize(FontScale.MICRO)
                  .fontWeight(this.filterTag === tag ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.filterTag === tag ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                  .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                  .backgroundColor(this.filterTag === tag ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius(Radii.SM)
                  .margin({ right: Spacing.SM })
                  .scale({ x: this.tagPulse === tag ? 1.15 : 1, y: this.tagPulse === tag ? 1.15 : 1 })
                  .animation({ curve: Curve.EaseOut, duration: 200 })
                  .onClick(() => { this.filterByTag(tag); this.tagPulse = tag; setTimeout(() => { this.tagPulse = ''; }, 200); })
              }, (tag: string, idx: number) => 'cmtag_' + idx.toString())
              if (this.filterTag) {
                Text('清除筛选').fontSize(FontScale.MICRO).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                  .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                  .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.SM })
                  .onClick(() => { this.filterTag = ''; this.loadPosts(); })
              }
            }
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1)
        }
        .width('100%').padding({ left: Spacing.PAGE, right: Spacing.MD, top: Spacing.SM, bottom: Spacing.SM })
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
      }

      if (this.isLoading) {
        StateView({ state: ViewState.LOADING, message: '正在加载帖子' })
      } else if (this.loadFailed) {
        StateView({
          state: ViewState.ERROR,
          message: '帖子加载失败',
          hint: '请检查网络后重试',
          onRetry: () => { this.loadPosts(); }
        })
      } else if (this.posts.length === 0) {
        StateView({
          state: ViewState.EMPTY,
          message: '还没有帖子',
          hint: '点击右上角「发帖」发布第一条帖子'
        })
      } else {
        Scroll() {
          GridRow({
            columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
            gutter: { x: Spacing.SM, y: Spacing.SM },
            breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
          }) {
            ForEach(this.posts, (post: Post) => {
              GridCol({ span: 1 }) {
                Column() {
                  this.PostCard(post)
                }
                .opacity(this.visiblePostIds.has(post.id) ? 1 : 0)
                .translate({ y: this.visiblePostIds.has(post.id) ? 0 : 30 })
                .animation({ duration: 200, curve: Curve.EaseOut })
              }
            }, (post: Post) => post.id.toString())
          }
          .width('100%')
          .padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM, bottom: Spacing.HUGE })
        }
        .width('100%').layoutWeight(1).align(Alignment.Top)
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
        Text(post.authorNickname).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        Text('·').fontSize(FontScale.CAPTION).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 6, right: 6 })
        Text(post.createTime).fontSize(FontScale.LABEL).fontColor(ColorTokens.textDisabled(this.isDarkMode))

        if (hotness(post) > 0) {
          Text('热度 ' + hotness(post).toString())
            .fontSize(FontScale.TINY).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.warning(this.isDarkMode)).margin({ left: 8 })
        }

        Blank()

        if (post.isRecommended) {
          Text('已推荐')
            .fontSize(FontScale.MICRO).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(Radii.MD)
        } else {
          Text('推荐')
            .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.MD })
            .onClick(() => { this.recommendPost(post.id); })
        }
      }.width('100%').margin({ bottom: 8 })

      Text(post.title)
        .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(post.content)
        .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20).width('100%').margin({ top: 6 })

      if (post.imageUrls && post.imageUrls.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(post.imageUrls.slice(0, 4), (url: string, idx: number) => {
            Image(url).width(80).height(80)
              .borderRadius(Radii.MD).objectFit(ImageFit.Cover)
              .margin({ right: 6, top: 6 })
          }, (url: string, idx: number) => 'pimg_' + idx.toString())
        }.width('100%').margin({ top: 8 })
      }

      if (post.files && post.files.length > 0) {
        Row() {
          ForEach(post.files.slice(0, 5), (file: PostFile, idx: number) => {
            Row() {
              Text(fileIcon(file.type)).fontSize(FontScale.CAPTION)
              Text(file.name).fontSize(FontScale.MICRO).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 100 })
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.MD)
            .margin({ right: 6, top: 4 })
          }, (file: PostFile, idx: number) => 'pf_' + idx.toString() + '_' + file.name)
          if (post.files.length > 5) {
            Text('+' + (post.files.length - 5).toString())
              .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.MD)
              .margin({ top: 4 })
          }
        }.width('100%').margin({ top: 6 })
      }

      if (post.tags.length > 0) {
        Row() {
          ForEach(post.tags, (tag: string, idx: number) => {
            Text(tag)
              .fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
              .borderRadius(Radii.SM).margin({ right: 6, top: 4 })
          }, (tag: string, idx: number) => 'ptag_' + idx.toString())
        }.width('100%').margin({ top: 8 })
      }

      // Interaction bar
      Row() {
        Row() {
          Text('赞').fontSize(FontScale.CAPTION).fontColor(post.isLiked ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
          Text(post.likeCount.toString()).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .scale({ x: this.likeBounceId === post.id ? 1.3 : 1, y: this.likeBounceId === post.id ? 1.3 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 200 })
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(post.isLiked ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.XL)
        .onClick(() => { this.likePost(post.id, post.isLiked); this.likeBounceId = post.id; setTimeout(() => { this.likeBounceId = 0; }, 200); })

        Row() {
          Text('收藏').fontSize(FontScale.CAPTION).fontColor(post.isFavorited ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
          Text(post.favoriteCount.toString()).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .scale({ x: this.favBounceId === post.id ? 1.3 : 1, y: this.favBounceId === post.id ? 1.3 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 200 })
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(post.isFavorited ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.XL)
        .margin({ left: 8 })
        .onClick(() => { this.favoritePost(post.id, post.isFavorited); this.favBounceId = post.id; setTimeout(() => { this.favBounceId = 0; }, 300); })

        Row() {
          Text('评论').fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode))
          Text(post.commentCount.toString()).fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
        }
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .margin({ left: 8 })
      }.width('100%').margin({ top: 10 })
    }
    .width('100%').padding(16)
    .backgroundColor(this.highlightPostId === post.id ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(Radii.CARD)
    .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
    .margin({ top: 6, bottom: 6 })
    .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
    .onClick(() => { router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: post.id } }); })
  }
}
