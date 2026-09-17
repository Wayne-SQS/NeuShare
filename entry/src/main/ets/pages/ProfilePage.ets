import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { FavoriteService } from '../services/FavoriteService';
import { ResourceItem as ResourceItemModel } from '../models/ResourceModel';
import { ResourceCard } from '../components/ResourceCard';
import { AuthApi, UserInfo } from '../api/AuthApi';
import { PostApi, PostVO } from '../api/PostApi';
import { CommentApi, MyCommentItem } from '../api/CommentApi';
import { UserApi } from '../api/UserApi';
import { Context } from '@ohos.abilityAccessCtrl';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Entry
@Component
struct ProfilePage {
  @State favorites: ResourceItemModel[] = [];
  @State historyResources: ResourceItemModel[] = [];
  @State favoriteCount: number = 0;
  @State activeTab: number = 0;
  @State searchKeyword: string = '';
  @State sortMode: SortMode = 'default';
  @State userName: string = '未登录';
  @State userNickname: string = '游客';
  @State userAvatar: string = '';
  @State userCollege: string = '';
  @State userGrade: number = 0;
  @State isLoggedIn: boolean = false;
  @State myPosts: PostVO[] = [];
  @State postCount: number = 0;
  @State myComments: MyCommentItem[] = [];
  @State commentCount: number = 0;
  @State followerCount: number = 0;
  @State followingCount: number = 0;
  @State myUserId: number = 0;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  private resourceService: ResourceService = ResourceService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private authStore: AuthStore = AuthStore.getInstance();
  private authApi: AuthApi = new AuthApi();
  private postApi: PostApi = new PostApi();
  private commentApi: CommentApi = new CommentApi();
  private userApi: UserApi = new UserApi();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.authStore.init(context);
    await this.loadData();
    await this.loadUserInfo();
    this.loadMyPosts();
    this.loadCommentStats();
    this.loadFollowStats();
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  async onPageShow(): Promise<void> {
    await this.loadData();
    await this.loadUserInfo();
    this.loadMyPosts();
    this.loadCommentStats();
    this.loadFollowStats();
    this.searchKeyword = '';
    this.sortMode = 'default';
  }

  async loadUserInfo(): Promise<void> {
    this.isLoggedIn = await this.authStore.isLoggedIn();
    if (this.isLoggedIn) {
      try {
        const resp = await this.authApi.getInfo();
        if (resp.code === 200 && resp.data) {
          const u: UserInfo = resp.data;
          this.userName = u.username;
          this.userNickname = u.nickname || u.username;
          this.userAvatar = u.avatarUrl || '';
          this.userCollege = u.college || '';
          this.userGrade = u.grade || 0;
          this.myUserId = u.id || 0;
        }
      } catch (e) {
        this.isLoggedIn = false;
      }
    }
  }

  async loadData(): Promise<void> {
    // 从后端 API 获取收藏列表
    const favResult = await this.favoriteService.getFavoriteResources(1, 100);
    this.favorites = favResult.items;
    this.favoriteCount = favResult.total;
    // 如果 API 没返回资源详情，用本地数据补充
    if (this.favorites.length === 0 && this.favoriteCount > 0) {
      const favIds = await this.favoriteService.getFavoriteIds();
      this.favorites = this.resourceService.getLocalResources().filter(r => favIds.has(r.id));
    }
    const historyIds = await this.favoriteService.getHistory();
    this.historyResources = historyIds
      .map(id => this.resourceService.getLocalResourceById(id))
      .filter(r => r !== undefined) as ResourceItemModel[];
  }

  async doLogout(): Promise<void> {
    await this.authStore.logout();
    this.isLoggedIn = false;
    this.userName = '未登录';
    this.userNickname = '游客';
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  getGradeLabel(): string {
    const labels: string[] = ['', '大一', '大二', '大三', '大四'];
    return (this.userGrade >= 1 && this.userGrade <= 4) ? labels[this.userGrade] : '';
  }

  getFilteredList(): ResourceItemModel[] {
    const source = this.activeTab === 0 ? this.favorites : this.historyResources;
    let result = source;
    // Search
    if (this.searchKeyword.trim()) {
      const kw = this.searchKeyword.toLowerCase().trim();
      result = result.filter(r =>
        r.title.toLowerCase().includes(kw) ||
        (r.tags && r.tags.some(t => t.toLowerCase().includes(kw))) ||
        r.description.toLowerCase().includes(kw) ||
        r.author.toLowerCase().includes(kw)
      );
    }
    // Sort
    if (this.sortMode === 'name') {
      result = [...result].sort((a, b) => a.title.localeCompare(b.title));
    } else if (this.sortMode === 'rating') {
      result = [...result].sort((a, b) => b.rating - a.rating);
    } else if (this.sortMode === 'date') {
      result = [...result].sort((a, b) => b.publishDate.localeCompare(a.publishDate));
    }
    return result;
  }

  async loadMyPosts(): Promise<void> {
    if (!this.isLoggedIn) return;
    try {
      const resp = await this.postApi.getUserPosts(1, 50);
      if (resp.code === 200 && resp.data) {
        this.myPosts = resp.data.records;
        this.postCount = resp.data.total;
      }
    } catch (e) {
      console.error('loadMyPosts failed: ' + JSON.stringify(e));
    }
  }

  async loadCommentStats(): Promise<void> {
    if (!this.isLoggedIn) return;
    try {
      const resp = await this.commentApi.getMyComments(1, 1);
      if (resp.code === 200 && resp.data) {
        this.commentCount = resp.data.total;
      }
    } catch (e) {
      console.error('loadCommentStats failed: ' + JSON.stringify(e));
    }
  }

  async loadMyComments(): Promise<void> {
    if (!this.isLoggedIn) return;
    try {
      const resp = await this.commentApi.getMyComments(1, 50);
      if (resp.code === 200 && resp.data) {
        this.myComments = resp.data.records;
        this.commentCount = resp.data.total;
      }
    } catch (e) {
      console.error('loadMyComments failed: ' + JSON.stringify(e));
    }
  }

  async loadFollowStats(): Promise<void> {
    if (!this.isLoggedIn || this.myUserId === 0) return;
    try {
      const profile = await this.userApi.getProfile(this.myUserId);
      if (profile.code === 200 && profile.data) {
        this.followerCount = profile.data.followerCount || 0;
        this.followingCount = profile.data.followingCount || 0;
      }
    } catch (e) {
      console.error('loadFollowStats failed: ' + JSON.stringify(e));
    }
  }

  formatTimeAgo(dateStr: string): string {
    if (!dateStr) return '';
    try {
      const then = new Date(dateStr.replace(' ', 'T') + 'Z').getTime();
      const now = Date.now();
      const diff = now - then;
      if (diff < 60000) return '刚刚';
      if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
      if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
      if (diff < 2592000000) return Math.floor(diff / 86400000) + '天前';
      return dateStr.substring(0, 10);
    } catch (e) {
      return dateStr.substring(0, 10);
    }
  }

  @Builder PostCardBuilder(post: PostVO) {
    Column() {
      Row() {
        Column() {
          Text(post.title)
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(post.content)
            .fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
          Row() {
            Text('❤ ' + post.likeCount).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode))
            Text('💬 ' + post.commentCount).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
            Text(this.formatTimeAgo(post.createTime)).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
          }.margin({ top: 8 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('›').fontSize(20).fontColor(ColorTokens.textDisabled(this.isDarkMode))
      }
      .width('100%').padding(16).alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
    .margin({ left: 24, right: 24, top: 8 })
    .border({ width: 1, color: '#08000000', radius: 14 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: post.id } });
    })
  }

  @Builder CommentCardBuilder(comment: MyCommentItem) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(comment.sourceType === 'resource' ? '📄' : '📝')
              .fontSize(12)
              .fontColor(comment.sourceType === 'resource' ?
                ColorTokens.resolve('#4A6BFF', '#FFFFFF', this.isDarkMode) :
                ColorTokens.resolve('#6BCB77', '#FFFFFF', this.isDarkMode))
            Text(comment.sourceTitle)
              .fontSize(13).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 })
          }
          Text(comment.content)
            .fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
          Row() {
            Text('❤ ' + comment.likeCount).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode))
            Text('💬 ' + comment.replyCount).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
            Text(this.formatTimeAgo(comment.createTime)).fontSize(11).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
          }.margin({ top: 6 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('›').fontSize(20).fontColor(ColorTokens.textDisabled(this.isDarkMode))
      }
      .width('100%').padding(16).alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
    .margin({ left: 24, right: 24, top: 8 })
    .border({ width: 1, color: '#08000000', radius: 14 })
    .onClick(() => {
      if (comment.sourceType === 'resource') {
        router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: comment.sourceId } });
      } else {
        router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: comment.sourceId } });
      }
    })
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('我的').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      }
      .width('100%').height(48).padding({ left: 24, right: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          // Profile card
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(72).height(72).borderRadius(36).backgroundColor(ColorTokens.resolve(ColorTokens.BG_AVATAR, ColorTokens.BG_AVATAR_DARK, this.isDarkMode))
              if (this.userAvatar) {
                Image(this.userAvatar).width(72).height(72).borderRadius(36).objectFit(ImageFit.Cover)
              } else {
                Text('👤').fontSize(36)
              }
            }
            Column() {
              Text(this.userNickname)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text(this.userCollege ? this.userCollege + ' · ' + this.getGradeLabel() : '东北大学')
                .fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }.margin({ left: 14 })
            Blank()
            if (this.isLoggedIn) {
              Text('编辑 ›').fontSize(13).fontColor(ColorTokens.primary(this.isDarkMode))
                .onClick(() => { router.pushUrl({ url: 'pages/EditProfilePage' }); })
            }
          }
          .width('100%').padding(20)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(18)
          .margin({ left: 24, right: 24, top: 16 })
          .shadow({ radius: 12, color: '#0E000000', offsetX: 0, offsetY: 3 })
          .border({ width: 1, color: '#08000000', radius: 18 })

          // Login/Logout row
          Row() {
            if (this.isLoggedIn) {
              Text('🔑 退出登录').fontSize(12).fontColor(ColorTokens.error(this.isDarkMode))
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.error(this.isDarkMode), '30'), radius: 14 })
                .onClick(() => { this.doLogout(); })
            } else {
              Text('🔑 登录账号').fontSize(12).fontColor(ColorTokens.primary(this.isDarkMode))
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '30'), radius: 14 })
                .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }); })
            }
            Blank()
          }
          .width('100%').padding({ left: 24, right: 24 }).margin({ top: 6 })

          // Stats cards
          Row() {
            Column() {
              Text(this.favoriteCount.toString())
                .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.primary(this.isDarkMode))
              Text('我的收藏').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(16)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text(this.historyResources.length.toString())
                .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.success(this.isDarkMode))
              Text('浏览历史').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(16).margin({ left: 8 })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text('📄').fontSize(new BpType<number>({ sm: 24, md: 26, lg: 28, xl: 36 }).getValue(this.currentBreakpoint) ?? 24)
              Text('我的资源').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(16).margin({ left: 8 })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .onClick(() => { router.pushUrl({ url: 'pages/MyResourcesPage' }); })
          }
          .width('100%').padding({ left: 24, right: 24 })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 10 })

          Row() {
            Column() {
              Text(this.postCount.toString())
                .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.warning(this.isDarkMode))
              Text('我的帖子').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(16)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .onClick(() => { this.activeTab = 2; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyPosts(); })

            Column() {
              Text(this.commentCount.toString())
                .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                .fontWeight(FontWeight.Bold).fontColor('#FF9500')
              Text('我的评论').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(16).margin({ left: 8 })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
            .onClick(() => { this.activeTab = 3; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyComments(); })
          }
          .width('100%').padding({ left: 24, right: 24 })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 8 })

          // Follower / Following stats row
          if (this.isLoggedIn) {
            Row() {
              Column() {
                Text(this.followerCount.toString())
                  .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                  .fontWeight(FontWeight.Bold).fontColor(ColorTokens.primary(this.isDarkMode))
                Text('粉丝').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
              }
              .layoutWeight(1).padding(16)
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
              .onClick(() => {
                router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 0 } });
              })

              Column() {
                Text(this.followingCount.toString())
                  .fontSize(new BpType<number>({ sm: 28, md: 30, lg: 32, xl: 40 }).getValue(this.currentBreakpoint) ?? 28)
                  .fontWeight(FontWeight.Bold).fontColor(ColorTokens.success(this.isDarkMode))
                Text('关注').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
              }
              .layoutWeight(1).padding(16).margin({ left: 8 })
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
              .onClick(() => {
                router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 1 } });
              })
            }
            .width('100%').padding({ left: 24, right: 24 })
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 8 })
          }

          // Tab pills
          Row() {
            Text('收藏')
              .fontSize(14).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 0 ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('浏览历史')
              .fontSize(14).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 1 ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('帖子')
              .fontSize(14).fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 2 ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 2 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 2; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyPosts(); })

            Text('评论')
              .fontSize(14).fontWeight(this.activeTab === 3 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 3 ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.activeTab === 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 3; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyComments(); })

            Blank()
          }
          .width('100%').padding({ left: 24 }).margin({ top: 16 })

          // Search bar — only for favorites (tab 0) and history (tab 1)
          if ((this.activeTab === 0 || this.activeTab === 1) && (this.getFilteredList().length > 0 || this.searchKeyword.trim())) {
            Row() {
              Text('🔍').fontSize(14)
              TextInput({ text: this.searchKeyword, placeholder: '搜索已收藏资源...' })
                .fontSize(13).layoutWeight(1).height(36)
                .backgroundColor('#00000000')
                .padding({ left: 8 })
                .onChange((value: string) => { this.searchKeyword = value; })
              if (this.searchKeyword) {
                Text('✕').fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode))
                  .onClick(() => { this.searchKeyword = ''; })
              }
            }
            .width('100%').height(40).padding({ left: 24, right: 24 })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
            .borderRadius(20)
            .margin({ left: 24, right: 24, top: 12 })

            // Sort chips
            Row() {
              SortChip({ label: '默认', active: this.sortMode === 'default',
                onSort: () => { this.sortMode = 'default'; } })
              SortChip({ label: '按名称', active: this.sortMode === 'name',
                onSort: () => { this.sortMode = 'name'; } })
              SortChip({ label: '按评分', active: this.sortMode === 'rating',
                onSort: () => { this.sortMode = 'rating'; } })
              SortChip({ label: '按时间', active: this.sortMode === 'date',
                onSort: () => { this.sortMode = 'date'; } })
            }
            .width('100%').padding({ left: 24, right: 24, top: 10, bottom: 4 })
          }

          // Content
          if (this.activeTab === 0) {
            if (this.favorites.length === 0) {
              Column() {
                Text('☆').fontSize(48).margin({ top: 60 })
                Text('还没有收藏').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
                Text('浏览资源时点击 ☆ 即可收藏').fontSize(13).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ top: 4 })
              }.width('100%')
            } else {
              if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
                Column() {
                  Text('🔍').fontSize(48).margin({ top: 60 })
                  Text('未找到「' + this.searchKeyword + '」').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
                }.width('100%')
              } else {
                if (this.currentBreakpoint === BreakpointTypeEnum.MD || this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
                  Grid() {
                    ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                      GridItem() {
                        ResourceCard({
                          resource: item,
                          isFavorite: true,
                          onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                        })
                      }
                    }, (item: ResourceItemModel) => item.id.toString())
                  }
                  .columnsTemplate(new BpType<string>({ md: '1fr 1fr', lg: '1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr')
                  .rowsGap(4).columnsGap(4)
                  .width('100%').padding({ left: 24, right: 24 })
                } else {
                  ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                    ResourceCard({
                      resource: item,
                      isFavorite: true,
                      onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                    })
                  }, (item: ResourceItemModel) => item.id.toString())
                }
              }
            }
          } else if (this.activeTab === 1) {
            if (this.historyResources.length === 0) {
              Column() {
                Text('🕐').fontSize(48).margin({ top: 60 })
                Text('还没有浏览记录').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
              }.width('100%')
            } else {
              if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
                Column() {
                  Text('🔍').fontSize(48).margin({ top: 60 })
                  Text('未找到「' + this.searchKeyword + '」').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
                }.width('100%')
              } else {
                if (this.currentBreakpoint === BreakpointTypeEnum.MD || this.currentBreakpoint === BreakpointTypeEnum.LG || this.currentBreakpoint === BreakpointTypeEnum.XL) {
                  Grid() {
                    ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                      GridItem() {
                        ResourceCard({
                          resource: item,
                          onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                        })
                      }
                    }, (item: ResourceItemModel) => item.id.toString())
                  }
                  .columnsTemplate(new BpType<string>({ md: '1fr 1fr', lg: '1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr' }).getValue(this.currentBreakpoint) ?? '1fr 1fr')
                  .rowsGap(4).columnsGap(4)
                  .width('100%').padding({ left: 24, right: 24 })
                } else {
                  ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                    ResourceCard({
                      resource: item,
                      onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                    })
                  }, (item: ResourceItemModel) => item.id.toString())
                }
              }
            }
          } else if (this.activeTab === 2) {
            // My Posts tab
            if (this.myPosts.length === 0) {
              Column() {
                Text('📝').fontSize(48).margin({ top: 60 })
                Text('还没有发布帖子').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
                Text('去社区发个帖子吧').fontSize(13).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ top: 4 })
              }.width('100%')
            } else {
              ForEach(this.myPosts, (item: PostVO) => {
                this.PostCardBuilder(item)
              }, (item: PostVO) => item.id.toString())
            }
          } else if (this.activeTab === 3) {
            // My Comments tab
            if (this.myComments.length === 0) {
              Column() {
                Text('💬').fontSize(48).margin({ top: 60 })
                Text('还没有评论').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
                Text('你的评论会在这里显示').fontSize(13).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ top: 4 })
              }.width('100%')
            } else {
              ForEach(this.myComments, (item: MyCommentItem) => {
                this.CommentCardBuilder(item)
              }, (item: MyCommentItem) => item.sourceType + '_' + item.id.toString())
            }
          }

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.9)
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(12)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => { this.onSort(); })
  }
}