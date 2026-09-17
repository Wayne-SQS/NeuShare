// ============================================================
// BlurPerformance — 毛玻璃性能分级管理
// 滚动时关闭 blur / 低端设备降级为纯色 / 三级模糊策略
// ============================================================

export enum BlurLevel {
  NONE = 0,    // 无模糊（低端设备 / 滚动中）
  LOW = 20,    // 低模糊（中端设备）
  HIGH = 40,   // 高模糊（高端设备 / 静态时）
}

export class BlurPerformance {
  // ── AppStorage 键名 ─────────────────────────
  static readonly KEY_IS_SCROLLING = 'isScrolling';
  static readonly KEY_BLUR_LEVEL = 'blurLevel';

  // ── 静态缓存，避免 onScrollFrameBegin 每帧 AppStorage 查询 ─
  private static _isScrolling: boolean = false;

  // ── 初始化（应用启动时调用一次） ──────────────
  static init(): void {
    AppStorage.setOrCreate(BlurPerformance.KEY_IS_SCROLLING, false);
    AppStorage.setOrCreate(BlurPerformance.KEY_BLUR_LEVEL, BlurLevel.HIGH);
  }

  // ── 检测设备能力并设置模糊等级 ────────────────
  // 可根据 display DPI / 内存等信息扩展
  static detectDeviceCapability(): void {
    try {
      // 简单策略：默认 HIGH，后续可根据设备信息降级
      // HarmonyOS 可通过 @ohos.deviceInfo 获取设备信息
      // 目前保守策略：所有设备默认 HIGH，滚动时自动降级
      AppStorage.setOrCreate(BlurPerformance.KEY_BLUR_LEVEL, BlurLevel.HIGH);
    } catch (e) {
      AppStorage.setOrCreate(BlurPerformance.KEY_BLUR_LEVEL, BlurLevel.LOW);
    }
  }

  // ── 获取当前有效模糊半径 ──────────────────────
  static effectiveBlur(isDark: boolean): number {
    if (isDark) {
      return 0; // 深色模式不使用毛玻璃
    }
    const isScrolling: boolean = AppStorage.get(BlurPerformance.KEY_IS_SCROLLING) ?? false;
    if (isScrolling) {
      return 0; // 滚动中关闭模糊
    }
    const level: number = AppStorage.get(BlurPerformance.KEY_BLUR_LEVEL) ?? BlurLevel.HIGH;
    return level;
  }

  // ── 滚动开始（静态缓存 + 守卫，避免 onScrollFrameBegin 每帧写 AppStorage） ──
  static onScrollStart(): void {
    if (!BlurPerformance._isScrolling) {
      BlurPerformance._isScrolling = true;
      AppStorage.setOrCreate(BlurPerformance.KEY_IS_SCROLLING, true);
    }
  }

  // ── 滚动结束 ────────────────────────────────
  static onScrollStop(): void {
    if (BlurPerformance._isScrolling) {
      BlurPerformance._isScrolling = false;
      AppStorage.setOrCreate(BlurPerformance.KEY_IS_SCROLLING, false);
    }
  }

  // ── 获取纯色降级背景（模糊关闭时替代半透明） ──
  static fallbackBg(isDark: boolean): string {
    return isDark ? '#1C1C1F' : '#F0F3FF'; // 深色：卡片色 / 亮色：接近页面底色的不透明色
  }
}
