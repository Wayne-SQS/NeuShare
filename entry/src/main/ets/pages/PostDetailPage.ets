import router from '@ohos.router';
import { ColorTokens, BreakpointTypeEnum, AuthStore } from '@neushare/common';
import { CommunityService } from '../services/CommunityService';
import { Post, PostComment, PostFile, formatFileSize, fileIcon, toComment } from '../models/PostModel';
import { PostApi, PostCommentVO } from '../api/PostApi';
import curves from '@ohos.curves';
import promptAction from '@ohos.promptAction';
import { request } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

const BASE_URL: string = 'http://10.0.2.2:8080';

@Entry
@Component
struct PostDetailPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @State post: Post | null = null;
  @State comments: PostComment[] = [];
  @State commentText: string = '';
  @State replyToId: number = 0;
  @State likeBounce: boolean = false;
  @State favBounce: boolean = false;
  @State isSubmitting: boolean = false;
  @State currentUserId: number = 0;
  @State showDeleteConfirm: boolean = false;
  @State replyToName: string = '';
  @State commentLikedIds: Set<number> = new Set();
  private postId: number = 0;
  private communityService: CommunityService = CommunityService.getInstance();
  private postApi: PostApi = new PostApi();

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['postId']) {
      this.postId = params['postId'] as number;
    }
    const authStore = AuthStore.getInstance();
    const userInfo = await authStore.getUser();
    if (userInfo && userInfo['id']) {
      this.currentUserId = userInfo['id'] as number;
    }
    await this.loadPost();
    await this.loadComments();
  }

  async loadPost(): Promise<void> {
    this.post = await this.communityService.getPostDetail(this.postId);
  }

  async loadComments(): Promise<void> {
    try {
      const res = await this.postApi.getComments(this.postId);
      if (res.code === 200 && res.data) {
        this.comments = (res.data as PostCommentVO[]).map(vo => toComment(vo));
      }
    } catch (e) {
      console.error('loadComments failed: ' + JSON.stringify(e));
    }
  }

  async toggleLike(): Promise<void> {
    if (!this.post) return;
    const oldLiked = this.post.isLiked;
    const newLiked = !oldLiked;
    const newCount = this.post.likeCount + (newLiked ? 1 : -1);
    // 乐观更新：重新赋值整个对象触发 UI 刷新
    const p = this.post;
    this.post = {
      id: p.id,
      userId: p.userId,
      title: p.title,
      content: p.content,
      authorNickname: p.authorNickname,
      authorAvatarUrl: p.authorAvatarUrl,
      authorCollege: p.authorCollege,
      tags: p.tags,
      createTime: p.createTime,
      isRecommended: p.isRecommended,
      likeCount: newCount,
      favoriteCount: p.favoriteCount,
      commentCount: p.commentCount,
      viewCount: p.viewCount,
      imageUrls: p.imageUrls,
      files: p.files,
      status: p.status,
      isLiked: newLiked,
      isFavorited: p.isFavorited
    };
    this.likeBounce = true;
    setTimeout(() => { this.likeBounce = false; }, 300);
    try {
      const success = await this.communityService.likePost(this.post.id, oldLiked);
      if (!success) {
        // API 失败，回滚
        const cur = this.post;
        this.post = {
          id: cur.id, userId: cur.userId, title: cur.title, content: cur.content,
          authorNickname: cur.authorNickname, authorAvatarUrl: cur.authorAvatarUrl, authorCollege: cur.authorCollege,
          tags: cur.tags, createTime: cur.createTime, isRecommended: cur.isRecommended,
          likeCount: cur.likeCount + (oldLiked ? 1 : -1), favoriteCount: cur.favoriteCount,
          commentCount: cur.commentCount, viewCount: cur.viewCount, imageUrls: cur.imageUrls,
          files: cur.files, status: cur.status, isLiked: oldLiked, isFavorited: cur.isFavorited
        };
        promptAction.showToast({ message: '操作失败，已离线保存' });
      }
    } catch (e) {
      const cur = this.post;
      this.post = {
        id: cur.id, userId: cur.userId, title: cur.title, content: cur.content,
        authorNickname: cur.authorNickname, authorAvatarUrl: cur.authorAvatarUrl, authorCollege: cur.authorCollege,
        tags: cur.tags, createTime: cur.createTime, isRecommended: cur.isRecommended,
        likeCount: cur.likeCount + (oldLiked ? 1 : -1), favoriteCount: cur.favoriteCount,
        commentCount: cur.commentCount, viewCount: cur.viewCount, imageUrls: cur.imageUrls,
        files: cur.files, status: cur.status, isLiked: oldLiked, isFavorited: cur.isFavorited
      };
    }
  }

  async toggleFavorite(): Promise<void> {
    if (!this.post) return;
    const oldFav = this.post.isFavorited;
    const newFav = !oldFav;
    const newCount = this.post.favoriteCount + (newFav ? 1 : -1);
    // 乐观更新：重新赋值整个对象触发 UI 刷新
    const p = this.post;
    this.post = {
      id: p.id,
      userId: p.userId,
      title: p.title,
      content: p.content,
      authorNickname: p.authorNickname,
      authorAvatarUrl: p.authorAvatarUrl,
      authorCollege: p.authorCollege,
      tags: p.tags,
      createTime: p.createTime,
      isRecommended: p.isRecommended,
      likeCount: p.likeCount,
      favoriteCount: newCount,
      commentCount: p.commentCount,
      viewCount: p.viewCount,
      imageUrls: p.imageUrls,
      files: p.files,
      status: p.status,
      isLiked: p.isLiked,
      isFavorited: newFav
    };
    this.favBounce = true;
    setTimeout(() => { this.favBounce = false; }, 300);
    try {
      const success = await this.communityService.favoritePost(this.post.id, oldFav);
      if (!success) {
        const cur = this.post;
        this.post = {
          id: cur.id, userId: cur.userId, title: cur.title, content: cur.content,
          authorNickname: cur.authorNickname, authorAvatarUrl: cur.authorAvatarUrl, authorCollege: cur.authorCollege,
          tags: cur.tags, createTime: cur.createTime, isRecommended: cur.isRecommended,
          likeCount: cur.likeCount, favoriteCount: cur.favoriteCount + (oldFav ? 1 : -1),
          commentCount: cur.commentCount, viewCount: cur.viewCount, imageUrls: cur.imageUrls,
          files: cur.files, status: cur.status, isLiked: cur.isLiked, isFavorited: oldFav
        };
        promptAction.showToast({ message: '操作失败，已离线保存' });
      }
    } catch (e) {
      const cur = this.post;
      this.post = {
        id: cur.id, userId: cur.userId, title: cur.title, content: cur.content,
        authorNickname: cur.authorNickname, authorAvatarUrl: cur.authorAvatarUrl, authorCollege: cur.authorCollege,
        tags: cur.tags, createTime: cur.createTime, isRecommended: cur.isRecommended,
        likeCount: cur.likeCount, favoriteCount: cur.favoriteCount + (oldFav ? 1 : -1),
        commentCount: cur.commentCount, viewCount: cur.viewCount, imageUrls: cur.imageUrls,
        files: cur.files, status: cur.status, isLiked: cur.isLiked, isFavorited: oldFav
      };
    }
  }

  async submitComment(): Promise<void> {
    if (!this.commentText.trim() || this.isSubmitting) return;
    this.isSubmitting = true;
    const content: string = this.commentText.trim();
    const parentId: number = this.replyToId > 0 ? this.replyToId : 0;
    const replyName: string = this.replyToName;
    this.commentText = '';
    this.replyToId = 0;
    this.replyToName = '';
    // 乐观插入
    const optimistic: PostComment = {
      id: Date.now(),
      postId: this.postId,
      userId: this.currentUserId,
      content: content,
      parentId: parentId,
      deleted: 0,
      createTime: '刚刚',
      nickname: '我',
      avatarUrl: '',
      children: []
    };
    if (parentId === 0) {
      this.comments = [optimistic, ...this.comments];
    } else {
      const addChild = (list: PostComment[]): boolean => {
        for (let i = 0; i < list.length; i++) {
          if (list[i].id === parentId) {
            list[i].children = [optimistic, ...list[i].children];
            return true;
          }
          if (list[i].children && addChild(list[i].children)) return true;
        }
        return false;
      };
      addChild(this.comments);
    }
    // 发 API
    try {
      const res = await this.postApi.addComment(this.postId, content, parentId);
      if (res.code === 200) {
        await this.loadComments();
        await this.loadPost();
      } else {
        promptAction.showToast({ message: '发送失败: ' + (res.message || '请重试') });
        await this.loadComments();
      }
    } catch (e) {
      promptAction.showToast({ message: '发送失败，评论仅本地可见' });
    }
    this.isSubmitting = false;
  }

  async deleteComment(commentId: number): Promise<void> {
    try {
      const res = await this.postApi.deleteComment(commentId);
      if (res.code === 200) {
        await this.loadComments();
        await this.loadPost();
      } else {
        promptAction.showToast({ message: '删除失败: ' + (res.message || '请重试') });
      }
    } catch (e) {
      promptAction.showToast({ message: '删除失败，请检查网络' });
    }
  }

  async toggleCommentLike(commentId: number): Promise<void> {
    try {
      const liked = this.commentLikedIds.has(commentId);
      if (liked) {
        const res = await this.postApi.unlikeComment(commentId);
        if (res.code === 200) {
          this.commentLikedIds.delete(commentId);
          this.commentLikedIds = new Set(this.commentLikedIds);
        }
      } else {
        const res = await this.postApi.likeComment(commentId);
        if (res.code === 200) {
          this.commentLikedIds.add(commentId);
          this.commentLikedIds = new Set(this.commentLikedIds);
        }
      }
    } catch (e) {
      console.error('toggleCommentLike failed: ' + JSON.stringify(e));
    }
  }

  async downloadPostFile(file: PostFile): Promise<void> {
    try {
      const downloadUrl = BASE_URL + file.uri;
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const saveDir = ctx.filesDir + '/downloads';
      if (!fileIo.accessSync(saveDir)) {
        fileIo.mkdirSync(saveDir, true);
      }
      // 重名处理：自动加后缀 (1), (2)...
      let savePath = saveDir + '/' + file.name;
      const dotIdx = file.name.lastIndexOf('.');
      const baseName = dotIdx >= 0 ? file.name.substring(0, dotIdx) : file.name;
      const ext = dotIdx >= 0 ? file.name.substring(dotIdx) : '';
      let counter = 1;
      while (fileIo.accessSync(savePath)) {
        savePath = saveDir + '/' + baseName + '_' + counter + ext;
        counter++;
      }
      const savedName = savePath.substring(savePath.lastIndexOf('/') + 1);
      promptAction.showToast({ message: '开始下载: ' + file.name });
      const token = await AuthStore.getInstance().getToken();
      const headers: Record<string, string> = {};
      if (token) {
        headers['Authorization'] = 'Bearer ' + token;
      }
      const task = await request.downloadFile(ctx, {
        url: downloadUrl,
        filePath: savePath,
        header: headers
      });
      task.on('complete', () => {
        promptAction.showToast({ message: '已保存: ' + savedName, duration: 2000 });
        const ctx2 = this.getUIContext().getHostContext() as common.UIAbilityContext;
        AlertDialog.show({
          title: '下载完成',
          message: savedName + '\n已保存到本地',
          autoCancel: true,
          alignment: DialogAlignment.Center,
          primaryButton: {
            value: '打开',
            action: () => {
              try {
                const ext = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
                const mimeMap: Record<string, string> = {
                  '.pdf': 'application/pdf',
                  '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                  '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                  '.txt': 'text/plain', '.java': 'text/x-java', '.py': 'text/x-python',
                  '.sql': 'text/x-sql', '.zip': 'application/zip', '.mp4': 'video/mp4',
                  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg'
                };
                const want: Want = {
                  action: 'ohos.want.action.viewData',
                  uri: 'file://' + savePath,
                  type: mimeMap[ext] || 'application/octet-stream'
                };
                ctx2.startAbility(want);
              } catch (e) {
                console.error('open file failed: ' + JSON.stringify(e));
                promptAction.showToast({ message: '没有可打开此文件的应用' });
              }
            }
          },
          secondaryButton: {
            value: '完成',
            action: () => {}
          }
        });
      });
      task.on('fail', (code: number) => {
        promptAction.showToast({ message: '下载失败 (code: ' + code + ')' });
      });
    } catch (e) {
      console.error('downloadPostFile failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '下载失败，请检查网络' });
    }
  }

  async deletePost(): Promise<void> {
    if (!this.post) return;
    const success = await this.communityService.deletePost(this.post.id);
    if (success) {
      router.back();
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('帖子详情').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
        Blank()
        if (this.post && (this.post.userId === this.currentUserId)) {
          Row() {
            Text('编辑').fontSize(14).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(14)
              .onClick(() => { router.pushUrl({ url: 'pages/CreatePostPage', params: { editPostId: this.post!.id } }); })
            Text('删除').fontSize(14).fontColor(ColorTokens.error(this.isDarkMode))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(ColorTokens.withAlpha(ColorTokens.error(this.isDarkMode), '15')).borderRadius(14)
              .margin({ left: 8 })
              .onClick(() => { this.showDeleteConfirm = true; })
          }
        }
      }
      .width('100%').height(52).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      if (this.post) {
        Scroll() {
          Column() {
            // Author info
            Row() {
              Text('👤').fontSize(16)
              Text(this.post.authorNickname).fontSize(14).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 6 })
              Text('·').fontSize(14).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 8, right: 8 })
              Text(this.post.createTime).fontSize(12).fontColor(ColorTokens.textDisabled(this.isDarkMode))
              if (this.post.isRecommended) {
                Text('⚡ 已推荐').fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(8)
                  .margin({ left: 8 })
              }
            }.width('100%').margin({ bottom: 12 })

            // Title
            Text(this.post.title)
              .fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .width('100%')

            // Content
            Text(this.post.content)
              .fontSize(15).fontColor(ColorTokens.textSecondary(this.isDarkMode))
              .lineHeight(24).width('100%').margin({ top: 12 })

            // Images
            if (this.post.imageUrls && this.post.imageUrls.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.post.imageUrls, (url: string, idx: number) => {
                  Image(url).width('100%').height(200)
                    .borderRadius(12).objectFit(ImageFit.Cover)
                    .margin({ top: 8 })
                }, (url: string, idx: number) => 'img_' + idx.toString())
              }.width('100%').margin({ top: 8 })
            }

            // Files
            if (this.post.files && this.post.files.length > 0) {
              Column() {
                ForEach(this.post.files, (file: PostFile, idx: number) => {
                  Row() {
                    Text(fileIcon(file.type)).fontSize(18)
                    Column() {
                      Text(file.name).fontSize(13).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(file.type.toUpperCase().replace('.', '') + (file.size > 0 ? ' · ' + formatFileSize(file.size) : ''))
                        .fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ top: 2 })
                    }.margin({ left: 10 }).layoutWeight(1)
                    Text('⬇').fontSize(18).fontColor(ColorTokens.primary(this.isDarkMode))
                      .width(32).height(32).textAlign(TextAlign.Center)
                  }
                  .width('100%').padding(12)
                  .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(10)
                  .margin({ top: 6 })
                  .onClick(() => { this.downloadPostFile(file); })
                }, (file: PostFile, idx: number) => 'file_' + idx.toString() + '_' + file.name)
              }.width('100%').margin({ top: 8 })
            }

            // Tags
            if (this.post.tags && this.post.tags.length > 0) {
              Row() {
                ForEach(this.post.tags, (tag: string, idx: number) => {
                  Text(tag)
                    .fontSize(11).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                    .borderRadius(6).margin({ right: 6, top: 4 })
                }, (tag: string, idx: number) => 'tag_' + idx.toString())
              }.width('100%').margin({ top: 12 })
            }

            // Interaction bar
            Row() {
              Row() {
                Text(this.post.isLiked ? '👍' : '👍').fontSize(16)
                Text(this.post.likeCount.toString()).fontSize(14).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
              }
              .scale({ x: this.likeBounce ? 1.3 : 1, y: this.likeBounce ? 1.3 : 1 })
              .animation({ curve: Curve.EaseOut, duration: 200 })
              .padding({ left: 12, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.post.isLiked ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(16)
              .onClick(() => { this.toggleLike(); })

              Row() {
                Text(this.post.isFavorited ? '⭐' : '⭐').fontSize(16)
                Text(this.post.favoriteCount.toString()).fontSize(14).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
              }
              .scale({ x: this.favBounce ? 1.3 : 1, y: this.favBounce ? 1.3 : 1 })
              .animation({ curve: Curve.EaseOut, duration: 200 })
              .padding({ left: 12, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.post.isFavorited ? ColorTokens.accentLight(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode)).borderRadius(16)
              .margin({ left: 10 })
              .onClick(() => { this.toggleFavorite(); })

              Row() {
                Text('💬').fontSize(16)
                Text(this.post.commentCount.toString()).fontSize(14).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ left: 4 })
              }
              .padding({ left: 12, right: 14, top: 8, bottom: 8 })
              .margin({ left: 10 })
            }.width('100%').margin({ top: 16 })

            // ─── 评论区域 ───
            Divider().color(ColorTokens.divider(this.isDarkMode)).margin({ top: 20, bottom: 12 })
            Text('评论 (' + this.post.commentCount.toString() + ')')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .width('100%').margin({ bottom: 12 })

            // Comment input
            Row() {
              TextInput({ text: this.commentText, placeholder: this.replyToId > 0 ? '回复...' : '写评论...' })
                .fontSize(14).layoutWeight(1).height(40)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
                .onChange((value: string) => { this.commentText = value; })
              Text('发送')
                .fontSize(13).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(14)
                .margin({ left: 8 })
                .onClick(() => { this.submitComment(); })
            }.width('100%')

            if (this.replyToId > 0) {
              Row() {
                Text('↩ 回复 @' + this.replyToName).fontSize(12).fontColor(ColorTokens.primary(this.isDarkMode))
                Text('  取消').fontSize(12).fontColor(ColorTokens.error(this.isDarkMode))
                  .onClick(() => { this.replyToId = 0; this.replyToName = ''; })
              }.margin({ top: 4 })
            }

            // Comment tree
            if (this.comments.length > 0) {
              Column() {
                ForEach(this.comments, (comment: PostComment) => {
                  this.CommentItem(comment, 0)
                }, (comment: PostComment) => comment.id.toString())
              }.width('100%').margin({ top: 12 })
            } else {
              Text('暂无评论，快来抢沙发！').fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode))
                .margin({ top: 16 }).width('100%').textAlign(TextAlign.Center)
            }
          }
          .padding(20)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .align(Alignment.Top)
      } else {
        Column() {
          Text('📄').fontSize(48).margin({ top: 120 })
          Text('帖子不存在').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }

      // Delete confirmation overlay
      if (this.showDeleteConfirm) {
        Column() {
          Column() {
            Text('确认删除').fontSize(17).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ bottom: 8 })
            Text('删除后不可恢复，确定要删除这篇帖子吗？').fontSize(14)
              .fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ bottom: 16 })
            Row() {
              Text('取消').fontSize(15).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textSecondary(this.isDarkMode))
                .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(14)
                .layoutWeight(1).textAlign(TextAlign.Center)
                .onClick(() => { this.showDeleteConfirm = false; })
              Text('删除').fontSize(15).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.TEXT_WHITE)
                .padding({ left: 24, right: 24, top: 10, bottom: 10 })
                .backgroundColor(ColorTokens.error(this.isDarkMode)).borderRadius(14)
                .layoutWeight(1).textAlign(TextAlign.Center)
                .margin({ left: 12 })
                .onClick(() => { this.showDeleteConfirm = false; this.deletePost(); })
            }.width('100%')
          }
          .width('80%').padding(20)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(16)
        }
        .width('100%').height('100%')
        .backgroundColor(ColorTokens.withAlpha('#000000', '66'))
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }

  @Builder
  CommentItem(comment: PostComment, depth: number) {
    Column() {
      Row() {
        Text('👤').fontSize(14)
        Text(comment.deleted === 1 ? '已删除' : comment.nickname)
          .fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor(comment.deleted === 1 ? ColorTokens.textDisabled(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
          .margin({ left: 4 })
        Text('·').fontSize(12).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 6, right: 6 })
        Text(comment.createTime).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode))
        Blank()
        // 已删除的评论不显示操作按钮
        if (comment.deleted !== 1) {
          // 点赞
          Row() {
            Text(this.commentLikedIds.has(comment.id) ? '❤️' : '🤍').fontSize(13)
          }
          .margin({ right: 10 })
          .onClick(() => { this.toggleCommentLike(comment.id); })
          // 回复
          Text('回复').fontSize(11).fontColor(ColorTokens.primary(this.isDarkMode))
            .onClick(() => {
              this.replyToId = comment.id;
              this.replyToName = comment.nickname;
            })
          // 删除（仅自己或帖子作者的评论可删）
          if (comment.userId === this.currentUserId || (this.post && this.post.userId === this.currentUserId)) {
            Text('删除').fontSize(11).fontColor(ColorTokens.error(this.isDarkMode))
              .margin({ left: 10 })
              .onClick(() => { this.deleteComment(comment.id); })
          }
        }
      }.width('100%')

      Text(comment.deleted === 1 ? '该评论已被删除' : comment.content)
        .fontSize(14).fontColor(comment.deleted === 1 ? ColorTokens.textDisabled(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
        .width('100%').margin({ top: 6, left: 22 })

      // Children (replies) — 始终显示，即使父评论已删除
      if (comment.children && comment.children.length > 0) {
        Column() {
          ForEach(comment.children, (child: PostComment) => {
            this.CommentItem(child, depth + 1)
          }, (child: PostComment) => child.id.toString())
        }
        .width('100%').margin({ left: 22, top: 8 })
        .padding({ left: 10 })
        .border({ width: { left: 2 }, color: ColorTokens.divider(this.isDarkMode) })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right).opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left).opacity(0.9)
  }
}
