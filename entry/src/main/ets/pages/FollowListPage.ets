import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, PageData, ApiResponse } from '@neushare/common';
import { FollowApi, FollowUser } from '../api/FollowApi';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct FollowListPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @State activeTab: number = 0; // 0=followers, 1=following
  @State users: FollowUser[] = [];
  @State loading: boolean = true;
  @State pageNum: number = 1;
  @State hasMore: boolean = true;
  @State breathScale: number = 1;
  private followApi: FollowApi = new FollowApi();
  private breathInterval: number = -1;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.activeTab = (params['tab'] as number) || 0;
    }
    // 呼吸动画
    this.breathInterval = setInterval(() => {
      animateTo({ duration: 1500, curve: Curve.EaseInOut }, () => {
        this.breathScale = this.breathScale === 1 ? 1.1 : 1;
      });
    }, 1600);
    await this.loadUsers();
  }

  aboutToDisappear(): void {
    if (this.breathInterval >= 0) {
      clearInterval(this.breathInterval);
      this.breathInterval = -1;
    }
  }

  async loadUsers(): Promise<void> {
    this.loading = true;
    try {
      let resp: ApiResponse<PageData<FollowUser>>;
      if (this.activeTab === 0) {
        resp = await this.followApi.getFollowers(this.pageNum);
      } else {
        resp = await this.followApi.getFollowing(this.pageNum);
      }
      if (resp && resp.code === 200 && resp.data) {
        const records: FollowUser[] = resp.data.records || [];
        if (this.pageNum === 1) {
          this.users = records;
        } else {
          const merged: FollowUser[] = [];
          for (let i = 0; i < this.users.length; i++) {
            merged.push(this.users[i]);
          }
          for (let i = 0; i < records.length; i++) {
            merged.push(records[i]);
          }
          this.users = merged;
        }
        this.hasMore = records.length >= 10;
      }
    } catch (e) {
      console.error('loadUsers failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '加载失败，请检查网络', duration: 2000 });
    }
    this.loading = false;
  }

  async switchTab(tab: number): Promise<void> {
    if (this.activeTab === tab) return;
    this.activeTab = tab;
    this.pageNum = 1;
    this.users = [];
    await this.loadUsers();
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore || this.loading) return;
    this.pageNum++;
    await this.loadUsers();
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('关注与粉丝').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
      }
      .width('100%').height(52).padding({ left: 16 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      // Tab switch
      Row() {
        Text('粉丝')
          .fontSize(15).fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.activeTab === 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
          .padding({ bottom: 8 })
          .border({ width: { bottom: this.activeTab === 0 ? 2 : 0 }, color: ColorTokens.primary(this.isDarkMode) })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.switchTab(0); })

        Text('关注')
          .fontSize(15).fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.activeTab === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
          .padding({ bottom: 8 })
          .border({ width: { bottom: this.activeTab === 1 ? 2 : 0 }, color: ColorTokens.primary(this.isDarkMode) })
          .layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => { this.switchTab(1); })
      }
      .width('100%').padding({ left: 24, right: 24, top: 12 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      // User list
      if (this.users.length === 0 && !this.loading) {
        Column() {
          Text(this.activeTab === 0 ? '👤' : '👥').fontSize(48)
            .scale({ x: this.breathScale, y: this.breathScale })
            .animation({ duration: 1500, curve: Curve.EaseInOut, iterations: -1 })
          Text(this.activeTab === 0 ? '暂无粉丝' : '暂未关注任何人')
            .fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.users, (user: FollowUser) => {
            ListItem() {
              Row() {
                Stack({ alignContent: Alignment.Center }) {
                  Column().width(44).height(44).borderRadius(22).backgroundColor(ColorTokens.resolve(ColorTokens.BG_AVATAR, ColorTokens.BG_AVATAR_DARK, this.isDarkMode))
                  if (user.avatarUrl) {
                    Image(user.avatarUrl).width(44).height(44).borderRadius(22).objectFit(ImageFit.Cover)
                  } else {
                    Text('👤').fontSize(22)
                  }
                }
                Column() {
                  Text(user.nickname || user.username).fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                  if (user.college) {
                    Text(user.college).fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
                  }
                }.margin({ left: 12 }).layoutWeight(1)
              }
              .width('100%').padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/UserProfilePage', params: {
                  userId: user.id, username: user.username, nickname: user.nickname, avatarUrl: user.avatarUrl, college: user.college
                }});
              })
            }
          }, (user: FollowUser) => user.id.toString())

          // Load more trigger
          if (this.hasMore && !this.loading) {
            ListItem() {
              Row() {
                Text('加载更多...').fontSize(14).fontColor(ColorTokens.primary(this.isDarkMode))
              }
              .width('100%').height(44).justifyContent(FlexAlign.Center)
              .onClick(() => { this.loadMore(); })
            }
          }
          if (this.loading && this.users.length > 0) {
            ListItem() {
              Row() {
                LoadingProgress().width(20).height(20).color(ColorTokens.primary(this.isDarkMode))
              }
              .width('100%').height(44).justifyContent(FlexAlign.Center)
            }
          }
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0 })
        .onReachEnd(() => { this.loadMore(); })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right).opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left).opacity(0.9)
  }
}
