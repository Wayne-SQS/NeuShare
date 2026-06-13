import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { CommunityService } from '../services/CommunityService';
import { Post, PostFile, hotness, formatFileSize, fileIcon } from '../models/PostModel';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct CommunityPage {
  @State posts: Post[] = [];
  @State allPosts: Post[] = [];
  @State highlightPostId: string = '';
  @State filterTag: string = '';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private communityService: CommunityService = CommunityService.getInstance();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.communityService.init(context);

    const params = router.getParams() as Record<string, Object>;
    if (params && params['highlightPostId']) {
      this.highlightPostId = params['highlightPostId'] as string;
    }

    await this.loadPosts();
  }

  onPageShow(): void {
    this.loadPosts();
  }

  async loadPosts(): Promise<void> {
    this.allPosts = await this.communityService.getAllPosts();
    if (this.filterTag) {
      this.posts = this.allPosts.filter(p => p.tags.includes(this.filterTag));
    } else {
      this.posts = [...this.allPosts];
    }
  }

  getAllTags(): string[] {
    const set = new Set<string>();
    for (const p of this.allPosts) {
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

  async likePost(postId: string): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.communityService.init(context);
    await this.communityService.likePost(postId);
    await this.loadPosts();
  }

  async favoritePost(postId: string): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.communityService.init(context);
    await this.communityService.favoritePost(postId);
    await this.loadPosts();
  }

  async recommendPost(postId: string): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.communityService.init(context);
    await this.communityService.recommendPost(postId);
    await this.loadPosts();
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('学习社区').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.TEXT_PRIMARY).layoutWeight(1).textAlign(TextAlign.Center)
        Text('✚ 发帖')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.PRIMARY)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(14)
          .onClick(() => { router.pushUrl({ url: 'pages/CreatePostPage' }); })
      }
      .width('100%').height(52).padding({ left: 14, right: 10 })
      .backgroundColor(ColorTokens.BG_CARD)

      // Tag filter pills
      if (this.getAllTags().length > 0) {
        Row() {
          Text('🏷️').fontSize(13)
          Scroll() {
            Row() {
              ForEach(this.getAllTags(), (tag: string) => {
                Text(tag)
                  .fontSize(11)
                  .fontWeight(this.filterTag === tag ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.filterTag === tag ? '#FFFFFF' : ColorTokens.TEXT_PRIMARY)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.filterTag === tag ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
                  .borderRadius(12)
                  .margin({ right: 6 })
                  .onClick(() => { this.filterByTag(tag); })
              })
              if (this.filterTag) {
                Text('✕ 清除').fontSize(11).fontColor(ColorTokens.RED)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .border({ width: 1, color: ColorTokens.DIVIDER, radius: 12 })
                  .onClick(() => { this.filterTag = ''; this.loadPosts(); })
              }
            }
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1)
        }
        .width('100%').padding({ left: 14, right: 10, top: 6, bottom: 6 })
        .backgroundColor(ColorTokens.BG_PAGE)
      }

      if (this.posts.length === 0) {
        Column() {
          Text('💬').fontSize(48).margin({ top: 120 })
          Text('还没有帖子').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
          Text('点击右上角「✚ 发帖」发布第一条帖子').fontSize(13)
            .fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
        }.width('100%').layoutWeight(1)
      } else if (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
        // ─── PC：双列帖子 ───
        Grid() {
          ForEach(this.posts, (post: Post) => {
            GridItem() {
              this.PostCard(post)
            }
          }, (post: Post) => post.id)
        }
        .columnsTemplate(new BpType<string>({ lg: '1fr 1fr', xl: '1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr').rowsGap(6).columnsGap(6)
        .layoutWeight(1).padding({ left: 16, right: 16, top: 6 })
      } else {
        List() {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              this.PostCard(post)
            }
          }, (post: Post) => post.id)
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0 })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }

  @Builder
  PostCard(post: Post) {
    Column() {
      // Author row
      Row() {
        Text('👤').fontSize(14)
        Text(post.author).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 4 })
        Text('·').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ left: 6, right: 6 })
        Text(post.createdAt).fontSize(12).fontColor(ColorTokens.TEXT_DISABLED)

        if (hotness(post) > 0) {
          Text('🔥' + hotness(post).toString())
            .fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor('#E74C3C').margin({ left: 8 })
        }

        Blank()

        if (post.recommended) {
          Text('⚡ 已推荐')
            .fontSize(11).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.ACCENT)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.ACCENT_LIGHT).borderRadius(8)
        } else {
          Text('推荐')
            .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .border({ width: 1, color: ColorTokens.DIVIDER, radius: 8 })
            .onClick(() => { this.recommendPost(post.id); })
        }
      }.width('100%').margin({ bottom: 8 })

      Text(post.title)
        .fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.TEXT_PRIMARY)
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(post.content)
        .fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20).width('100%').margin({ top: 6 })

      if (post.imageUrls && post.imageUrls.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(post.imageUrls.slice(0, 4), (url: string) => {
            Image(url).width(80).height(80)
              .borderRadius(8).objectFit(ImageFit.Cover)
              .margin({ right: 6, top: 6 })
          }, (url: string) => 'img' + url)
        }.width('100%').margin({ top: 8 })
      }

      if (post.files && post.files.length > 0) {
        Row() {
          ForEach(post.files.slice(0, 5), (file: PostFile, idx: number) => {
            Row() {
              Text(fileIcon(file.type)).fontSize(13)
              Text(file.name).fontSize(11).fontColor(ColorTokens.TEXT_PRIMARY)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 100 })
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ColorTokens.BG_INPUT).borderRadius(8)
            .margin({ right: 6, top: 4 })
          }, (file: PostFile, idx: number) => 'postfile' + idx.toString())
          if (post.files.length > 5) {
            Text('+' + (post.files.length - 5).toString())
              .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ColorTokens.BG_INPUT).borderRadius(8)
              .margin({ top: 4 })
          }
        }.width('100%').margin({ top: 6 })
      }

      if (post.tags.length > 0) {
        Row() {
          ForEach(post.tags, (tag: string) => {
            Text(tag)
              .fontSize(11).fontColor(ColorTokens.PRIMARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(ColorTokens.PRIMARY_LIGHT)
              .borderRadius(6).margin({ right: 6, top: 4 })
          })
        }.width('100%').margin({ top: 8 })
      }

      // Interaction bar
      Row() {
        Row() {
          Text('👍').fontSize(14)
          Text(post.likes.toString()).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 4 })
        }
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(ColorTokens.BG_INPUT).borderRadius(14)
        .onClick(() => { this.likePost(post.id); })

        Row() {
          Text('⭐').fontSize(14)
          Text(post.favorites.toString()).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 4 })
        }
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .backgroundColor(ColorTokens.BG_INPUT).borderRadius(14)
        .margin({ left: 8 })
        .onClick(() => { this.favoritePost(post.id); })

        Row() {
          Text('💬').fontSize(14)
          Text(post.commentsCount.toString()).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 4 })
        }
        .padding({ left: 8, right: 10, top: 6, bottom: 6 })
        .margin({ left: 8 })
      }.width('100%').margin({ top: 10 })
    }
    .width('100%').padding(16)
    .backgroundColor(this.highlightPostId === post.id ? ColorTokens.ACCENT_LIGHT : ColorTokens.BG_CARD)
    .borderRadius(14)
    .margin({ left: (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? 0 : 16, right: (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) ? 0 : 16, top: 6, bottom: 6 })
    .shadow({ radius: 4, color: '#08000000', offsetX: 0, offsetY: 1 })
  }
}
