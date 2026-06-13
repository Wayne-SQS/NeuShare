import router from '@ohos.router';
import { ColorTokens, AuthStore } from '@neushare/common';
import { AuthApi, UserInfo } from '../api/AuthApi';
import { GradePill } from '../components/GradePill';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct EditProfilePage {
  @State nickname: string = '';
  @State avatarUrl: string = '';
  @State college: string = '软件学院';
  @State grade: number = 1;
  @State isLoading: boolean = false;
  @State message: string = '';
  private authApi: AuthApi = new AuthApi();
  private authStore: AuthStore = AuthStore.getInstance();
  private grades: string[] = ['大一', '大二', '大三', '大四'];

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.authStore.init(context);
    try {
      const resp = await this.authApi.getInfo();
      if (resp.code === 200 && resp.data) {
        const u: UserInfo = resp.data;
        this.nickname = u.nickname || '';
        this.avatarUrl = u.avatarUrl || '';
        this.college = u.college || '软件学院';
        this.grade = u.grade || 1;
      }
    } catch (e) {
      this.message = '加载用户信息失败';
    }
  }

  async saveProfile(): Promise<void> {
    this.isLoading = true;
    this.message = '';
    try {
      const resp = await this.authApi.updateInfo(this.nickname.trim(), this.avatarUrl.trim(), this.college, this.grade);
      if (resp.code === 200) {
        this.message = '保存成功';
        setTimeout((): void => { router.back(); }, 500);
      } else {
        this.message = resp.message || '保存失败';
      }
    } catch (e) {
      this.message = '网络错误';
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('编辑资料').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.TEXT_PRIMARY).margin({ left: 12 })
        Blank()
        Text('保存').fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.PRIMARY)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(16)
          .onClick(() => { this.saveProfile(); })
      }
      .width('100%').height(52).padding({ left: 12, right: 12 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Avatar preview
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              Column().width(80).height(80).borderRadius(40).backgroundColor(ColorTokens.BG_AVATAR)
              if (this.avatarUrl) {
                Image(this.avatarUrl).width(80).height(80).borderRadius(40).objectFit(ImageFit.Cover)
              } else {
                Text('👤').fontSize(40)
              }
            }
            Column() {
              Text('头像').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
              Text('输入图片URL地址').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 4 })
            }.margin({ left: 16 })
          }
          .width('100%').padding(20)
          .backgroundColor(ColorTokens.BG_CARD)
          .margin({ left: 16, right: 16, top: 12 })
          .borderRadius(14)

          // Form
          Column() {
            Text('头像URL').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ bottom: 6 })
            TextInput({ text: this.avatarUrl, placeholder: 'https://...' })
              .fontSize(14).width('100%').height(44)
              .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
              .padding({ left: 12 })
              .onChange((value: string) => { this.avatarUrl = value; })

            Text('昵称').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 16, bottom: 6 })
            TextInput({ text: this.nickname, placeholder: '你的昵称' })
              .fontSize(14).width('100%').height(44)
              .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
              .padding({ left: 12 })
              .onChange((value: string) => { this.nickname = value; })

            Text('学院').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 16, bottom: 6 })
            TextInput({ text: this.college, placeholder: '软件学院' })
              .fontSize(14).width('100%').height(44)
              .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
              .padding({ left: 12 })
              .onChange((value: string) => { this.college = value; })

            Text('年级').fontSize(12).fontColor(ColorTokens.TEXT_HINT).margin({ top: 16, bottom: 8 })
            Row() {
              ForEach(this.grades, (label: string, idx: number) => {
                GradePill({
                  label: label,
                  isSelected: this.grade === (idx + 1),
                  onTap: () => { this.grade = idx + 1; }
                }).margin({ right: 8 })
              })
            }.width('100%')
          }
          .width('100%').padding(20)
          .backgroundColor(ColorTokens.BG_CARD)
          .margin({ left: 16, right: 16, top: 12 })
          .borderRadius(14)

          if (this.message) {
            Text(this.message)
              .fontSize(13)
              .fontColor(this.message.includes('成功') ? ColorTokens.GREEN : ColorTokens.RED)
              .margin({ top: 12 })
          }

          Column().height(60)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
