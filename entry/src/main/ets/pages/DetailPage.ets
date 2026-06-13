import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils, BreakpointTypeEnum } from '@neushare/common';
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
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private resourceId: number = 0;
  private resourceService: ResourceService = ResourceService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();
  private commentApi: CommentApi = new CommentApi();
  private recommendService: RecommendService = RecommendService.getInstance();
  private ttsService: TtsService = TtsService.getInstance();
  private shareHelper: ShareHelper = ShareHelper.getInstance();

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
  }

  async loadDetailFromApi(): Promise<void> {
    const res = await this.resourceService.fetchResourceDetail(this.resourceId);
    if (res) {
      this.resource = res;
    }
    // 加载相似推荐
    this.similarResources = this.recommendService.getSimilarResources(this.resourceId, 4);
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
        Column() { Text('加载中...').fontSize(16).fontColor(ColorTokens.TEXT_HINT) }
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
                this.CommentInput()
                this.CloudComments()
                if (this.comments.length > 0) {
                  this.LocalComments()
                }
                Column().height(40)
              }
            }
            .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(2)

            // 侧边推荐栏
            if (this.similarResources.length > 0) {
              Scroll() {
                Column() {
                  Text('📋 相似推荐')
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                    .width('100%').padding({ top: 12, bottom: 8 })

                  ForEach(this.similarResources, (item: ResourceItemModel) => {
                    Row() {
                      Column() {
                        Text(item.title).fontSize(14).fontWeight(FontWeight.Medium)
                          .fontColor(ColorTokens.TEXT_PRIMARY).maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                        Row() {
                          if (item.tags && item.tags.length > 0) {
                            Text(item.tags[0]).fontSize(11).fontColor(ColorTokens.PRIMARY)
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                              .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(6)
                          }
                          Text(item.author).fontSize(11).fontColor(ColorTokens.TEXT_HINT)
                            .margin({ left: 6 })
                        }.margin({ top: 4 })
                      }.layoutWeight(1)
                      Text('›').fontSize(18).fontColor(ColorTokens.TEXT_HINT)
                    }
                    .width('100%').padding(14)
                    .margin({ top: 6 })
                    .backgroundColor('#F5F5F5').borderRadius(12)
                    .onClick(() => {
                      router.replaceUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                    })
                  }, (item: ResourceItemModel) => item.id.toString())
                }
                .width('100%').padding({ left: 12, right: 12 })
              }
              .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
              .backgroundColor(ColorTokens.BG_CARD)
              .border({ width: { left: 1 }, color: ColorTokens.DIVIDER })
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
              this.CommentInput()
              this.CloudComments()
              if (this.comments.length > 0) {
                this.LocalComments()
              }
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
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }

  @Builder
  HeaderBar() {
    Row() {
      Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
        .onClick(() => { router.back(); })
      Blank()
      Text(this.resource!.type === 'book' ? '📖' :
        this.resource!.type === 'video' ? '🎬' :
        this.resource!.type === 'software' ? '💻' : '📝').fontSize(20)
      Text(this.resource!.type === 'book' ? '书籍详情' :
        this.resource!.type === 'video' ? '视频详情' :
        this.resource!.type === 'software' ? '软件详情' : '教程详情')
        .fontSize(16).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 6 })
      Blank()
      Text(this.isSpeaking ? '🔊' : '🔈').fontSize(22)
        .fontColor(ColorTokens.PRIMARY).margin({ right: 12 })
        .onClick(() => { this.toggleTts(); })
      Text('↗').fontSize(22).fontColor(ColorTokens.TEXT_SECONDARY).margin({ right: 12 })
        .onClick(() => {
          if (this.resource) {
            this.shareHelper.shareResource(this.resourceId, this.resource.title);
          }
        })
      Text(this.isFavorited ? '★' : '☆')
        .fontSize(28).fontColor(ColorTokens.ACCENT)
        .onClick(() => { this.toggleFavorite(); })
    }
    .width('100%').height(48).padding({ left: 16, right: 16 })
    .backgroundColor(ColorTokens.BG_CARD)
  }

  @Builder
  TitleCard() {
    Column() {
      Text(this.resource!.title)
        .fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.TEXT_PRIMARY).width('100%')

      Row() {
        Text(this.resource!.author).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
        if (this.resource!.publishDate) {
          Text(' · ').fontColor(ColorTokens.TEXT_DISABLED)
          Text(this.resource!.publishDate).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
        }
      }.margin({ top: 8 })

      if (this.resource!.source) {
        Text('来源：' + this.resource!.source)
          .fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
      }

      if (this.resource!.tags && this.resource!.tags.length > 0) {
        Row() {
          ForEach(this.resource!.tags, (tag: string) => {
            Text(tag)
              .fontSize(11).fontColor(ColorTokens.PRIMARY)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(ColorTokens.PRIMARY_LIGHT)
              .borderRadius(10).margin({ right: 6, top: 6 })
          })
        }.width('100%').margin({ top: 8 })
      }
    }
    .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD)
  }

  @Builder
  DescriptionSection() {
    Column() {
      Text('📖 详细介绍')
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      Text(this.resource!.description)
        .fontSize(14).fontColor(ColorTokens.TEXT_SECONDARY)
        .lineHeight(23).margin({ top: 10 })
    }
    .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD)
    .margin({ top: 8 })
  }

  @Builder
  PriceComparison() {
    Column() {
      Text('💰 各平台价格对比')
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      Text('点击跳转购买').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })

      this.priceRow('京东', 'https://search.jd.com/Search?keyword=' + encodeURI(this.resource!.title), '#E74C3C')
      this.priceRow('当当', 'https://search.dangdang.com/?key=' + encodeURI(this.resource!.title), '#E74C3C')
      this.priceRow('淘宝', 'https://s.taobao.com/search?q=' + encodeURI(this.resource!.title), '#FF6600')
    }
    .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })
  }

  @Builder
  ExternalLink() {
    Column() {
      Text('🔗 在线资源').fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.TEXT_PRIMARY)
      Row() {
        Text(this.resource!.url)
          .fontSize(12).fontColor(ColorTokens.PRIMARY).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }
      .width('100%').margin({ top: 10 })
      Row() {
        Text('应用内打开')
          .fontSize(13).fontColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.PRIMARY).borderRadius(12)
          .onClick(() => { this.openUrl(this.resource!.url); })
        Text('浏览器打开')
          .fontSize(13).fontColor(ColorTokens.PRIMARY)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(12)
          .margin({ left: 10 })
          .onClick(() => { this.openInBrowser(this.resource!.url); })
      }.margin({ top: 10 })
    }
    .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })
  }

  @Builder
  CommentInput() {
    Row() {
      TextInput({ text: this.newComment, placeholder: '写下你的评论...' })
        .fontSize(14).layoutWeight(1).height(40)
        .backgroundColor('#F5F5F5').borderRadius(20)
        .padding({ left: 14 })
        .border({ width: 1, color: '#EEEEEE', radius: 20 })
        .onChange((value: string) => { this.newComment = value; })
      Text('发送').fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(this.newComment.trim() ? '#FF5A5F' : '#CCCCCC')
        .margin({ left: 10 })
        .onClick(() => { this.submitComment(); })
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })
  }

  @Builder
  CloudComments() {
    if (this.cloudComments.length > 0) {
      Column() {
        Row() {
          Text('💬 评论 (' + this.cloudComments.length.toString() + ')')
            .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#000000')
        }.width('100%').padding({ left: 16, right: 16, top: 12 })

        ForEach(this.cloudComments, (item: CommentItem) => {
          Column() {
            if (item.deleted === 1) {
              Text('该评论已被删除')
                .fontSize(14).fontColor('#BBBBBB').lineHeight(20)
                .width('100%')
            } else {
              Row() {
                Text(item.nickname).fontSize(13)
                  .fontWeight(FontWeight.Bold).fontColor('#000000')
                Text(' · ' + item.createTime).fontSize(11)
                  .fontColor('#999999').margin({ left: 6 })
              }.width('100%')
              Text(item.content)
                .fontSize(14).fontColor('#444444').lineHeight(20)
                .width('100%').margin({ top: 6 })
            }
            if (item.children && item.children.length > 0) {
              Column() {
                ForEach(item.children, (child: CommentItem) => {
                  Column() {
                    if (child.deleted === 1) {
                      Text('该评论已被删除')
                        .fontSize(13).fontColor('#BBBBBB').lineHeight(18)
                        .width('100%')
                    } else {
                      Row() {
                        Text(child.nickname).fontSize(12)
                          .fontWeight(FontWeight.Bold).fontColor('#333333')
                        Text(' · ' + child.createTime).fontSize(10)
                          .fontColor('#999999').margin({ left: 4 })
                      }.width('100%')
                      Text(child.content)
                        .fontSize(13).fontColor('#555555').lineHeight(18)
                        .width('100%').margin({ top: 4 })
                    }
                  }
                  .width('100%').padding(10)
                  .backgroundColor('#FFFFFF').borderRadius(8)
                  .margin({ top: 6 })
                }, (child: CommentItem) => child.id.toString())
              }
              .width('100%').margin({ top: 6 })
              .padding({ left: 12 })
            }
          }
          .width('100%').padding(14)
          .backgroundColor('#F9F9F9').borderRadius(12)
          .margin({ left: 16, right: 16, top: 6 })
        }, (item: CommentItem) => item.id.toString())
      }
      .width('100%').padding({ bottom: 12 })
      .backgroundColor(ColorTokens.BG_CARD).margin({ top: 4 })
    }
  }

  @Builder
  LocalComments() {
    Column() {
      ForEach(this.comments, (comment: Post) => {
        Column() {
          Row() {
            Text('👤').fontSize(12)
            Text(comment.author).fontSize(13)
              .fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              .margin({ left: 4 })
            Blank()
            Row() {
              Text('👍').fontSize(12)
              Text(comment.likes.toString()).fontSize(11)
                .fontColor(ColorTokens.TEXT_HINT).margin({ left: 3 })
            }
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
            .onClick(() => { this.likeComment(comment.id); })
          }.width('100%')
          Text(comment.content)
            .fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
            .lineHeight(20).width('100%').margin({ top: 8 })
        }
        .width('100%').padding(14)
        .backgroundColor(ColorTokens.BG_PAGE).borderRadius(12)
        .margin({ top: 8 })
      })
    }
    .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 4 })
  }

  @Builder
  SimilarRecommendations() {
    Column() {
      Text('📋 相似推荐')
        .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#000000')
        .width('100%').padding({ left: 16, right: 16, top: 12 })

      ForEach(this.similarResources, (item: ResourceItemModel) => {
        Row() {
          Column() {
            Text(item.title).fontSize(14).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.TEXT_PRIMARY).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
            Row() {
              if (item.tags && item.tags.length > 0) {
                Text(item.tags[0]).fontSize(11).fontColor(ColorTokens.PRIMARY)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(6)
              }
              Text(item.author).fontSize(11).fontColor(ColorTokens.TEXT_HINT)
                .margin({ left: 6 })
            }.margin({ top: 4 })
          }.layoutWeight(1)
          Text('›').fontSize(18).fontColor(ColorTokens.TEXT_HINT)
        }
        .width('100%').padding(14)
        .margin({ left: 16, right: 16, top: 6 })
        .backgroundColor('#F5F5F5').borderRadius(12)
        .onClick(() => {
          router.replaceUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
        })
      }, (item: ResourceItemModel) => item.id.toString())
    }
    .width('100%').padding({ bottom: 12 })
    .backgroundColor(ColorTokens.BG_CARD).margin({ top: 4 })
  }

  @Builder
  priceRow(platform: string, url: string, color: string) {
    Row() {
      Text(platform)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor(color)
      Blank()
      Text('查看价格 ›')
        .fontSize(12).fontColor(ColorTokens.PRIMARY)
    }
    .width('100%').padding(12)
    .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
    .margin({ top: 8 })
    .onClick(() => { this.openUrl(url); })
  }
}
