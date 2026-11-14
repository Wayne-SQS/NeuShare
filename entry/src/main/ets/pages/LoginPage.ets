import router from '@ohos.router';
import { AuthStore, ColorTokens, FontScale, Radii, Spacing, ControlSize } from '@neushare/common';
import { AuthApi } from '../api/AuthApi';
import { FavoriteService } from '../services/FavoriteService';
import { PreferencesStore } from '@neushare/common';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct LoginPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State cardOpacity: number = 0;
  @State cardY: number = 30;
  @State rememberPwd: boolean = true;
  @State btnPressed: boolean = false; // 按钮按压状态（教程 §16.3 生命力原则）
  private authApi: AuthApi = new AuthApi();
  private authStore: AuthStore = AuthStore.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private credentialStore: PreferencesStore = new PreferencesStore('neushare_cred');

  aboutToAppear(): void {
    // 加载记住的账号密码
    this.loadSavedCredentials();
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.cardOpacity = 1; this.cardY = 0;
      });
    }, 200);
  }

  async loadSavedCredentials(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.credentialStore.init(context);
      const savedUser = await this.credentialStore.get('saved_username', '') as string;
      const savedPwd = await this.credentialStore.get('saved_password', '') as string;
      if (savedUser) {
        this.username = savedUser;
        this.password = savedPwd;
        this.rememberPwd = true;
      }
    } catch (e) {
      // 忽略加载错误
    }
  }

  async saveCredentials(): Promise<void> {
    try {
      if (this.rememberPwd && this.username.trim()) {
        await this.credentialStore.set('saved_username', this.username.trim());
        await this.credentialStore.set('saved_password', this.password);
      } else {
        await this.credentialStore.set('saved_username', '');
        await this.credentialStore.set('saved_password', '');
      }
    } catch (e) {
      // 忽略保存错误
    }
  }

  async doLogin(): Promise<void> {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMsg = '请输入用户名和密码';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.authStore.init(context);
      const resp = await this.authApi.login(this.username.trim(), this.password);
      if (resp.code === 200 && resp.data) {
        await this.authStore.setToken(resp.data.token);
        await this.authStore.saveLogin(resp.data.token, resp.data.user);
        // 记住密码
        await this.saveCredentials();
        // 合并本地离线收藏到云端
        await this.favoriteService.init(context);
        this.favoriteService.mergeLocalFavoritesToCloud();
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        this.errorMsg = resp.message || '登录失败';
      }
    } catch (e) {
      this.errorMsg = '无法连接服务器 (10.0.2.2:8080)，确认后端和MySQL都在运行';
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // Logo
          Stack({ alignContent: Alignment.Center }) {
            Column().width(72).height(72).borderRadius(Radii.PILL).backgroundColor(ColorTokens.primary(this.isDarkMode))
            Text('N').fontSize(FontScale.BRAND).fontWeight(FontWeight.Bolder).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
          }
          .margin({ top: 80 })

          Text('NEU Share')
            .fontSize(FontScale.DISPLAY).fontWeight(FontWeight.Bolder).fontColor(ColorTokens.textPrimary(this.isDarkMode)).letterSpacing(4)
            .margin({ top: 24 })

          Text('东北大学软件学院')
            .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold).fontColor(ColorTokens.primary(this.isDarkMode)).letterSpacing(6)
            .margin({ top: 10 })

          // Form
          Column() {
            TextInput({ text: this.username, placeholder: '用户名 / 学号' })
              .fontSize(FontScale.SUBTITLE).width('100%').height(ControlSize.INPUT)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding({ left: Spacing.LG })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.username = value; })

            TextInput({ text: this.password, placeholder: '密码' })
              .fontSize(FontScale.SUBTITLE).width('100%').height(ControlSize.INPUT)
              .type(InputType.Password)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding({ left: Spacing.LG }).margin({ top: Spacing.MD })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.password = value; })

            // 记住密码
            Row() {
              Text(this.rememberPwd ? '已记住' : '记住密码')
                .fontSize(FontScale.CAPTION)
                .fontColor(this.rememberPwd ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
                .borderRadius(Radii.SM)
                .backgroundColor(this.rememberPwd ? ColorTokens.bgInput(this.isDarkMode) : ColorTokens.TRANSPARENT)
                .onClick(() => { this.rememberPwd = !this.rememberPwd; })
              Blank()
            }
            .width('100%').margin({ top: Spacing.SM })

            if (this.errorMsg) {
              Text(this.errorMsg).fontSize(FontScale.CAPTION).fontColor(ColorTokens.error(this.isDarkMode)).margin({ top: Spacing.SM })
            }

            Button(this.isLoading ? '登录中...' : '登 录')
              .width('100%').height(ControlSize.BUTTON)
              .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.BUTTON)
              .margin({ top: Spacing.XL })
              .enabled(!this.isLoading)
              .scale({ x: this.btnPressed ? 0.96 : 1, y: this.btnPressed ? 0.96 : 1 })
              .animation({ curve: Curve.EaseOut, duration: 200 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.btnPressed = true; }
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.btnPressed = false; }
              })
              .onClick(() => { this.doLogin(); })

            Text('还没有账号？立即注册')
              .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Medium).fontColor(ColorTokens.primary(this.isDarkMode))
              .height(ControlSize.BUTTON)
              .margin({ top: Spacing.MD })
              .onClick(() => { router.pushUrl({ url: 'pages/RegisterPage' }); })

            Text('跳过登录，离线使用')
              .fontSize(FontScale.CAPTION).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textDisabled(this.isDarkMode))
              .height(ControlSize.BUTTON)
              .onClick(() => { router.replaceUrl({ url: 'pages/Index' }); })
          }
          .width('100%').padding(24)
          .margin({ top: 32, left: 24, right: 24 })

          Column().height(60)
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .opacity(this.cardOpacity).translate({ y: this.cardY })
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
