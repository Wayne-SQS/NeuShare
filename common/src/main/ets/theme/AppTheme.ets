import { ColorTokens } from './ColorTokens';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import common from '@ohos.app.ability.common';

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

export class AppTheme {
  private static instance: AppTheme;
  private _currentMode: ThemeMode = ThemeMode.SYSTEM;

  static getInstance(): AppTheme {
    if (!AppTheme.instance) {
      AppTheme.instance = new AppTheme();
    }
    return AppTheme.instance;
  }

  get currentMode(): ThemeMode {
    return this._currentMode;
  }

  setThemeMode(mode: ThemeMode): void {
    this._currentMode = mode;
    this.updateDarkMode();
  }

  /**
   * 根据系统配置判断当前是否应为深色模式
   * @param colorMode 系统配置的 colorMode
   */
  onConfigurationUpdate(colorMode: ConfigurationConstant.ColorMode): void {
    if (this._currentMode === ThemeMode.SYSTEM) {
      const isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      AppStorage.setOrCreate('isDarkMode', isDark);
    }
  }

  /**
   * 初始化：读取系统当前颜色模式
   */
  initFromContext(context: Context): void {
    if (this._currentMode === ThemeMode.SYSTEM) {
      const ctx: common.UIAbilityContext = context as common.UIAbilityContext;
      if (ctx.config && ctx.config.colorMode !== undefined) {
        const isDark: boolean = ctx.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
        AppStorage.setOrCreate('isDarkMode', isDark);
      }
    }
    this.updateDarkMode();
  }

  private updateDarkMode(): void {
    if (this._currentMode === ThemeMode.DARK) {
      AppStorage.setOrCreate('isDarkMode', true);
    } else if (this._currentMode === ThemeMode.LIGHT) {
      AppStorage.setOrCreate('isDarkMode', false);
    }
    // SYSTEM 模式下由 onConfigurationUpdate 处理
  }

  isDarkMode(): boolean {
    return AppStorage.get<boolean>('isDarkMode') || false;
  }
}
