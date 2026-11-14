import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import display from '@ohos.display';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { BreakpointSystem, AppTheme } from '@neushare/common';

interface AppConfiguration {
  colorMode: ConfigurationConstant.ColorMode;
}

export default class EntryAbility extends UIAbility {
  private searchKeyword: string = '';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onCreate');
    // 将 AbilityContext 存入 AppStorage，供 ShareHelper 等服务使用
    AppStorage.setOrCreate('context', this.context);
    // 处理小艺搜索意图
    this.handleIntent(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onNewWant');
    this.handleIntent(want);
    // App 已在后台时，onNewWant 触发但不会重新 loadContent
    // 通过 AppStorage 传递关键词，SearchPage 可监听变化
    if (this.searchKeyword) {
      AppStorage.setOrCreate('searchKeyword', this.searchKeyword);
    }
  }

  /**
   * 处理意图框架传入的搜索请求
   * 小艺助手："在NEUShare搜索高数" → 提取关键词 → 跳转搜索页
   */
  private handleIntent(want: Want): void {
    if (!want || !want.parameters) return;

    const action = want.action;
    if (action === 'ohos.want.action.search' || action === 'action.search') {
      // 从意图参数中提取搜索关键词
      const keyword = want.parameters['keyword'] as string ||
        want.parameters['query'] as string ||
        want.parameters['search'] as string || '';

      if (keyword) {
        this.searchKeyword = keyword;
        console.info('Intent search keyword: ' + keyword);
      }
    }

    // 处理 deeplink: neushare://search?keyword=xxx
    if (want.uri && want.uri.startsWith('neushare://search')) {
      const uri = want.uri;
      const match = uri.match(/keyword=([^&]+)/);
      if (match && match[1]) {
        this.searchKeyword = decodeURIComponent(match[1]);
      }
    }
  }

  getSearchKeyword(): string {
    return this.searchKeyword;
  }

  clearSearchKeyword(): void {
    this.searchKeyword = '';
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Initialize theme from system config
    AppTheme.getInstance().initFromContext(this.context);

    // 注册 window 尺寸变化监听（教程 §2.6 方式二）
    // size.width 自动为 vp 单位，无需 px→vp 转换
    // 断点初始值由 Index.aboutToAppear() 中的 mediaQuery 设置（对齐 QuickStart）
    try {
      const mainWindow = await windowStage.getMainWindow();

      // 沉浸式状态栏（教程 §9 + §14.4）
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00FFFFFF',
        navigationBarColor: '#00FFFFFF',
        isStatusBarLightIcon: false,
        isNavigationBarLightIcon: false
      });

      mainWindow.on('windowSizeChange', (size: window.Size) => {
        BreakpointSystem.getInstance().updateFromVpWidth(size.width, size.height);
      });

      // 记录状态栏高度（vp），供 PageScaffold 统一处理安全区
      this.updateSafeArea(mainWindow);
      mainWindow.on('avoidAreaChange', () => {
        this.updateSafeArea(mainWindow);
      });
    } catch (e) {
      console.warn('[EntryAbility] windowSizeChange registration failed: ' + JSON.stringify(e));
    }

    // 将搜索关键词写入 AppStorage，供 SearchPage 读取
    if (this.searchKeyword) {
      AppStorage.setOrCreate('searchKeyword', this.searchKeyword);
    }

    // 根据是否有搜索意图决定加载哪个页面
    const startPage = this.searchKeyword ? 'pages/SearchPage' : 'pages/SplashPage';
    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        console.error('Failed to load content: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in loading content');
    });
  }

  /**
   * 读取系统状态栏避让高度并转为 vp 存入 AppStorage。
   * AvoidArea 的 Rect 以 px 为单位，这里用屏幕密度换算；仅做单位换算，
   * 断点判定仍走 window/mediaQuery（display 的尺寸接口在模拟器上不可靠）。
   * 注意：只有窗口处于沉浸式（内容延伸到状态栏下）时才需要额外留白，
   * 非沉浸式下窗口内容本就在状态栏之下，再加 padding 会出现双倍留白，
   * 因此这里先用 getWindowLayoutFullScreen() 判断，避免重复留白。
   */
  private async updateSafeArea(mainWindow: window.Window): Promise<void> {
    try {
      const isFullScreen: boolean = await mainWindow.getWindowLayoutFullScreen();
      if (!isFullScreen) {
        AppStorage.setOrCreate<number>('topSafeAreaVp', 0);
        AppStorage.setOrCreate<number>('bottomSafeAreaVp', 0);
        return;
      }
      const avoid: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const density: number = display.getDefaultDisplaySync().densityPixels || 1;
      const topVp: number = Math.round(avoid.topRect.height / density);
      AppStorage.setOrCreate<number>('topSafeAreaVp', topVp);
      const bottomVp: number = Math.round(avoid.bottomRect.height / density);
      AppStorage.setOrCreate<number>('bottomSafeAreaVp', bottomVp);
    } catch (e) {
      console.warn('[EntryAbility] updateSafeArea failed: ' + JSON.stringify(e));
    }
  }

  onWindowStageDestroy(): void {
    console.info('EntryAbility onWindowStageDestroy');
    BreakpointSystem.getInstance().unregister();
  }

  onForeground(): void {
    console.info('EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('EntryAbility onBackground');
  }

  onConfigurationUpdate(newConfig: AppConfiguration): void {
    // 系统暗色模式切换时更新 AppStorage
    if (newConfig && newConfig.colorMode !== undefined) {
      AppTheme.getInstance().onConfigurationUpdate(newConfig.colorMode);
    }
  }
}
