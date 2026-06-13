import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum, AppTheme, ThemeMode } from '@neushare/common';
import { ResourceService } from '../../services/ResourceService';
import { FavoriteService } from '../../services/FavoriteService';
import { ResourceItem as ResourceItemModel } from '../../models/ResourceModel';
import { ResourceCard } from '../../components/ResourceCard';
import { AuthApi, UserInfo } from '../../api/AuthApi';
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
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private resourceService: ResourceService = ResourceService.getInstance();

  // ── 响应式参数 ─────────────────────────────────────────
  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 640, lg: 780, xl: 920 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private headerHeight(): number {
    return new BpType<number>({ sm: 44, md: 48, lg: 52, xl: 56 }).getValue(this.currentBreakpoint) ?? 44;
  }

  private titleFontSize(): number {
    return new BpType<number>({ sm: 20, md: 22, lg: 26, xl: 30 }).getValue(this.currentBreakpoint) ?? 20;
  }

  private subtitleFontSize(): number {
    return new BpType<number>({ sm: 18, md: 20, lg: 24, xl: 28 }).getValue(this.currentBreakpoint) ?? 18;
  }

  private bodyFontSize(): number {
    return new BpType<number>({ sm: 14, md: 16, lg: 18, xl: 20 }).getValue(this.currentBreakpoint) ?? 14;
  }

  private captionFontSize(): number {
    return new BpType<number>({ sm: 12, md: 13, lg: 15, xl: 17 }).getValue(this.currentBreakpoint) ?? 12;
  }

  private smallFontSize(): number {
    return new BpType<number>({ sm: 11, md: 12, lg: 14, xl: 16 }).getValue(this.currentBreakpoint) ?? 11;
  }

  private emptyIconSize(): number {
    return new BpType<number>({ sm: 40, md: 52, lg: 64, xl: 76 }).getValue(this.currentBreakpoint) ?? 40;
  }

  private emptyTitleSize(): number {
    return new BpType<number>({ sm: 15, md: 18, lg: 22, xl: 26 }).getValue(this.currentBreakpoint) ?? 15;
  }
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private authStore: AuthStore = AuthStore.getInstance();
  private authApi: AuthApi = new AuthApi();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.favoriteService.init(context);
    await this.authStore.init(context);
    await this.loadUserInfo();
    await this.loadFavorites();
    await this.loadHistory();
    this.dataReady = true;
  }

  async onPageShow(): Promise<void> {
    await this.loadUserInfo();
    await this.loadFavorites();
    await this.loadHistory();
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
    const favResult = await this.favoriteService.getFavoriteResources(1, 100);
    this.favorites = favResult.items;
    if (this.favorites.length === 0 && favResult.total > 0) {
      const favIds = await this.favoriteService.getFavoriteIds();
      this.favorites = this.resourceService.getLocalResources().filter(r => favIds.has(r.id));
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

  build() {
    Column() {
      // Header
      Row() {
        Text('我的').fontSize(this.titleFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
      }
      .width('100%').height(this.headerHeight()).padding({ left: this.contentPadding(), right: this.contentPadding() })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          Column() {
          // Profile card — clickable to login/edit
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(64).height(64).borderRadius(32).backgroundColor(ColorTokens.BG_AVATAR)
              if (this.userAvatar) {
                Image(this.userAvatar).width(64).height(64).borderRadius(32).objectFit(ImageFit.Cover)
              } else {
                Text('👤').fontSize(this.subtitleFontSize() + 12)
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
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), radius: 12 })
                .onClick(() => { router.pushUrl({ url: 'pages/EditProfilePage' }); })
            }
          }
          .width('100%').padding(new BpType<number>({ sm: 18, md: 20, lg: 24, xl: 28 }).getValue(this.currentBreakpoint) ?? 18)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 14 })
          .onClick(() => {
            if (!this.isLoggedIn) { router.pushUrl({ url: 'pages/LoginPage' }); }
          })

          // Logout
          if (this.isLoggedIn) {
            Row() {
              Text('退出登录').fontSize(this.smallFontSize()).fontColor(ColorTokens.RED)
                .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                .border({ width: 1, color: ColorTokens.withAlpha(ColorTokens.RED, '25'), radius: 10 })
                .onClick(() => { this.doLogout(); })
              Blank()
            }
            .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() }).margin({ top: 8 })
          }

          // Stats row
          Row() {
            Column() {
              Text(this.favorites.length.toString())
                .fontSize(new BpType<number>({ sm: 26, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 26)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.primary(this.isDarkMode))
              Text('我的收藏').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
            .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text(this.historyResources.length.toString())
                .fontSize(new BpType<number>({ sm: 26, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 26)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
              Text('浏览历史').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14).margin({ left: 8 })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
            .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text('📄').fontSize(new BpType<number>({ sm: 22, md: 24, lg: 28, xl: 32 }).getValue(this.currentBreakpoint) ?? 22)
              Text('我的资源').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14).margin({ left: 8 })
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
            .onClick(() => { router.pushUrl({ url: 'pages/MyResourcesPage' }); })
          }
          .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 12 })

          // Stats entry
          Row() {
            Text('📊').fontSize(22)
            Column() {
              Text('数据统计').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('分类分布 · 来源排行 · 热度Top10').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.margin({ left: 10 })
            Blank()
            Text('查看 ›').fontSize(this.captionFontSize()).fontColor(ColorTokens.primary(this.isDarkMode))
          }
          .width('100%').padding(14)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
          .shadow({ radius: 4, color: ColorTokens.SHADOW_LIGHT, offsetX: 0, offsetY: 2 })
          .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 14 })
          .onClick(() => { router.pushUrl({ url: 'pages/StatsPage' }); })

          // 主题切换
          Row() {
            Text(this.isDarkMode ? '🌙' : '☀️').fontSize(22)
            Column() {
              Text('外观主题').fontSize(this.bodyFontSize()).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text(this.isDarkMode ? '深色模式' : '亮色模式').fontSize(this.smallFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.margin({ left: 10 })
            Blank()
            // 三档切换按钮
            Row() {
              Text('☀️').fontSize(14)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(8)
                .backgroundColor(!this.isDarkMode ? ColorTokens.primary(this.isDarkMode) : '#00000000')
                .fontColor(!this.isDarkMode ? '#FFFFFF' : ColorTokens.textHint(this.isDarkMode))
                .onClick(() => { AppTheme.getInstance().setThemeMode(ThemeMode.LIGHT); })
              Text('🌙').fontSize(14)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(8)
                .backgroundColor(this.isDarkMode ? ColorTokens.primary(this.isDarkMode) : '#00000000')
                .fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.textHint(this.isDarkMode))
                .onClick(() => { AppTheme.getInstance().setThemeMode(ThemeMode.DARK); })
            }
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(10)
          }
          .width('100%').padding(14)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(14)
          .margin({ left: this.contentPadding(), right: this.contentPadding(), top: 8 })
          .shadow({ radius: 4, color: ColorTokens.SHADOW_LIGHT, offsetX: 0, offsetY: 2 })
          .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 14 })

          // Tab pills
          Row() {
            Text('收藏')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 0 ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(18)
              .backgroundColor(this.activeTab === 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('浏览历史')
              .fontSize(this.captionFontSize()).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 1 ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textHint(this.isDarkMode))
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(18)
              .backgroundColor(this.activeTab === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Blank()
          }
          .width('100%').padding({ left: this.contentPadding() }).margin({ top: 14 })

          // Search + Sort (only when has content)
          if (this.getFilteredList().length > 0 || this.searchKeyword.trim()) {
            Row() {
              Text('🔍').fontSize(this.captionFontSize())
              TextInput({ text: this.searchKeyword, placeholder: '搜索...' })
                .fontSize(this.captionFontSize()).layoutWeight(1).height(34)
                .backgroundColor('#00000000').padding({ left: 8 })
                .onChange((value: string) => { this.searchKeyword = value; })
              if (this.searchKeyword) {
                Text('✕').fontSize(this.captionFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
                  .onClick(() => { this.searchKeyword = ''; })
              }
            }
            .width('100%').height(38).padding({ left: this.contentPadding(), right: this.contentPadding() })
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(18)
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
          if (this.activeTab === 0) {
            if (this.favorites.length === 0) {
              Column() {
                Text('☆').fontSize(this.emptyIconSize()).opacity(0.3).margin({ top: 50 })
                Text('还没有收藏').fontSize(this.emptyTitleSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 10 })
                Text('浏览资源时点击 ☆ 即可收藏').fontSize(this.captionFontSize()).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
              }.width('100%')
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              Column() {
                Text('🔍').fontSize(this.emptyIconSize()).opacity(0.3).margin({ top: 50 })
                Text('未找到「' + this.searchKeyword + '」').fontSize(this.emptyTitleSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 10 })
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
                .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() })
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
          } else {
            if (this.historyResources.length === 0) {
              Column() {
                Text('🕐').fontSize(this.emptyIconSize()).opacity(0.3).margin({ top: 50 })
                Text('还没有浏览记录').fontSize(this.emptyTitleSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 10 })
              }.width('100%')
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              Column() {
                Text('🔍').fontSize(this.emptyIconSize()).opacity(0.3).margin({ top: 50 })
                Text('未找到「' + this.searchKeyword + '」').fontSize(this.emptyTitleSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 10 })
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
                .width('100%').padding({ left: this.contentPadding(), right: this.contentPadding() })
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

          // Bottom spacer
          Column().height(60)
          }
          .constraintSize({ maxWidth: this.maxContentWidth() })
          .width('100%')
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
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
      .fontSize(new BpType<number>({ sm: 11, md: 12, lg: 13, xl: 14 }).getValue(this.currentBreakpoint) ?? 11)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textHint(this.isDarkMode))
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.active ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
      .borderRadius(14)
      .margin({ right: 6 })
      .onClick(() => { this.onSort(); })
  }
}
