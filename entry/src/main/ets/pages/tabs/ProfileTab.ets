import router from '@ohos.router';
import { ColorTokens, AuthStore, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
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
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  private resourceService: ResourceService = ResourceService.getInstance();
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
        Text('我的').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
      }
      .width('100%').height(44).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Profile card — clickable to login/edit
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(64).height(64).borderRadius(32).backgroundColor(ColorTokens.BG_AVATAR)
              if (this.userAvatar) {
                Image(this.userAvatar).width(64).height(64).borderRadius(32).objectFit(ImageFit.Cover)
              } else {
                Text('👤').fontSize(30)
              }
            }
            Column() {
              Text(this.isLoggedIn ? this.userNickname : '点击登录')
                .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text(this.isLoggedIn && this.userCollege ?
                this.userCollege + ' · ' + this.getGradeLabel() : '东北大学')
                .fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.margin({ left: 12 })
            Blank()
            if (this.isLoggedIn) {
              Text('编辑资料').fontSize(12).fontColor(ColorTokens.ACCENT)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .border({ width: 1, color: ColorTokens.ACCENT + '40', radius: 12 })
                .onClick(() => { router.pushUrl({ url: 'pages/EditProfilePage' }); })
            }
          }
          .width('100%').padding(18)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
          .margin({ left: 16, right: 16, top: 14 })
          .onClick(() => {
            if (!this.isLoggedIn) { router.pushUrl({ url: 'pages/LoginPage' }); }
          })

          // Logout
          if (this.isLoggedIn) {
            Row() {
              Text('退出登录').fontSize(11).fontColor(ColorTokens.RED)
                .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                .border({ width: 1, color: ColorTokens.RED + '25', radius: 10 })
                .onClick(() => { this.doLogout(); })
              Blank()
            }
            .width('100%').padding({ left: 16, right: 16 }).margin({ top: 8 })
          }

          // Stats row
          Row() {
            Column() {
              Text(this.favorites.length.toString())
                .fontSize(new BpType<number>({ sm: 26, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 26)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.ACCENT)
              Text('我的收藏').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14)
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
            .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text(this.historyResources.length.toString())
                .fontSize(new BpType<number>({ sm: 26, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 26)
                .fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
              Text('浏览历史').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14).margin({ left: 8 })
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
            .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Column() {
              Text('📄').fontSize(new BpType<number>({ sm: 22, md: 24, lg: 28, xl: 32 }).getValue(this.currentBreakpoint) ?? 22)
              Text('我的资源').fontSize(11).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }
            .layoutWeight(1).padding(14).margin({ left: 8 })
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
            .onClick(() => { router.pushUrl({ url: 'pages/MyResourcesPage' }); })
          }
          .width('100%').padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 12 })

          // Tab pills
          Row() {
            Text('收藏')
              .fontSize(13).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 0 ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(18)
              .backgroundColor(this.activeTab === 0 ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
              .onClick(() => { this.activeTab = 0; this.searchKeyword = ''; this.sortMode = 'default'; })

            Text('浏览历史')
              .fontSize(13).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.activeTab === 1 ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
              .padding({ left: 18, right: 18, top: 7, bottom: 7 })
              .borderRadius(18)
              .backgroundColor(this.activeTab === 1 ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
              .margin({ left: 8 })
              .onClick(() => { this.activeTab = 1; this.searchKeyword = ''; this.sortMode = 'default'; })

            Blank()
          }
          .width('100%').padding({ left: 16 }).margin({ top: 14 })

          // Search + Sort (only when has content)
          if (this.getFilteredList().length > 0 || this.searchKeyword.trim()) {
            Row() {
              Text('🔍').fontSize(13)
              TextInput({ text: this.searchKeyword, placeholder: '搜索...' })
                .fontSize(12).layoutWeight(1).height(34)
                .backgroundColor('#00000000').padding({ left: 8 })
                .onChange((value: string) => { this.searchKeyword = value; })
              if (this.searchKeyword) {
                Text('✕').fontSize(13).fontColor(ColorTokens.TEXT_HINT)
                  .onClick(() => { this.searchKeyword = ''; })
              }
            }
            .width('100%').height(38).padding({ left: 16, right: 16 })
            .backgroundColor(ColorTokens.BG_INPUT).borderRadius(18)
            .margin({ left: 16, right: 16, top: 10 })

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
            .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 2 })
          }

          // Content
          if (this.activeTab === 0) {
            if (this.favorites.length === 0) {
              Column() {
                Text('☆').fontSize(40).opacity(0.3).margin({ top: 50 })
                Text('还没有收藏').fontSize(15).fontColor(ColorTokens.TEXT_HINT).margin({ top: 10 })
                Text('浏览资源时点击 ☆ 即可收藏').fontSize(12).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
              }.width('100%')
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              Column() {
                Text('🔍').fontSize(40).opacity(0.3).margin({ top: 50 })
                Text('未找到「' + this.searchKeyword + '」').fontSize(15).fontColor(ColorTokens.TEXT_HINT).margin({ top: 10 })
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
                .width('100%').padding({ left: 16, right: 16 })
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
                Text('🕐').fontSize(40).opacity(0.3).margin({ top: 50 })
                Text('还没有浏览记录').fontSize(15).fontColor(ColorTokens.TEXT_HINT).margin({ top: 10 })
              }.width('100%')
            } else if (this.searchKeyword.trim() && this.getFilteredList().length === 0) {
              Column() {
                Text('🔍').fontSize(40).opacity(0.3).margin({ top: 50 })
                Text('未找到「' + this.searchKeyword + '」').fontSize(15).fontColor(ColorTokens.TEXT_HINT).margin({ top: 10 })
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
                .width('100%').padding({ left: 16, right: 16 })
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
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}

@Component
struct SortChip {
  @Prop label: string = '';
  @Prop active: boolean = false;
  onSort: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(11)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.active ? ColorTokens.TEXT_WHITE : ColorTokens.TEXT_HINT)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.active ? ColorTokens.PRIMARY : ColorTokens.BG_INPUT)
      .borderRadius(14)
      .margin({ right: 6 })
      .onClick(() => { this.onSort(); })
  }
}
