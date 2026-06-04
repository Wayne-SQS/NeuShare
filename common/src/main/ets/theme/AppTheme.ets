import { ColorTokens } from './ColorTokens';

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

export class AppTheme {
  private static instance: AppTheme;
  private _currentMode: ThemeMode = ThemeMode.LIGHT;

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
  }
}
