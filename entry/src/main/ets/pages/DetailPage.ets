import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { CommunityService } from '../services/CommunityService';
import { RecommendService } from '../services/RecommendService';
import { TtsService } from '../services/TtsService';
import { ShareHelper } from '../services/ShareHelper';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { Post } from '../models/PostModel';
import { CommentApi, CommentItem } from '../api/CommentApi';
import { Context } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct DetailPage {
  @State resource: ResourceItemModel | null = null;
  @State isFavorited: boolean = false;
  @State comments: Post[] = [];
  @State cloudComments: CommentItem[] = [];
  @State newComment: string = '';
  @State commentLoading: boolean = false;
  @State similarResources: ResourceItemModel[] = [];
  @State isSpeaking: boolean = false;
  @State loadFailed: boolean = false;
  @State loadTimeout: boolean = false;
  @State showComments: boolean = false; // 半模态评论面板（教程 §13.3）
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private resourceId: number = 0;
  private loadTimer: number = -1;
  private resourceService: ResourceService = ResourceService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();
  private commentApi: CommentApi = new CommentApi();
  private recommendService: RecommendService = RecommendService.getInstance();
  private ttsService: TtsService = TtsService.getInstance();
  private shareHelper: ShareHelper = ShareHelper.getInstance();

  // ── 响应式参数 ─────────────────────────────────────────
  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 640, lg: 780, xl: 920 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private titleFontSize(): number {
    return new BpType<number>({ sm: 22, md: 26, lg: 30, xl: 34 }).getValue(this.currentBreakpoint) ?? 22;
  }

  private subtitleFontSize(): number {
    return new BpType<number>({ sm: 16, md: 18, lg: 22, xl: 26 }).getValue(this.currentBreakpoint) ?? 16;
  }

  private bodyFontSize(): number {
    return new BpType<number>({ sm: 14, md: 16, lg: 18, xl: 20 }).getValue(this.currentBreakpoint) ?? 14;
  }

  private captionFontSize(): number {
    return new BpType<number>({ sm: 12, md: 14, lg: 16, xl: 18 }).getValue(this.currentBreakpoint) ?? 12;
  }

  private smallFontSize(): number {
    return new BpType<number>({ sm: 11, md: 12, lg: 14, xl: 16 }).getValue(this.currentBreakpoint) ?? 11;
  }

  private headerHeight(): number {
    return new BpType<number>({ sm: 48, md: 52, lg: 58, xl: 64 }).getValue(this.currentBreakpoint) ?? 48;
  }

  private cardPadding(): number {
    return new BpType<number>({ sm: 14, md: 16, lg: 20, xl: 24 }).getValue(this.currentBreakpoint) ?? 14;
  }

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.resourceId = params['resourceId'] as number;
    }
    // 先从本地加载
    const localRes = this.resourceService.getLocalResourceById(this.resourceId);
    if (localRes) {
      this.resource = localRes;
    }
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.communityService.init(context);
    this.isFavorited = await this.favoriteService.isFavorite(this.resourceId);
    await this.favoriteService.addHistory(this.resourceId);
    await this.loadComments();
    this.loadCloudComments();
    // 异步从后端加载详情
    this.loadDetailFromApi();
    // 超时兜底：8 秒后若仍无数据则报错
    this.loadTimer = setTimeout(() => {
      if (!this.resource) {
        this.loadTimeout = true;
      }
    }, 8000);
  }

  async loadDetailFromApi(): Promise<void> {
    try {
      const res = await this.resourceService.fetchResourceDetail(this.resourceId);
      if (res) {
        this.resource = res;
        if (this.loadTimer >= 0) {
          clearTimeout(this.loadTimer);
          this.loadTimer = -1;
        }
      } else {
        if (!this.resource) {
          this.loadFailed = true;
        }
      }
    } catch (e) {
      console.error('loadDetailFromApi error: ' + JSON.stringify(e));
      if (!this.resource) {
        this.loadFailed = true;
      }
    }
    // 加载相似推荐
    if (this.resource) {
      this.similarResources = this.recommendService.getSimilarResources(this.resourceId, 4);
    }
  }

  async loadComments(): Promise<void> {
    const allPosts = await this.communityService.getAllPosts();
    this.comments = allPosts.filter(p =>
      p.tags.some(t => t.includes(this.resourceId.toString()))
    );
  }

  async loadCloudComments(): Promise<void> {
    try {
      const resp = await this.commentApi.getList(this.resourceId);
      if (resp.code === 200 && resp.data) {
        this.cloudComments = resp.data;
      } else {
        promptAction.showToast({ message: '评论加载失败: ' + resp.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器，请确认后端已启动' });
    }
  }

  async submitComment(): Promise<void> {
    if (!this.newComment.trim() || this.commentLoading) return;
    this.commentLoading = true;
    const content: string = this.newComment.trim();
    this.newComment = '';
    // Optimistically append to list immediately
    const optimistic: CommentItem = {
      id: Date.now(),
      resourceId: this.resourceId,
      userId: 0,
      nickname: '我',
      avatarUrl: '',
      content: content,
      parentId: 0,
      deleted: 0,
      children: [],
      createTime: '刚刚'
    };
    this.cloudComments = [optimistic, ...this.cloudComments];
    try {
      const resp = await this.commentApi.add(this.resourceId, content, 0);
      if (resp.code === 200) {
        // Refresh to get real data from server
        await this.loadCloudComments();
      } else {
        promptAction.showToast({ message: '发送失败: ' + resp.message });
        await this.loadCloudComments();
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器，评论仅本地可见' });
    }
    this.commentLoading = false;
  }

  async toggleFavorite(): Promise<void> {
    const isFav = await this.favoriteService.toggleFavorite(this.resourceId);
    this.isFavorited = isFav;
  }

  async toggleTts(): Promise<void> {
    if (this.isSpeaking) {
      this.ttsService.stop();
      this.isSpeaking = false;
    } else if (this.resource) {
      const ok = await this.ttsService.speakResource(this.resource.title, this.resource.description);
      this.isSpeaking = ok;
    }
  }

  async likeComment(postId: string): Promise<void> {
    await this.communityService.likePost(postId);
    await this.loadComments();
  }

  openUrl(url: string): void {
    if (!url || url.trim().length === 0) return;
    // 优先应用内 WebView 打开
    router.pushUrl({ url: 'pages/WebViewPage', params: { url: url, title: this.resource?.title || '' } });
  }

  openInBrowser(url: string): void {
    if (!url || url.trim().length === 0) return;
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browser'],
      uri: url
    };
    try { ctx.startAbility(want); } catch (e) {}
  }

  build() {
    Column() {
      if (!this.resource) {
        Column() {
          if (this.loadTimeout || this.loadFailed) {
            Text('📭').fontSize(48)
            Text('加载失败').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ top: 12 })
            Text('请检查网络连接或确认后端服务已启动')
              .fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 6 })
            Text('重试').fontSize(14).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
              .fontWeight(FontWeight.Bold)
              .padding({ left: 24, right: 24, top: 10, bottom: 10 })
              .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(20)
              .margin({ top: 20 })
              .onClick(() => {
                this.loadFailed = false;
                this.loadTimeout = false;
                this.loadDetailFromApi();
                this.loadTimer = setTimeout(() => {
                  if (!this.resource) { this.loadTimeout = true; }
                }, 8000);
              })
          } else {
            LoadingProgress().width(36).height(36).color(ColorTokens.primary(this.isDarkMode))
            Text('加载中...').fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
          }
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        // 大屏：主内容 + 侧边推荐并排；小屏：全屏滚动
        if (this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.MD || this.currentBreakpoint === BreakpointTypeEnum.XL) {
          Row() {
            // 主内容区
            Scroll() {
              Column() {
                this.HeaderBar()
                this.TitleCard()
                this.DescriptionSection()
                if (this.resource.type === 'book') {
                  this.PriceComparison()
                }
                if (this.resource.url && this.resource.url.trim().length > 0) {
                  this.ExternalLink()
                }
                this.CommentTrigger()
                Column().height(40)
              }
            }
            .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(2)

            // 侧边推荐栏
            if (this.similarResources.length > 0) {
              Scroll() {
                Column() {
                  Text('📋 相似推荐')
                    .fontSize(this.bodyFontSize() - 1).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                    .width('100%').padding({ top: 12, bottom: 8 })

                  ForEach(this.similarResources, (item: ResourceItemModel) => {
                    Row() {
                      Column() {
                        Text(item.title).fontSize(this.bodyFontSize()).fontWeight(FontWeight.Medium)
                          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                        Row() {
                          if (item.tags && item.tags.length > 0) {
                            Text(item.tags[0]).fontSize(this.smallFontSize()).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                              .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(6)
                          }
                          Text(item.author).fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
                            .margin({ left: 6 })
                        }.margin({ top: 4 })
                      }.layoutWeight(1)
                      Text('›').fontSize(this.subtitleFontSize() + 2).fontColor(ColorTokens.textHint(this.isDarkMode))
                    }
                    .width('100%').padding(this.cardPadding())
                    .margin({ top: 6 })
                    .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
                    .onClick(() => {
                      router.replaceUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                    })
                  }, (item: ResourceItemModel) => item.id.toString())
                }
                .width('100%').padding({ left: 12, right: 12 })
              }
              .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
              .border({ width: { left: 1 }, color: ColorTokens.divider(this.isDarkMode) })
            }
          }
          .layoutWeight(1)
        } else {
          // 小屏：原样全屏滚动
          Scroll() {
            Column() {
              this.HeaderBar()
              this.TitleCard()
              this.DescriptionSection()
              if (this.resource.type === 'book') {
                this.PriceComparison()
              }
              if (this.resource.url && this.resource.url.trim().length > 0) {
                this.ExternalLink()
              }
              this.CommentTrigger()
              // 小屏：相似推荐在底部
              if (this.similarResources.length > 0) {
                this.SimilarRecommendations()
              }
              Column().height(40)
            }
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
        }
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .bindSheet(this.showComments, this.commentSheet(), {
      height: '75%',
      showClose: true,
      dragBar: true
    })
  }

  @Builder
  HeaderBar() {
    Row() {
      Text('←').fontSize(this.titleFontSize()).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .onClick(() => { router.back(); })
      Blank()
      Text(this.resource!.type === 'book' ? '📖' :
        this.resource!.type === 'video' ? '🎬' :
        this.resource!.type === 'software' ? '💻' : '📝').fontSize(this.subtitleFontSize() + 4)
        .sharedTransition('cover_' + this.resourceId, { duration: 300, curve: Curve.EaseInOut })
      Text(this.resource!.type === 'book' ? '书籍详情' :
        this.resource!.type === 'video' ? '视频详情' :
        this.resource!.type === 'software' ? '软件详情' : '教程详情')
        .fontSize(this.bodyFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 6 })
      Blank()
      Text(this.isSpeaking ? '🔊' : '🔈').fontSize(this.subtitleFontSize() + 6)
        .fontColor(ColorTokens.primary(this.isDarkMode)).margin({ right: 12 })
        .onClick(() => { this.toggleTts(); })
      Text('↗').fontSize(this.subtitleFontSize() + 6).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ right: 12 })
        .onClick(() => {
          if (this.resource) {
            this.shareHelper.shareResource(this.resourceId, this.resource.title);
          }
        })
      Text(this.isFavorited ? '★' : '☆')
        .fontSize(this.titleFontSize() + 6).fontColor(ColorTokens.primary(this.isDarkMode))
        .onClick(() => { this.toggleFavorite(); })
    }
    .width('100%').height(this.headerHeight()).padding({ left: this.contentPadding(), right: this.contentPadding() })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
  }

  @Builder
  TitleCard() {
    Column() {
      Text(this.resource!.title)
        .fontSize(this.titleFontSize()).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%')

      Row() {
        Text(this.resource!.author).fontSize(this.captionFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        if (this.resource!.publishDate) {
          Text(' · ').fontColor(ColorTokens.TEXT_DISABLED)
          Text(this.resource!.publishDate).fontSize(this.captionFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        }
      }.margin({ top: 8 })

      if (this.resource!.source) {
        Text('来源：' + this.resource!.source)
          .fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
      }

      if (this.resource!.tags && this.resource!.tags.length > 0) {
        Row() {
          ForEach(this.resource!.tags, (tag: string) => {
            Text(tag)
              .fontSize(this.smallFontSize()).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
              .borderRadius(10).margin({ right: 6, top: 6 })
          })
        }.width('100%').margin({ top: 8 })
      }
    }
    .width('100%').padding(this.cardPadding()).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
  }

  @Builder
  DescriptionSection() {
    Column() {
      Text('📖 详细介绍')
        .fontSize(this.subtitleFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      Text(this.resource!.description)
        .fontSize(this.bodyFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode))
        .lineHeight(this.bodyFontSize() + 9).margin({ top: 10 })
    }
    .width('100%').padding(this.cardPadding()).backgroundColor(ColorTokens.bgCard(this.isDarkMode))
    .margin({ top: 8 })
  }

  @Builder
  PriceComparison() {
    Column() {
      Text('💰 各平台价格对比')
        .fontSize(this.subtitleFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      Text('点击跳转购买').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })

      this.priceRow('京东', 'https://search.jd.com/Search?keyword=' + encodeURI(this.resource!.title), '#E74C3C')
      this.priceRow('当当', 'https://search.dangdang.com/?key=' + encodeURI(this.resource!.title), '#E74C3C')
      this.priceRow('淘宝', 'https://s.taobao.com/search?q=' + encodeURI(this.resource!.title), '#FF6600')
    }
    .width('100%').padding(this.cardPadding()).backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 8 })
  }

  @Builder
  ExternalLink() {
    Column() {
      Text('🔗 在线资源').fontSize(this.subtitleFontSize()).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary(this.isDarkMode))
      Row() {
        Text(this.resource!.url)
          .fontSize(this.captionFontSize()).fontColor(ColorTokens.primary(this.isDarkMode)).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }
      .width('100%').margin({ top: 10 })
      Row() {
        Text('应用内打开')
          .fontSize(this.captionFontSize()).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(12)
          .onClick(() => { this.openUrl(this.resource!.url); })
        Text('浏览器打开')
          .fontSize(this.captionFontSize()).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => { this.openInBrowser(this.resource!.url); })
      }.margin({ top: 10 })
    }
    .width('100%').padding(this.cardPadding()).backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 8 })
  }

  // 评论触发按钮（教程 §13.3 半模态）
  @Builder
  CommentTrigger() {
    Row() {
      Text('💬').fontSize(this.bodyFontSize() + 2)
      Text(this.cloudComments.length > 0 || this.comments.length > 0 ?
        ' 查看评论 (' + (this.cloudComments.length + this.comments.length).toString() + ')' :
        ' 写评论')
        .fontSize(this.bodyFontSize()).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      Blank()
      Text('›').fontSize(this.subtitleFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
    }
    .width('100%').padding(this.cardPadding())
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
    .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
    .onClick(() => { this.showComments = true; })
  }

  // 半模态评论面板内容
  @Builder
  commentSheet() {
    Column() {
      // 标题栏
      Row() {
        Text('评论').fontSize(this.subtitleFontSize()).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode))
        Blank()
        Text('✕').fontSize(this.subtitleFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
          .width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { this.showComments = false; })
      }
      .width('100%').padding({ left: 24, right: 8, top: 8 })

      // 评论输入
      this.CommentInput()

      // 评论列表
      Scroll() {
        Column() {
          this.CloudComments()
          if (this.comments.length > 0) {
            this.LocalComments()
          }
          Column().height(40)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }

  @Builder
  CommentInput() {
    Row() {
      TextInput({ text: this.newComment, placeholder: '写下你的评论...' })
        .fontSize(this.bodyFontSize()).layoutWeight(1).height(this.bodyFontSize() + 26)
        .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(20)
        .padding({ left: 14 })
        .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 20 })
        .onChange((value: string) => { this.newComment = value; })
      Text('发送').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold)
        .fontColor(this.newComment.trim() ? ColorTokens.primary(this.isDarkMode) : ColorTokens.TEXT_DISABLED)
        .margin({ left: 10 })
        .onClick(() => { this.submitComment(); })
    }
    .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), top: 12, bottom: 12 })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 8 })
  }

  @Builder
  CloudComments() {
    if (this.cloudComments.length > 0) {
      Column() {
        Row() {
          Text('💬 评论 (' + this.cloudComments.length.toString() + ')')
            .fontSize(this.bodyFontSize() - 1).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        }.width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), top: 12 })

        ForEach(this.cloudComments, (item: CommentItem) => {
          Column() {
            if (item.deleted === 1) {
              Text('该评论已被删除')
                .fontSize(this.bodyFontSize()).fontColor(ColorTokens.TEXT_DISABLED).lineHeight(20)
                .width('100%')
            } else {
              Row() {
                Text(item.nickname).fontSize(this.captionFontSize())
                  .fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                Text(' · ' + item.createTime).fontSize(this.smallFontSize())
                  .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 6 })
              }.width('100%')
              Text(item.content)
                .fontSize(this.bodyFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode)).lineHeight(20)
                .width('100%').margin({ top: 6 })
            }
            if (item.children && item.children.length > 0) {
              Column() {
                ForEach(item.children, (child: CommentItem) => {
                  Column() {
                    if (child.deleted === 1) {
                      Text('该评论已被删除')
                        .fontSize(this.captionFontSize()).fontColor(ColorTokens.TEXT_DISABLED).lineHeight(18)
                        .width('100%')
                    } else {
                      Row() {
                        Text(child.nickname).fontSize(this.captionFontSize() - 1)
                          .fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                        Text(' · ' + child.createTime).fontSize(this.smallFontSize() - 1)
                          .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 4 })
                      }.width('100%')
                      Text(child.content)
                        .fontSize(this.captionFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode)).lineHeight(18)
                        .width('100%').margin({ top: 4 })
                    }
                  }
                  .width('100%').padding(10)
                  .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(8)
                  .margin({ top: 6 })
                }, (child: CommentItem) => child.id.toString())
              }
              .width('100%').margin({ top: 6 })
              .padding({ left: 12 })
            }
          }
          .width('100%').padding(this.cardPadding())
          .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 6 })
        }, (item: CommentItem) => item.id.toString())
      }
      .width('100%').padding({ bottom: 12 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 4 })
    }
  }

  @Builder
  LocalComments() {
    Column() {
      ForEach(this.comments, (comment: Post) => {
        Column() {
          Row() {
            Text('👤').fontSize(this.captionFontSize())
            Text(comment.author).fontSize(this.captionFontSize())
              .fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .margin({ left: 4 })
            Blank()
            Row() {
              Text('👍').fontSize(this.captionFontSize())
              Text(comment.likes.toString()).fontSize(this.smallFontSize())
                .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 3 })
            }
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(10)
            .onClick(() => { this.likeComment(comment.id); })
          }.width('100%')
          Text(comment.content)
            .fontSize(this.captionFontSize()).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .lineHeight(20).width('100%').margin({ top: 8 })
        }
        .width('100%').padding(this.cardPadding())
        .backgroundColor(ColorTokens.bgPage(this.isDarkMode)).borderRadius(12)
        .margin({ top: 8 })
      })
    }
    .width('100%').padding(this.cardPadding()).backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 4 })
  }

  @Builder
  SimilarRecommendations() {
    Column() {
      Text('📋 相似推荐')
        .fontSize(this.bodyFontSize() - 1).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
        .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), top: 12 })

      ForEach(this.similarResources, (item: ResourceItemModel) => {
        Row() {
          Column() {
            Text(item.title).fontSize(this.bodyFontSize()).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
            Row() {
              if (item.tags && item.tags.length > 0) {
                Text(item.tags[0]).fontSize(this.smallFontSize()).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(6)
              }
              Text(item.author).fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
                .margin({ left: 6 })
            }.margin({ top: 4 })
          }.layoutWeight(1)
          Text('›').fontSize(this.subtitleFontSize() + 2).fontColor(ColorTokens.textHint(this.isDarkMode))
        }
        .width('100%').padding(this.cardPadding())
        .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 6 })
        .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
        .onClick(() => {
          router.replaceUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
        })
      }, (item: ResourceItemModel) => item.id.toString())
    }
    .width('100%').padding({ bottom: 12 })
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 4 })
  }

  @Builder
  priceRow(platform: string, url: string, color: string) {
    Row() {
      Text(platform)
        .fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold).fontColor(color)
      Blank()
      Text('查看价格 ›')
        .fontSize(this.captionFontSize()).fontColor(ColorTokens.primary(this.isDarkMode))
    }
    .width('100%').padding(12)
    .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(10)
    .margin({ top: 8 })
    .onClick(() => { this.openUrl(url); })
  }
}
