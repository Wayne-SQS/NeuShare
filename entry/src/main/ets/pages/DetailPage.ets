import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { CommunityService } from '../services/CommunityService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { Post } from '../models/PostModel';
import { Context } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
struct DetailPage {
  @State resource: ResourceItemModel | null = null;
  @State isFavorited: boolean = false;
  @State comments: Post[] = [];
  private resourceId: number = 0;
  private resourceService: ResourceService = ResourceService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private communityService: CommunityService = CommunityService.getInstance();

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.resourceId = params['resourceId'] as number;
    }
    const res = this.resourceService.getResourceById(this.resourceId);
    if (res) {
      this.resource = res;
      const context = this.getUIContext().getHostContext() as Context;
      await this.favoriteService.init(context);
      await this.communityService.init(context);
      this.isFavorited = await this.favoriteService.isFavorite(this.resourceId);
      await this.favoriteService.addHistory(this.resourceId);
      await this.loadComments();
    }
  }

  async loadComments(): Promise<void> {
    const allPosts = await this.communityService.getAllPosts();
    this.comments = allPosts.filter(p =>
      p.tags.some(t => t.includes(this.resourceId.toString()))
    );
  }

  async toggleFavorite(): Promise<void> {
    const isFav = await this.favoriteService.toggleFavorite(this.resourceId);
    this.isFavorited = isFav;
  }

  async likeComment(postId: string): Promise<void> {
    await this.communityService.likePost(postId);
    await this.loadComments();
  }

  openUrl(url: string): void {
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
        Scroll() {
          Column() {
            // ── Header bar ──
            Row() {
              Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
                .onClick(() => { router.back(); })
              Blank()
              Text(this.resource.type === 'book' ? '📖' :
                this.resource.type === 'video' ? '🎬' :
                this.resource.type === 'software' ? '💻' : '📝').fontSize(20)
              Text(this.resource.type === 'book' ? '书籍详情' :
                this.resource.type === 'video' ? '视频详情' :
                this.resource.type === 'software' ? '软件详情' : '教程详情')
                .fontSize(16).fontColor(ColorTokens.TEXT_SECONDARY).margin({ left: 6 })
              Blank()
              Text(this.isFavorited ? '★' : '☆')
                .fontSize(28).fontColor(ColorTokens.ACCENT)
                .onClick(() => { this.toggleFavorite(); })
            }
            .width('100%').height(48).padding({ left: 16, right: 16 })
            .backgroundColor(ColorTokens.BG_CARD)

            // ── Title card ──
            Column() {
              Text(this.resource.title)
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.TEXT_PRIMARY).width('100%')

              Row() {
                Text(this.resource.author).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
                if (this.resource.publishDate) {
                  Text(' · ').fontColor(ColorTokens.TEXT_DISABLED)
                  Text(this.resource.publishDate).fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
                }
              }.margin({ top: 8 })

              if (this.resource.source) {
                Text('来源：' + this.resource.source)
                  .fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
              }

              if (this.resource.tags.length > 0) {
                Row() {
                  ForEach(this.resource.tags, (tag: string) => {
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

            // ── Description ──
            Column() {
              Text('📖 详细介绍')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text(this.resource.description)
                .fontSize(14).fontColor(ColorTokens.TEXT_SECONDARY)
                .lineHeight(23).margin({ top: 10 })
            }
            .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD)
            .margin({ top: 8 })

            // ── Price comparison (books only) ──
            if (this.resource.type === 'book') {
              Column() {
                Text('💰 各平台价格对比')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                Text('点击跳转购买').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 2 })

                this.priceRow('京东', 'https://search.jd.com/Search?keyword=' + encodeURI(this.resource.title), '#E74C3C')
                this.priceRow('当当', 'https://search.dangdang.com/?key=' + encodeURI(this.resource.title), '#E74C3C')
                this.priceRow('淘宝', 'https://s.taobao.com/search?q=' + encodeURI(this.resource.title), '#FF6600')
              }
              .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })
            }

            // ── External link ──
            if (this.resource.url && this.resource.url.trim().length > 0) {
              Column() {
                Text('🔗 在线资源').fontSize(16).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.TEXT_PRIMARY)
                Row() {
                  Text(this.resource.url)
                    .fontSize(12).fontColor(ColorTokens.PRIMARY).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                  Text('打开 ›').fontSize(13).fontColor('#FFFFFF')
                    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                    .backgroundColor(ColorTokens.PRIMARY).borderRadius(12)
                    .onClick(() => { this.openUrl(this.resource!.url); })
                }
                .width('100%').margin({ top: 10 })
                .padding(12).backgroundColor(ColorTokens.BG_INPUT).borderRadius(12)
              }
              .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })
            }

            // ── Comments section ──
            Column() {
              Row() {
                Text('💬 评论 (' + this.comments.length.toString() + ')')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              }.width('100%')

              if (this.comments.length === 0) {
                Text('暂无评论，去社区聊聊这本书？')
                  .fontSize(13).fontColor(ColorTokens.TEXT_HINT)
                  .margin({ top: 16 }).width('100%').textAlign(TextAlign.Center)
              } else {
                ForEach(this.comments, (comment: Post) => {
                  Column() {
                    Row() {
                      Text('👤').fontSize(12)
                      Text(comment.author).fontSize(13)
                        .fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                        .margin({ left: 4 })
                      Text('·').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED)
                        .margin({ left: 6, right: 6 })
                      Text(comment.createdAt).fontSize(11).fontColor(ColorTokens.TEXT_DISABLED)
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
            }
            .width('100%').padding(16).backgroundColor(ColorTokens.BG_CARD).margin({ top: 8 })

            Column().height(40)
          }
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
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
