import router from '@ohos.router';
import { ColorTokens, AuthStore } from '@neushare/common';
import { FollowApi, FollowUser } from '../api/FollowApi';
import { Context } from '@ohos.abilityAccessCtrl';

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
  private followApi: FollowApi = new FollowApi();
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
    if (await this.authStore.isLoggedIn()) {
      try {
        const resp = await this.followApi.check(this.userId);
        if (resp.code === 200) {
          this.isFollowing = resp.data as boolean;
        }
      } catch (e) {
        // ignore
      }
    }
  }

  async toggleFollow(): Promise<void> {
    this.isLoading = true;
    try {
      if (this.isFollowing) {
        await this.followApi.unfollow(this.userId);
        this.isFollowing = false;
      } else {
        await this.followApi.follow(this.userId);
        this.isFollowing = true;
      }
    } catch (e) {
      // ignore
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

      Column() {
        // Avatar + name
        Stack({ alignContent: Alignment.Center }) {
          Column().width(88).height(88).borderRadius(44).backgroundColor(ColorTokens.BG_AVATAR)
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
      }
      .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
