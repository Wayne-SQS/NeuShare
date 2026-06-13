import router from '@ohos.router';
import { AuthStore } from '@neushare/common';
import { AuthApi } from '../api/AuthApi';
import { FavoriteService } from '../services/FavoriteService';
import { PreferencesStore } from '@neushare/common';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State cardOpacity: number = 0;
  @State cardY: number = 30;
  @State rememberPwd: boolean = true;
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
            Column().width(72).height(72).borderRadius(36).backgroundColor('#FF5A5F')
            Text('N').fontSize(36).fontWeight(FontWeight.Bolder).fontColor('#FFFFFF')
          }
          .margin({ top: 80 })

          Text('NEU Share')
            .fontSize(30).fontWeight(FontWeight.Bolder).fontColor('#000000').letterSpacing(4)
            .margin({ top: 24 })

          Text('东北大学软件学院')
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FF5A5F').letterSpacing(6)
            .margin({ top: 10 })

          // Form
          Column() {
            TextInput({ text: this.username, placeholder: '用户名 / 学号' })
              .fontSize(16).width('100%').height(52)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.username = value; })

            TextInput({ text: this.password, placeholder: '密码' })
              .fontSize(16).width('100%').height(52)
              .type(InputType.Password)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 }).margin({ top: 12 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.password = value; })

            // 记住密码
            Row() {
              Text(this.rememberPwd ? '☑' : '☐')
                .fontSize(16).fontColor(this.rememberPwd ? '#FF5A5F' : '#CCCCCC')
                .onClick(() => { this.rememberPwd = !this.rememberPwd; })
              Text(' 记住密码')
                .fontSize(13).fontColor('#999999')
                .onClick(() => { this.rememberPwd = !this.rememberPwd; })
              Blank()
            }
            .width('100%').margin({ top: 10 })

            if (this.errorMsg) {
              Text(this.errorMsg).fontSize(13).fontColor('#FF5A5F').margin({ top: 10 })
            }

            Button(this.isLoading ? '登录中...' : '登 录')
              .width('100%').height(52)
              .fontSize(16).fontWeight(FontWeight.Bolder).fontColor('#FFFFFF')
              .backgroundColor('#FF5A5F').borderRadius(14)
              .margin({ top: 24 })
              .enabled(!this.isLoading)
              .onClick(() => { this.doLogin(); })

            Text('还没有账号？立即注册 →')
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#FF5A5F')
              .margin({ top: 22 })
              .onClick(() => { router.pushUrl({ url: 'pages/RegisterPage' }); })

            Text('跳过登录，离线使用')
              .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#AAAAAA')
              .margin({ top: 16 })
              .onClick(() => { router.replaceUrl({ url: 'pages/Index' }); })
          }
          .width('100%').padding(24)
          .margin({ top: 32, left: 16, right: 16 })

          Column().height(60)
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
    .opacity(this.cardOpacity).translate({ y: this.cardY })
  }
}
