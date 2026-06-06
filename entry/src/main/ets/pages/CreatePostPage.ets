import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { CommunityService } from '../services/CommunityService';
import { Post } from '../models/PostModel';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct CreatePostPage {
  @State title: string = '';
  @State content: string = '';
  @State author: string = '';
  @State tags: string = '';
  @State isSubmitting: boolean = false;
  private communityService: CommunityService = CommunityService.getInstance();

  async submitPost(): Promise<void> {
    if (!this.title.trim() || !this.content.trim() || this.isSubmitting) return;
    this.isSubmitting = true;

    const post: Post = {
      id: Date.now().toString(),
      title: this.title.trim(),
      content: this.content.trim(),
      author: this.author.trim() || '匿名',
      tags: this.tags.trim()
        ? this.tags.split(/[,，\s]+/).filter((t: string) => t.length > 0)
        : [],
      createdAt: new Date().toISOString().slice(0, 10),
      recommended: false,
      likes: 0,
      favorites: 0,
      commentsCount: 0
    };

    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.communityService.init(context);
      await this.communityService.createPost(post);
    } catch (e) {
      console.error('CreatePostPage submit failed: ' + JSON.stringify(e));
    }

    router.back();
  }

  aboutToAppear(): void {}

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Blank()
        Text('发布帖子').fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
        Blank()
        Text(this.title.trim() && this.content.trim() ? '发布' : '发布')
          .fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(this.title.trim() && this.content.trim() ? ColorTokens.PRIMARY : ColorTokens.TEXT_DISABLED)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.title.trim() && this.content.trim() ? ColorTokens.PRIMARY_LIGHT : ColorTokens.BG_INPUT)
          .onClick(() => { this.submitPost(); })
      }
      .width('100%').height(52).padding({ left: 12, right: 12 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Author
          Row() {
            Text('👤').fontSize(16)
            TextInput({ text: this.author, placeholder: '你的昵称（选填，默认「匿名」）' })
              .fontSize(14).layoutWeight(1).height(46)
              .backgroundColor(ColorTokens.BG_PAGE)
              .onChange((value: string) => { this.author = value; })
          }
          .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(ColorTokens.BG_CARD)

          Divider().color(ColorTokens.DIVIDER)

          // Title
          TextInput({ text: this.title, placeholder: '帖子标题...' })
            .fontSize(17).fontWeight(FontWeight.Bold)
            .width('100%').height(52)
            .backgroundColor(ColorTokens.BG_PAGE)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.title = value; })

          Divider().color(ColorTokens.DIVIDER)

          // Content
          TextArea({ text: this.content, placeholder: '分享你的学习心得、问题、资源...' })
            .fontSize(15).lineHeight(22)
            .width('100%').height(240)
            .backgroundColor(ColorTokens.BG_PAGE)
            .padding(16)
            .onChange((value: string) => { this.content = value; })

          Divider().color(ColorTokens.DIVIDER)

          // Tags
          TextInput({ text: this.tags, placeholder: '标签（逗号分隔，如：高数, 期末, 题库）' })
            .fontSize(14)
            .width('100%').height(48)
            .backgroundColor(ColorTokens.BG_PAGE)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.tags = value; })

          if (this.tags.trim().length > 0) {
            Row() {
              ForEach(
                this.tags.split(/[,，\s]+/).filter((t: string) => t.length > 0),
                (tag: string) => {
                  Text(tag)
                    .fontSize(12).fontColor(ColorTokens.PRIMARY)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                    .borderRadius(10).margin({ right: 6, top: 6 })
                }
              )
            }.width('100%').padding({ left: 16, right: 16 }).margin({ top: 8 })
          }

          Column().height(60)
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
