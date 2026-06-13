import router from '@ohos.router';
import { AuthStore } from '@neushare/common';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct SplashPage {
  @State logoScale: number = 0;
  @State logoOpacity: number = 0;
  @State titleOpacity: number = 0;
  @State titleY: number = 30;
  @State subOpacity: number = 0;
  @State subY: number = 16;
  @State tagOpacity: number = 0;
  @State pageOpacity: number = 1;
  @State isCheckingAuth: boolean = true;
  private jumped: boolean = false;
  private authStore: AuthStore = AuthStore.getInstance();

  aboutToAppear(): void {
    // 立即检查登录状态（不等待动画）
    this.tryAutoLogin();
  }

  /**
   * 自动登录：如果本地有有效 token，秒进主页；否则播动画 → 跳登录
   */
  async tryAutoLogin(): Promise<void> {
    if (this.jumped) return;
    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.authStore.init(context);
      const loggedIn = await this.authStore.isLoggedIn();
      if (loggedIn) {
        const valid = await this.authStore.validateToken();
        if (valid) {
          this.jumped = true;
          this.isCheckingAuth = false;
          router.replaceUrl({ url: 'pages/Index' });
          return;
        }
      }
    } catch (e) {
      // 验证失败，走正常登录流程
    }
    // 未登录或 token 失效 → 播动画后跳登录
    this.isCheckingAuth = false;
    this.playAnimation();
  }

  playAnimation(): void {
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 500, curve: Curve.FastOutSlowIn }, () => {
        this.logoScale = 1; this.logoOpacity = 1;
      });
    }, 300);

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
        this.titleOpacity = 1; this.titleY = 0;
      });
    }, 700);

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseOut }, () => {
        this.subOpacity = 1; this.subY = 0;
      });
    }, 950);

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseOut }, () => {
        this.tagOpacity = 1;
      });
    }, 1150);

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseIn }, () => {
        this.pageOpacity = 0;
      });
    }, 2200);

    setTimeout(() => {
      if (!this.jumped) {
        this.jumped = true;
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    }, 2600);
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#FFFFFF')

      if (this.isCheckingAuth) {
        // 正在验证 token（通常 <1秒），显示极简 loading
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Column().width(60).height(60).borderRadius(30)
              .backgroundColor('#FF5A5F')
            Text('N').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          }
          Text('加载中...')
            .fontSize(13).fontColor('#AAAAAA').margin({ top: 16 })
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        // 未登录 → 播完整动画
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Column().width(80).height(80).borderRadius(40)
              .backgroundColor('#FF5A5F')
            Text('N').fontSize(40).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          }
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)

          Text('NEU Share')
            .fontSize(34).fontWeight(FontWeight.Bolder)
            .fontColor('#000000').letterSpacing(4)
            .opacity(this.titleOpacity).translate({ y: this.titleY })
            .margin({ top: 28 })

          Text('东北大学 · 软件学院')
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor('#FF5A5F').letterSpacing(8)
            .opacity(this.subOpacity).translate({ y: this.subY })
            .margin({ top: 14 })

          Text('学习资源 · 课程推荐 · 考研指南')
            .fontSize(13).fontWeight(FontWeight.Medium)
            .fontColor('#444444').letterSpacing(2)
            .opacity(this.tagOpacity)
            .margin({ top: 36 })
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .opacity(this.pageOpacity)

        Text('NEU · Software College')
          .fontSize(10).fontColor('#999999').letterSpacing(3)
          .position({ x: '50%', y: '93%' }).translate({ x: '-50%', y: 0 })
          .opacity(this.subOpacity)
      }
    }
    .width('100%').height('100%')
  }
}
