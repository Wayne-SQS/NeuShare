import router from '@ohos.router';
import { webview } from '@kit.ArkWeb';
import { ColorTokens } from '@neushare/common';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
struct WebViewPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State pageTitle: string = '加载中...';
  @State loadProgress: number = 0;
  private url: string = '';
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.url = (params['url'] as string) || '';
      this.pageTitle = (params['title'] as string) || '加载中...';
    }
  }

  openInBrowser(url: string): void {
    if (!url) return;
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browser'],
      uri: url
    };
    try { ctx.startAbility(want); } catch (e) {
      console.error('openInBrowser failed: ' + JSON.stringify(e));
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })

        Column() {
          Text(this.pageTitle)
            .fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }.layoutWeight(1).margin({ left: 12, right: 12 })

        Text('⋮').fontSize(22).fontColor(ColorTokens.textSecondary(this.isDarkMode))
          .onClick(() => { this.openInBrowser(this.url); })
      }
      .width('100%').height(48).padding({ left: 24, right: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
      .alignItems(VerticalAlign.Center)

      // 加载进度条
      if (this.loadProgress > 0 && this.loadProgress < 100) {
        Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
          .width('100%').color(ColorTokens.primary(this.isDarkMode)).height(2)
      }

      // WebView — 对齐 QuickStart: 极简配置
      Web({ src: this.url, controller: this.webController })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .mixedMode(MixedMode.All)
        .darkMode(WebDarkMode.Auto)
        .width('100%')
        .layoutWeight(1)
        .onPageBegin(() => { this.loadProgress = 10; })
        .onPageEnd(() => {
          this.loadProgress = 100;
          try {
            const title = this.webController.getTitle();
            if (title && title.length > 0) { this.pageTitle = title; }
          } catch (e) {}
        })
        .onProgressChange((event) => {
          if (event) { this.loadProgress = event.newProgress; }
        })
        .onErrorReceive((event) => {
          if (event) {
            console.error('WebView error: ' + JSON.stringify(event));
          }
        })
    }
    .width('100%').height('100%')
    .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
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
