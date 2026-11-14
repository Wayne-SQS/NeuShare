import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum, AppTheme, ThemeMode, BlurPerformance, FontScale, Radii, Spacing, ControlSize, Elevation, GridLayout, EmptyState, PageHeader, StateView, ViewState } from '@neushare/common';
import { ResourceService } from '../../services/ResourceService';
import { FavoriteService } from '../../services/FavoriteService';
import { ResourceItem as ResourceItemModel } from '../../models/ResourceModel';
import { ResourceCard } from '../../components/ResourceCard';
import { AuthApi, UserInfo } from '../../api/AuthApi';
import { UserApi } from '../../api/UserApi';
import { PostApi, PostVO } from '../../api/PostApi';
import { CommentApi, MyCommentItem } from '../../api/CommentApi';
import { Context } from '@ohos.abilityAccessCtrl';

type SortMode = 'default' | 'name' | 'rating' | 'date';

@Component
export struct ProfileTab {
  @Prop favoriteCount: number = 0;
  @Prop historyCount: number = 0;
  @State favorites: ResourceItemModel[] = [];
  @State historyResources: ResourceItemModel[] = [];
  @State activeTab: number = 0;
  @State searchKeyword: string = '';
  @State sortMode: SortMode = 'default';
  @State userName: string = '';
  @State userNickname: string = '游客';
  @State userAvatar: string = '';
  @State userCollege: string = '';
  @State userGrade: number = 0;
  @State isLoggedIn: boolean = false;
  @State dataReady: boolean = false;
  @State loadFailed: boolean = false;
  @State followerCount: number = 0;
  @State followingCount: number = 0;
  @State myPosts: PostVO[] = [];
  @State postCount: number = 0;
  @State myComments: MyCommentItem[] = [];
  @State commentCount: number = 0;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State appearOpacity: number = 0;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private resourceService: ResourceService = ResourceService.getInstance();

  // ── 响应式参数 ─────────────────────────────────────────
  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 576, lg: 656, xl: 900 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 44 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private headerHeight(): number {
    return new BpType<number>({ sm: 44, md: 48, lg: 52, xl: 60 }).getValue(this.currentBreakpoint) ?? 44;
  }

  private titleFontSize(): number {
    return new BpType<number>({ sm: FontScale.TITLE_SM, md: FontScale.TITLE_MD, lg: 26, xl: FontScale.DISPLAY_LG }).getValue(this.currentBreakpoint) ?? 20;
  }

  private subtitleFontSize(): number {
    return new BpType<number>({ sm: FontScale.SECTION, md: FontScale.TITLE_SM, lg: FontScale.HERO, xl: 32 }).getValue(this.currentBreakpoint) ?? 18;
  }

  private bodyFontSize(): number {
    return new BpType<number>({ sm: FontScale.BODY_SM, md: FontScale.SUBTITLE, lg: FontScale.SECTION, xl: FontScale.TITLE_MD }).getValue(this.currentBreakpoint) ?? 14;
  }

  private captionFontSize(): number {
    return new BpType<number>({ sm: FontScale.LABEL, md: FontScale.CAPTION, lg: FontScale.BODY, xl: 19 }).getValue(this.currentBreakpoint) ?? 12;
  }

  private smallFontSize(): number {
    return new BpType<number>({ sm: FontScale.MICRO, md: FontScale.LABEL, lg: FontScale.BODY_SM, xl: FontScale.SUBTITLE_MD }).getValue(this.currentBreakpoint) ?? 11;
  }

  private emptyIconSize(): number {
    return new BpType<number>({ sm: 40, md: 52, lg: 64, xl: 84 }).getValue(this.currentBreakpoint) ?? 40;
  }

  private emptyTitleSize(): number {
    return new BpType<number>({ sm: FontScale.BODY, md: FontScale.SECTION, lg: FontScale.TITLE_MD, xl: FontScale.DISPLAY }).getValue(this.currentBreakpoint) ?? 15;
  }
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private authStore: AuthStore = AuthStore.getInstance();
  private authApi: AuthApi = new AuthApi();
  private userApi: UserApi = new UserApi();
  private postApi: PostApi = new PostApi();
  private commentApi: CommentApi = new CommentApi();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.authStore.init(context);
    await this.loadUserInfo();
    await this.loadFollowStats();
    await this.loadFavorites();
    await this.loadHistory();
    this.loadMyPosts();
    this.loadCommentStats();
    this.dataReady = true;
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  async onPageShow(): Promise<void> {
    await this.loadUserInfo();
    await this.loadFollowStats();
    await this.loadFavorites();
    await this.loadHistory();
    this.loadMyPosts();
    this.loadCommentStats();
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
        }
      } catch (e) {
        this.isLoggedIn = false;
      }
    }
  }

  async loadFavorites(): Promise<void> {
    try {
      const favResult = await this.favoriteService.getFavoriteResources(1, 100);
      this.favorites = favResult.items;
      if (this.favorites.length === 0 && favResult.total > 0) {
        const favIds = await this.favoriteService.getFavoriteIds();
        this.favorites = this.resourceService.getLocalResources().filter(r => favIds.has(r.id));
      }
      this.loadFailed = false;
    } catch (e) {
      console.error('loadFavorites failed: ' + JSON.stringify(e));
      this.loadFailed = true;
    }
  }

  async loadHistory(): Promise<void> {
    const historyIds = await this.favoriteService.getHistory();
    const result: ResourceItemModel[] = [];
    for (let i = 0; i < historyIds.length; i++) {
      const r = this.resourceService.getLocalResourceById(historyIds[i]);
      if (r !== undefined) {
        result.push(r);
      }
    }
    this.historyResources = result;
  }

  async loadFollowStats(): Promise<void> {
    try {
      const isLoggedIn = await this.authStore.isLoggedIn();
      if (isLoggedIn) {
        const infoResp = await this.authApi.getInfo();
        if (infoResp.code === 200 && infoResp.data) {
          const userId = infoResp.data.id;
          const profileResp = await this.userApi.getProfile(userId);
          if (profileResp.code === 200 && profileResp.data) {
            this.followerCount = profileResp.data.followerCount || 0;
            this.followingCount = profileResp.data.followingCount || 0;
          }
        }
      }
    } catch (e) {
      console.error('loadFollowStats failed: ' + JSON.stringify(e));
    }
  }

  async doLogout(): Promise<void> {
    await this.authStore.logout();
    this.isLoggedIn = false;
    this.userName = '';
    this.userNickname = '游客';
    this.userAvatar = '';
    this.userCollege = '';
    this.userGrade = 0;
    this.favorites = [];
    this.historyResources = [];
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  getGradeLabel(): string {
    const labels: string[] = ['', '大一', '大二', '大三', '大四'];
    return (this.userGrade >= 1 && this.userGrade <= 4) ? labels[this.userGrade] : '';
  }

  getFilteredList(): ResourceItemModel[] {
    const source = this.activeTab === 0 ? this.favorites : this.historyResources;
    let result = source;
    if (this.searchKeyword.trim()) {
      const kw = this.searchKeyword.toLowerCase().trim();
      const filtered: ResourceItemModel[] = [];
      for (let i = 0; i < result.length; i++) {
        const r = result[i];
        if (r.title.toLowerCase().includes(kw) ||
          (r.tags && r.tags.some(t => t.toLowerCase().includes(kw))) ||
          r.description.toLowerCase().includes(kw) ||
          r.author.toLowerCase().includes(kw)) {
          filtered.push(r);
        }
      }
      result = filtered;
    }
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
            .fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(post.content)
            .fontSize(this.captionFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
          Row() {
            Text('赞 ' + post.likeCount).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode))
            Text('评论 ' + post.commentCount).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
            Text(this.formatTimeAgo(post.createTime)).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
          }.margin({ top: 6 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('›').fontSize(FontScale.TITLE_SM).fontColor(ColorTokens.textDisabled(this.isDarkMode))
      }
      .width('100%').padding(16).alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
    .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
    .border({ width: 1, color: ColorTokens.SHADOW_LIGHT, radius: Radii.XL })
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: post.id } });
    })
  }

  @Builder CommentCardBuilder(comment: MyCommentItem) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(comment.sourceType === 'resource' ? '资源' : '帖子')
              .fontSize(FontScale.TINY)
              .padding({ left: Spacing.XS, right: Spacing.XS, top: Spacing.XXS, bottom: Spacing.XXS })
              .borderRadius(Radii.XS)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
              .fontColor(comment.sourceType === 'resource' ?
                ColorTokens.resolve(ColorTokens.PRIMARY_LIGHT, ColorTokens.TEXT_WHITE, this.isDarkMode) :
                ColorTokens.resolve(ColorTokens.STATUS_SUCCESS_LIGHT, ColorTokens.TEXT_WHITE, this.isDarkMode))
            Text(comment.sourceTitle)
              .fontSize(this.captionFontSize()).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 })
          }
          Text(comment.content)
            .fontSize(this.captionFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
          Row() {
            Text('赞 ' + comment.likeCount).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode))
            Text('回复 ' + comment.replyCount).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
            Text(this.formatTimeAgo(comment.createTime)).fontSize(this.smallFontSize()).fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 12 })
          }.margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('›').fontSize(FontScale.TITLE_SM).fontColor(ColorTokens.textDisabled(this.isDarkMode))
      }
      .width('100%').padding(16).alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
    .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
    .border({ width: 1, color: ColorTokens.SHADOW_LIGHT, radius: Radii.XL })
    .onClick(() => {
      if (comment.sourceType === 'resource') {
        router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: comment.sourceId } });
      } else {
        router.pushUrl({ url: 'pages/PostDetailPage', params: { postId: comment.sourceId } });
      }
    })
  }

  @Builder
  statTile(value: string, label: string, color: string, onTapHandler: () => void) {
    Column() {
      Text(value)
        .fontSize(FontScale.HERO_SM)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(FontScale.CAPTION)
        .fontColor(ColorTokens.textHint(this.isDarkMode))
        .margin({ top: Spacing.XS })
    }
    .width('100%')
    .padding(Spacing.MD)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
    .borderRadius(Radii.CARD)
    .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
    .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
    .onClick(() => { onTapHandler(); })
  }

  build() {
    Column() {
      // Header
      PageHeader({ title: '我的', showBack: false })

      Scroll() {
        Column() {
          Column() {
          // Profile card — clickable to login/edit
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(64).height(64).borderRadius(Radii.PILL).backgroundColor(ColorTokens.resolve(ColorTokens.BG_AVATAR, ColorTokens.BG_AVATAR_DARK, this.isDarkMode))
              if (this.userAvatar) {
                Image(this.userAvatar).width(64).height(64).borderRadius(Radii.PILL).objectFit(ImageFit.Cover)
              } else {
                Text(this.isLoggedIn && this.userNickname ? this.userNickname.substring(0, 1) : '我')
                  .fontSize(FontScale.HERO).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.textSecondary(this.isDarkMode))
              }
            }
            Column() {
              Text(this.isLoggedIn ? this.userNickname : '点击登录')
                .fontSize(this.subtitleFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text(this.isLoggedIn && this.userCollege ?
                this.userCollege + ' · ' + this.getGradeLabel() : '东北大学')
                .fontSize(this.captionFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }.margin({ left: 12 })
            Blank()
            if (this.isLoggedIn) {
              Text('编辑资料').fontSize(this.captionFontSize()).fontColor(ColorTokens.primary(this.isDarkMode))
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), radius: Radii.CARD })
                .onClick(() => { router.pushUrl({ url: 'pages/EditProfilePage' }); })
            }
          }
          .width('100%').padding(new BpType<number>({ sm: 18, md: 20, lg: 24, xl: 36 }).getValue(this.currentBreakpoint) ?? 18)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 14 })
          .onClick(() => {
            if (!this.isLoggedIn) { router.pushUrl({ url: 'pages/LoginPage' }); }
          })

          // Logout
          if (this.isLoggedIn) {
            Row() {
              Text('退出登录').fontSize(this.smallFontSize()).fontColor(ColorTokens.error(this.isDarkMode))
                .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.error(this.isDarkMode), '25'), radius: Radii.LG })
                .onClick(() => { this.doLogout(); })
              Blank()
            }
            .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() }).margin({ top: 8 })
          }

          // Stats grid：xs 单列堆叠，sm 起两列以上
          GridRow({
            columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
            gutter: { x: Spacing.SM, y: Spacing.SM },
            breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
          }) {
            GridCol({ span: 1 }) {
              this.statTile(this.favorites.length.toString(), '我的收藏', ColorTokens.primary(this.isDarkMode), () => {
                this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default';
              })
            }
            GridCol({ span: 1 }) {
              this.statTile(this.historyResources.length.toString(), '浏览历史', ColorTokens.success(this.isDarkMode), () => {
                this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default';
              })
            }
            GridCol({ span: 1 }) {
              this.statTile('进入', '我的资源', ColorTokens.textSecondary(this.isDarkMode), () => {
                router.pushUrl({ url: 'pages/MyResourcesPage' });
              })
            }
            GridCol({ span: 1 }) {
              this.statTile(this.postCount.toString(), '我的帖子', ColorTokens.warning(this.isDarkMode), () => {
                this.activeTab = 2; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyPosts();
              })
            }
            GridCol({ span: 1 }) {
              this.statTile(this.commentCount.toString(), '我的评论', ColorTokens.statusWarning(this.isDarkMode), () => {
                this.activeTab = 3; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyComments();
              })
            }
            GridCol({ span: 1 }) {
              this.statTile(this.followerCount.toString(), '粉丝', ColorTokens.PURPLE, () => {
                router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 0 } });
              })
            }
            GridCol({ span: 1 }) {
              this.statTile(this.followingCount.toString(), '关注', ColorTokens.primary(this.isDarkMode), () => {
                router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 1 } });
              })
            }
          }
          .width('100%')
          .padding({ left: this.contentPadding(), right: this.contentPadding() })
          .margin({ top: Spacing.MD })

          // Stats entry
          Row() {
            Row().width(3).height(ControlSize.ICON_LG).borderRadius(Radii.XXS).backgroundColor(ColorTokens.primary(this.isDarkMode))
            Column() {
              Text('数据统计').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('分类分布 · 来源排行 · 热度Top10').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: Spacing.XXS })
            }.margin({ left: Spacing.MD }).layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text('查看').fontSize(this.captionFontSize()).fontColor(ColorTokens.primary(this.isDarkMode))
          }
          .width('100%').padding(Spacing.LG)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: Spacing.SM })
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
          .onClick(() => { router.pushUrl({ url: 'pages/StatsPage' }); })

          // 主题切换
          Row() {
            Text(this.isDarkMode ? '深' : '浅')
              .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            Column() {
              Text('外观主题').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text(this.isDarkMode ? '深色模式' : '亮色模式').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.margin({ left: 10 })
            Blank()
            // 三档切换按钮
            Row() {
              Text('浅色').fontSize(FontScale.CAPTION)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(Radii.MD)
                .backgroundColor(!this.isDarkMode ? ColorTokens.primary(this.isDarkMode) : ColorTokens.TRANSPARENT)
                .fontColor(!this.isDarkMode ? ColorTokens.TEXT_WHITE : ColorTokens.textHint(this.isDarkMode))
                .onClick(() => { AppTheme.getInstance().setThemeMode(ThemeMode.LIGHT); })
              Text('深色').fontSize(FontScale.CAPTION)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(Radii.MD)
                .backgroundColor(this.isDarkMode ? ColorTokens.primary(this.isDarkMode) : ColorTokens.TRANSPARENT)
                .fontColor(this.isDarkMode ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                .onClick(() => { AppTheme.getInstance().setThemeMode(ThemeMode.DARK); })
            }
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.LG)
          }
          .width('100%').padding(14)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
          .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
          .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })

          // Tab pills
          Row() {
            Text('收藏')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 0 ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(Radii.XXL)
              .backgroundColor(this.activeTab === 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('浏览历史')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 1 ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(Radii.XXL)
              .backgroundColor(this.activeTab === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('帖子')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 2 ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(Radii.XXL)
              .backgroundColor(this.activeTab === 2 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 2; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyPosts(); })

            Text('评论')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 3 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 3 ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(Radii.XXL)
              .backgroundColor(this.activeTab === 3 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 3; this.searchKeyword = ''; this.sortMode = 'default'; this.loadMyComments(); })

            Blank()
          }
          .width('100%').padding({ left: this.contentPadding() }).margin({ top: 14 })

          // Search + Sort — only for favorites (tab 0) and history (tab 1)
          if ((this.activeTab === 0 || this.activeTab === 1) && (this.getFilteredList().length > 0 || this.searchKeyword.trim())) {
            Row() {
              TextInput({ text: this.searchKeyword, placeholder: '搜索...' })
                .fontSize(this.captionFontSize()).layoutWeight(1).height(34)
                .backgroundColor(ColorTokens.TRANSPARENT).padding({ left: 8 })
                .onChange((value: string) => { this.searchKeyword = value; })
              if (this.searchKeyword) {
                Text('清除').fontSize(this.captionFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
                  .onClick(() => { this.searchKeyword = ''; })
              }
            }
            .width('100%').height(38).padding({ left: this.contentPadding(), right: this.contentPadding() })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.XXL)
            .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 14 })

            Row() {
              SortChip({ label: '默认', active: this.sortMode === 'default',
                onSort: () => { this.sortMode = 'default'; } })
              SortChip({ label: '名称', active: this.sortMode === 'name',
                onSort: () => { this.sortMode = 'name'; } })
              SortChip({ label: '评分', active: this.sortMode === 'rating',
                onSort: () => { this.sortMode = 'rating'; } })
              SortChip({ label: '时间', active: this.sortMode === 'date',
                onSort: () => { this.sortMode = 'date'; } })
            }
            .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding(), top: 8, bottom: 2 })
          }

          // Content
          if (!this.dataReady) {
            StateView({ state: ViewState.LOADING, hint: '正在加载...' })
          } else if (this.loadFailed) {
            StateView({
              state: ViewState.ERROR,
              message: '加载失败',
              hint: '请检查网络后重试',
              onRetry: () => { this.loadFavorites(); this.loadHistory(); }
            })
          } else if (this.activeTab === 0) {
            if (this.favorites.length === 0) {
              EmptyState({ message: '还没有收藏', hint: '浏览资源时点击收藏即可' })
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              EmptyState({ message: '未找到「' + this.searchKeyword + '」', hint: '换个关键词试试' })
            } else {
              GridRow({
                columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
                gutter: { x: Spacing.SM, y: Spacing.SM },
                breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
              }) {
                ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                  GridCol({ span: 1 }) {
                    ResourceCard({
                      resource: item,
                      isFavorite: true,
                      onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                    })
                  }
                }, (item: ResourceItemModel) => item.id.toString())
              }
              .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() })
            }
          } else if (this.activeTab === 1) {
            if (this.historyResources.length === 0) {
              EmptyState({ message: '还没有浏览记录', hint: '看过的资源会出现在这里' })
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              EmptyState({ message: '未找到「' + this.searchKeyword + '」', hint: '换个关键词试试' })
            } else {
              GridRow({
                columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
                gutter: { x: Spacing.SM, y: Spacing.SM },
                breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
              }) {
                ForEach(this.getFilteredList(), (item: ResourceItemModel) => {
                  GridCol({ span: 1 }) {
                    ResourceCard({
                      resource: item,
                      onTap: () => { router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } }); }
                    })
                  }
                }, (item: ResourceItemModel) => item.id.toString())
              }
              .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() })
            }
          } else if (this.activeTab === 2) {
            // My Posts tab
            if (this.myPosts.length === 0) {
              EmptyState({ message: '还没有发布帖子', hint: '去社区发个帖子吧' })
            } else {
              ForEach(this.myPosts, (item: PostVO) => {
                this.PostCardBuilder(item)
              }, (item: PostVO) => item.id.toString())
            }
          } else if (this.activeTab === 3) {
            // My Comments tab
            if (this.myComments.length === 0) {
              EmptyState({ message: '还没有评论', hint: '你的评论会在这里显示' })
            } else {
              ForEach(this.myComments, (item: MyCommentItem) => {
                this.CommentCardBuilder(item)
              }, (item: MyCommentItem) => item.sourceType + '_' + item.id.toString())
            }
          }

          // Bottom spacer
          Column().height(60)
          }
          .constraintSize({ maxWidth: this.maxContentWidth() })
          .width('100%')
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
      .onScrollFrameBegin(() => { BlurPerformance.onScrollStart(); return { offsetRemain: 0 }; })
      .onScrollStop(() => { BlurPerformance.onScrollStop(); })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(new BpType<number>({ sm: FontScale.MICRO, md: FontScale.LABEL, lg: FontScale.CAPTION, xl: FontScale.BODY }).getValue(this.currentBreakpoint) ?? FontScale.MICRO)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(Radii.XL)
      .margin({ right: 6 })
      .onClick(() => { this.onSort(); })
  }
}
