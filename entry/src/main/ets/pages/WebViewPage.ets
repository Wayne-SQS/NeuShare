import router from '@ohos.router';
import webview from '@ohos.web.webview';
import { ColorTokens } from '@neushare/common';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

interface PageEvent { url: string; }
interface ProgressEvent { newProgress: number; }
interface ErrorInfo { getErrorInfo(): string; }
interface WebError { error: ErrorInfo; }

@Entry
@Component
struct WebViewPage {
  @State pageTitle: string = '加载中...';
  @State loadProgress: number = 0;
  @State canGoBack: boolean = false;
  @State canGoForward: boolean = false;
  @State isError: boolean = false;
  @State errorMsg: string = '';
  private url: string = '';
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.url = (params['url'] as string) || '';
      this.pageTitle = (params['title'] as string) || '加载中...';
    }
  }

  /**
   * 在系统浏览器中打开（降级方案）
   */
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
      // ── 顶部导航栏 ──
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => {
            if (this.canGoBack && this.webController.accessBackward()) {
              this.webController.backward();
            } else {
              router.back();
            }
          })

        Column() {
          Text(this.pageTitle)
            .fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.TEXT_PRIMARY).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }.layoutWeight(1).margin({ left: 12, right: 12 })

        // 前进按钮
        if (this.canGoForward) {
          Text('→').fontSize(20).fontColor(ColorTokens.TEXT_SECONDARY)
            .margin({ right: 12 })
            .onClick(() => {
              if (this.webController.accessForward()) {
                this.webController.forward();
              }
            })
        }

        // 在浏览器中打开
        Text('⋮').fontSize(22).fontColor(ColorTokens.TEXT_SECONDARY)
          .onClick(() => { this.openInBrowser(this.url); })
      }
      .width('100%').height(48).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)
      .alignItems(VerticalAlign.Center)

      // ── 加载进度条 ──
      if (this.loadProgress > 0 && this.loadProgress < 100) {
        Progress({ value: this.loadProgress, total: 100, type: ProgressType.Linear })
          .width('100%').color(ColorTokens.PRIMARY).height(2)
      }

      // ── WebView 内容区 ──
      if (this.isError) {
        // 错误页面
        Column() {
          Text('⚠️').fontSize(48).margin({ top: 80 })
          Text('页面加载失败').fontSize(18).fontColor(ColorTokens.TEXT_PRIMARY).margin({ top: 16 })
          Text(this.errorMsg).fontSize(13).fontColor(ColorTokens.TEXT_HINT).margin({ top: 8 })
          Row() {
            Button('重试')
              .fontSize(14).fontColor('#FFFFFF')
              .backgroundColor(ColorTokens.PRIMARY).borderRadius(20)
              .height(36).padding({ left: 24, right: 24 })
              .onClick(() => {
                this.isError = false;
                this.webController.loadUrl(this.url);
              })
            Button('在浏览器中打开')
              .fontSize(14).fontColor(ColorTokens.PRIMARY)
              .backgroundColor(ColorTokens.BG_INPUT).borderRadius(20)
              .height(36).padding({ left: 24, right: 24 })
              .margin({ left: 12 })
              .onClick(() => { this.openInBrowser(this.url); })
          }.margin({ top: 20 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        Web({ src: this.url, controller: this.webController })
          .layoutWeight(1)
          .width('100%')
          .darkMode(WebDarkMode.Auto)
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .onlineImageAccess(true)
          .mixedMode(MixedMode.All)
          .mediaPlayGestureAccess(true)
          .allowWindowOpenMethod(false)
          .onPageBegin((event: PageEvent) => {
            if (event) {
              this.loadProgress = 10;
            }
          })
          .onPageEnd((event: PageEvent) => {
            if (event) {
              this.loadProgress = 100;
              this.canGoBack = this.webController.accessBackward();
              this.canGoForward = this.webController.accessForward();
              try {
                const title = this.webController.getTitle();
                if (title && title.length > 0) {
                  this.pageTitle = title;
                }
              } catch (e) {}
            }
          })
          .onProgressChange((event: ProgressEvent) => {
            if (event) {
              this.loadProgress = event.newProgress;
            }
          })
          .onErrorReceive((event: WebError) => {
            if (event) {
              this.isError = true;
              this.errorMsg = event.error.getErrorInfo() || '未知错误';
            }
          })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(ColorTokens.BG_PAGE)
  }
}
