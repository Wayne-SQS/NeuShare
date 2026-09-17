import router from '@ohos.router';
import { ColorTokens, AuthStore, PageData, ApiResponse } from '@neushare/common';
import { FollowApi } from '../api/FollowApi';
import { UserApi, UserProfile } from '../api/UserApi';
import { ResourceVO } from '../models/ResourceModel';
import { Context } from '@ohos.abilityAccessCtrl';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct UserProfilePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State userId: number = 0;
  @State username: string = '';
  @State nickname: string = '';
  @State avatarUrl: string = '';
  @State college: string = '';
  @State isFollowing: boolean = false;
  @State isLoading: boolean = false;
  @State resourceCount: number = 0;
  @State followerCount: number = 0;
  @State followingCount: number = 0;
  @State totalLikesReceived: number = 0;
  @State userResources: ResourceVO[] = [];
  @State resourcesLoading: boolean = false;
  @State appearOpacity: number = 0;
  private followApi: FollowApi = new FollowApi();
  private userApi: UserApi = new UserApi();
  private authStore: AuthStore = AuthStore.getInstance();

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.userId = params['userId'] as number;
      this.username = (params['username'] || '') as string;
      this.nickname = (params['nickname'] || params['username'] || '') as string;
      this.avatarUrl = (params['avatarUrl'] || '') as string;
      this.college = (params['college'] || '') as string;
    }

    const context = this.getUIContext().getHostContext() as Context;
    await this.authStore.init(context);
    const isLoggedIn = await this.authStore.isLoggedIn();

    const results = await Promise.all([
      this.userApi.getProfile(this.userId),
      isLoggedIn ? this.followApi.check(this.userId) : Promise.resolve(null)
    ]);
    const profileResp = results[0];
    const followResp = results[1];

    if (profileResp && profileResp.code === 200 && profileResp.data) {
      this.username = profileResp.data.username || this.username;
      this.nickname = profileResp.data.nickname || this.nickname;
      this.avatarUrl = profileResp.data.avatarUrl || this.avatarUrl;
      this.college = profileResp.data.college || this.college;
      this.resourceCount = profileResp.data.resourceCount || 0;
      this.followerCount = profileResp.data.followerCount || 0;
      this.followingCount = profileResp.data.followingCount || 0;
      this.totalLikesReceived = profileResp.data.totalLikesReceived || 0;
    }

    if (followResp && followResp.code === 200 && followResp.data) {
      this.isFollowing = followResp.data.isFollowing;
    }

    this.loadUserResources();
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  async loadUserResources(): Promise<void> {
    this.resourcesLoading = true;
    try {
      const resp = await this.userApi.getUserResources(this.userId, 1, 20);
      if (resp.code === 200 && resp.data) {
        this.userResources = resp.data.records || [];
      }
    } catch (e) {
      console.error('loadUserResources failed: ' + JSON.stringify(e));
    }
    this.resourcesLoading = false;
  }

  async toggleFollow(): Promise<void> {
    this.isLoading = true;
    try {
      if (this.isFollowing) {
        const res = await this.followApi.unfollow(this.userId);
        if (res.code === 200) {
          this.isFollowing = false;
        } else {
          promptAction.showToast({ message: '取消关注失败，请重试' });
        }
      } else {
        const res = await this.followApi.follow(this.userId);
        if (res.code === 200) {
          this.isFollowing = true;
        } else {
          promptAction.showToast({ message: '关注失败，请重试' });
        }
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请检查网络' });
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('用户主页').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
      }
      .width('100%').height(52).padding({ left: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          // Avatar + name
          Stack({ alignContent: Alignment.Center }) {
            Column().width(88).height(88).borderRadius(44).backgroundColor(ColorTokens.resolve(ColorTokens.BG_AVATAR, ColorTokens.BG_AVATAR_DARK, this.isDarkMode))
            if (this.avatarUrl) {
              Image(this.avatarUrl).width(88).height(88).borderRadius(44).objectFit(ImageFit.Cover)
            } else {
              Text('👤').fontSize(44)
            }
          }.margin({ top: 30 })

          Text(this.nickname)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .margin({ top: 16 })
          Text('@' + this.username)
            .fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 4 })
          if (this.college) {
            Text(this.college).fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
          }

          Button(this.isFollowing ? '已关注' : '+ 关注')
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor(this.isFollowing ? ColorTokens.textPrimary(this.isDarkMode) : ColorTokens.TEXT_WHITE)
            .backgroundColor(this.isFollowing ? ColorTokens.bgInput(this.isDarkMode) : ColorTokens.primary(this.isDarkMode))
            .borderRadius(20).height(40).padding({ left: 28, right: 28 })
            .margin({ top: 20 })
            .enabled(!this.isLoading)
            .onClick(() => { this.toggleFollow(); })

          // 统计信息
          Row() {
            Column() {
              Text(this.resourceCount.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('资源').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.layoutWeight(1)

            Column() {
              Text(this.followerCount.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('粉丝').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.layoutWeight(1)
            .onClick(() => {
              router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 0 } });
            })

            Column() {
              Text(this.followingCount.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('关注').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.layoutWeight(1)
            .onClick(() => {
              router.pushUrl({ url: 'pages/FollowListPage', params: { tab: 1 } });
            })

            Column() {
              Text(this.totalLikesReceived.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Text('获赞').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
            }.layoutWeight(1)
          }
          .width('80%').margin({ top: 24 })

          // 用户的资源列表
          if (this.userResources.length > 0) {
            Column() {
              Text('📄 发布的资源')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .width('100%').padding({ left: 24, right: 24, top: 24 })

              ForEach(this.userResources, (item: ResourceVO) => {
                Row() {
                  Text(item.type === 'book' ? '📖' : item.type === 'video' ? '🎬' : item.type === 'software' ? '💻' : '📝')
                    .fontSize(20)
                  Column() {
                    Text(item.title)
                      .fontSize(15).fontWeight(FontWeight.Medium)
                      .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row() {
                      Text('❤ ' + item.likeCount).fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
                      Text('👁 ' + item.viewCount).fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 10 })
                    }.margin({ top: 4 })
                  }.layoutWeight(1).margin({ left: 10 })
                  Text('›').fontSize(20).fontColor(ColorTokens.textHint(this.isDarkMode))
                }
                .width('100%').padding(12)
                .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
                .margin({ left: 24, right: 24, top: 8 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                })
              }, (item: ResourceVO) => item.id.toString())
            }
            .width('100%').margin({ top: 8 })
          } else if (this.resourcesLoading) {
            Column() {
              LoadingProgress().width(24).height(24).color(ColorTokens.primary(this.isDarkMode))
              Text('加载中...').fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 8 })
            }.width('100%').margin({ top: 40 }).justifyContent(FlexAlign.Center)
          }

          Column().height(40)
        }
        .width('100%').alignItems(HorizontalAlign.Center)
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
