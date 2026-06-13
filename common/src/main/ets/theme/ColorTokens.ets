// ============================================================
// ColorTokens — Light: 多彩玻璃质感 / Dark: 极简黑白
// 设计原则：亮色清新跳脱 · 深色极简专业
// 两种主题使用完全不同的视觉语言
// ============================================================

// ── 主题模式 ────────────────────────────────
export enum ColorMode {
  LIGHT = 'light',
  DARK = 'dark',
}

// ── 辅助：取当前主题模式 ────────────────────
// 各页面通过 @StorageLink('colorMode') 订阅
// 在 build() 中判断 mode 并读取对应 token

export class ColorTokens {
  // ════════════════════════════════════════════
  // 亮色模式 (Light) — 清新跳脱 · 玻璃质感
  // ════════════════════════════════════════════

  // ── 品牌色 ──────────────────────────────────
  static readonly PRIMARY_LIGHT = '#4A6BFF';       // 清爽靛蓝
  static readonly ACCENT_PINK_LIGHT = '#FF8FB1';   // 粉色
  static readonly ACCENT_LAVENDER_LIGHT = '#C4B5FD'; // 薰衣草紫
  static readonly ACCENT_SKY_LIGHT = '#89CFEF';    // 天空蓝
  static readonly ACCENT_TEAL_LIGHT = '#00C2CB';   // 青蓝

  // ── 背景色 ──────────────────────────────────
  static readonly BG_PAGE_LIGHT = '#F4F7FF';        // 淡蓝白基底
  static readonly BG_CARD_LIGHT = '#B8FFFFFF';      // 72%透明白（毛玻璃主卡）
  static readonly BG_CARD_SECOND_LIGHT = '#E6FFFFFF'; // 90%透明白（次卡）
  static readonly BG_INPUT_LIGHT = '#CCFFFFFF';     // 80%透明白（输入框）

  // ── 文字色 ──────────────────────────────────
  static readonly TEXT_PRIMARY_LIGHT = '#1E2A5C';   // 深靛蓝
  static readonly TEXT_SECONDARY_LIGHT = '#5A6A9C'; // 中靛蓝灰
  static readonly TEXT_HINT_LIGHT = '#A0B0D8';      // 浅靛蓝灰

  // ── 功能色 ──────────────────────────────────
  static readonly SUCCESS_LIGHT = '#89CFEF';
  static readonly WARNING_LIGHT = '#FFB5A7';
  static readonly ERROR_LIGHT = '#FF6B6B';

  // ── 分隔线 ───────────────────────────────────
  static readonly DIVIDER_LIGHT = '#55D4DCF0';      // 极淡蓝灰 33%透明

  // ── 玻璃质感参数 ────────────────────────────
  static readonly BLUR_RADIUS_LIGHT = 40;            // 毛玻璃模糊半径
  static readonly CARD_RADIUS_LIGHT = 20;            // 卡片圆角
  static readonly INPUT_RADIUS_LIGHT = 12;           // 输入框圆角
  static readonly BUTTON_RADIUS_LIGHT = 14;          // 按钮圆角

  // ── 渐变配色（Banner/Hero 用） ─────────────
  static readonly GRADIENT_BLUE_TEAL: string[] = ['#4A6BFF', '#00C2CB'];
  static readonly GRADIENT_PINK_LAVENDER: string[] = ['#FF8FB1', '#C4B5FD'];
  static readonly GRADIENT_SKY_TEAL: string[] = ['#89CFEF', '#00C2CB'];
  static readonly GRADIENT_BLUE_PINK: string[] = ['#4A6BFF', '#FF8FB1'];
  static readonly GRADIENT_LAVENDER_SKY: string[] = ['#C4B5FD', '#89CFEF'];

  // ── 类型配色（多彩） ────────────────────────
  static readonly TYPE_VIDEO_LIGHT = '#FF8FB1';
  static readonly TYPE_BOOK_LIGHT = '#4A6BFF';
  static readonly TYPE_SOFTWARE_LIGHT = '#00C2CB';
  static readonly TYPE_TUTORIAL_LIGHT = '#C4B5FD';
  static readonly TYPE_DEFAULT_LIGHT = '#89CFEF';

  // ════════════════════════════════════════════
  // 深色模式 (Dark) — 极简黑白 · 高级专业
  // ════════════════════════════════════════════

  // ── 品牌色（唯一：纯白） ────────────────────
  static readonly PRIMARY_DARK = '#FFFFFF';         // 纯白强调

  // ── 背景色（靠明度差分层，无彩色） ──────────
  static readonly BG_PAGE_DARK = '#0E0E10';         // 极深灰（页面基底）
  static readonly BG_CARD_DARK = '#1C1C1F';         // 深灰（卡片）
  static readonly BG_INPUT_DARK = '#161618';        // 比卡片略深（输入框凹陷感）

  // ── 文字色 ──────────────────────────────────
  static readonly TEXT_PRIMARY_DARK = '#F2F2F4';    // 近白
  static readonly TEXT_SECONDARY_DARK = '#8A8A93';  // 中灰
  static readonly TEXT_HINT_DARK = '#6B6B73';       // 深灰（提升对比度至 4.5:1 以上）

  // ── 功能色（全白 / 近白，靠强度区分） ────────
  static readonly SUCCESS_DARK = '#E8E8EC';         // 近白
  static readonly WARNING_DARK = '#FFFFFF';         // 纯白（加粗）
  static readonly ERROR_DARK = '#FFFFFF';           // 纯白（加粗+图标）

  // ── 分隔线 / 边框 ───────────────────────────
  static readonly DIVIDER_DARK = '#2A2A2E';         // 极淡边框

  // ── 深色模式参数 ────────────────────────────
  static readonly CARD_RADIUS_DARK = 14;             // 更小，更利落
  static readonly INPUT_RADIUS_DARK = 10;
  static readonly BUTTON_RADIUS_DARK = 14;

  // ════════════════════════════════════════════
  // 通用便捷方法 — 自动根据 isDark 返回对应色
  // ════════════════════════════════════════════

  static resolve(lightColor: string, darkColor: string, isDark: boolean): string {
    return isDark ? darkColor : lightColor;
  }

  // ── 品牌色 ──────────────────────────────────
  static primary(isDark: boolean): string {
    return isDark ? ColorTokens.PRIMARY_DARK : ColorTokens.PRIMARY_LIGHT;
  }

  // ── 背景色 ──────────────────────────────────
  static bgPage(isDark: boolean): string {
    return isDark ? ColorTokens.BG_PAGE_DARK : ColorTokens.BG_PAGE_LIGHT;
  }
  static bgCard(isDark: boolean): string {
    return isDark ? ColorTokens.BG_CARD_DARK : ColorTokens.BG_CARD_LIGHT;
  }
  static bgCardSecond(isDark: boolean): string {
    return isDark ? ColorTokens.BG_CARD_DARK : ColorTokens.BG_CARD_SECOND_LIGHT;
  }
  static bgInput(isDark: boolean): string {
    return isDark ? ColorTokens.BG_INPUT_DARK : ColorTokens.BG_INPUT_LIGHT;
  }

  // ── 文字色 ──────────────────────────────────
  static textPrimary(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_PRIMARY_DARK : ColorTokens.TEXT_PRIMARY_LIGHT;
  }
  static textSecondary(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_SECONDARY_DARK : ColorTokens.TEXT_SECONDARY_LIGHT;
  }
  static textHint(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_HINT_DARK : ColorTokens.TEXT_HINT_LIGHT;
  }

  // ── 功能色 ──────────────────────────────────
  static success(isDark: boolean): string {
    return isDark ? ColorTokens.SUCCESS_DARK : ColorTokens.SUCCESS_LIGHT;
  }
  static warning(isDark: boolean): string {
    return isDark ? ColorTokens.WARNING_DARK : ColorTokens.WARNING_LIGHT;
  }
  static error(isDark: boolean): string {
    return isDark ? ColorTokens.ERROR_DARK : ColorTokens.ERROR_LIGHT;
  }

  // ── 分隔线 ───────────────────────────────────
  static divider(isDark: boolean): string {
    return isDark ? ColorTokens.DIVIDER_DARK : ColorTokens.DIVIDER_LIGHT;
  }

  // ── 卡片圆角 ────────────────────────────────
  static cardRadius(isDark: boolean): number {
    return isDark ? ColorTokens.CARD_RADIUS_DARK : ColorTokens.CARD_RADIUS_LIGHT;
  }

  // ── 类型配色（亮色多彩 / 深色统一近白） ───────
  static typeColor(type: string, isDark: boolean): string {
    if (isDark) {
      return ColorTokens.TEXT_SECONDARY_DARK; // 深色模式统一中灰，靠文字而非颜色区分类型
    }
    switch (type) {
      case 'video': return ColorTokens.TYPE_VIDEO_LIGHT;
      case 'book': return ColorTokens.TYPE_BOOK_LIGHT;
      case 'software': return ColorTokens.TYPE_SOFTWARE_LIGHT;
      case 'tutorial': return ColorTokens.TYPE_TUTORIAL_LIGHT;
      default: return ColorTokens.TYPE_DEFAULT_LIGHT;
    }
  }

  // ── 深色模式字母标签缩写 ───────────────────
  static typeAbbreviation(type: string): string {
    switch (type) {
      case 'video': return 'VID';
      case 'book': return 'BOOK';
      case 'software': return 'SOFT';
      case 'tutorial': return 'NOTE';
      default: return 'OTHR';
    }
  }

  // ── 透明度工具 ─────────────────────────────
  // 用法：ColorTokens.withAlpha('#4A6BFF', '80') → '#804A6BFF'（HarmonyOS 使用 #AARRGGBB 格式）
  static withAlpha(color: string, alphaHex: string): string {
    // 输入 #RRGGBB，输出 #AARRGGBB
    if (color.startsWith('#') && color.length === 7) {
      return '#' + alphaHex + color.substring(1);
    }
    return color;
  }

  // ════════════════════════════════════════════
  // 向后兼容别名 — 默认指向浅色模式
  // ════════════════════════════════════════════

  // ── 品牌色 ──────────────────────────────────
  static readonly PRIMARY = ColorTokens.PRIMARY_LIGHT;
  static readonly ACCENT = ColorTokens.PRIMARY_LIGHT;

  // ── 类型色（浅色模式多彩） ──────────────────
  static readonly TYPE_VIDEO = ColorTokens.TYPE_VIDEO_LIGHT;
  static readonly TYPE_BOOK = ColorTokens.TYPE_BOOK_LIGHT;
  static readonly TYPE_SOFTWARE = ColorTokens.TYPE_SOFTWARE_LIGHT;
  static readonly TYPE_TUTORIAL = ColorTokens.TYPE_TUTORIAL_LIGHT;
  static readonly TYPE_DEFAULT = ColorTokens.TYPE_DEFAULT_LIGHT;

  // ── 背景色 ──────────────────────────────────
  static readonly BG_PAGE = ColorTokens.BG_PAGE_LIGHT;
  static readonly BG_CARD = ColorTokens.BG_CARD_LIGHT;
  static readonly BG_INPUT = ColorTokens.BG_INPUT_LIGHT;
  static readonly BG_AVATAR = '#EDF0FF';            // 浅靛蓝（头像占位底）
  static readonly BG_AVATAR_DARK = '#2A2A2E';

  // ── 文字色 ──────────────────────────────────
  static readonly TEXT_PRIMARY = ColorTokens.TEXT_PRIMARY_LIGHT;
  static readonly TEXT_SECONDARY = ColorTokens.TEXT_SECONDARY_LIGHT;
  static readonly TEXT_HINT = ColorTokens.TEXT_HINT_LIGHT;
  static readonly TEXT_DISABLED = '#C4CCE8';        // 浅靛蓝灰（禁用态）
  static readonly TEXT_DISABLED_DARK = '#4E4E55';
  static readonly TEXT_WHITE = '#FFFFFF';

  // ── 功能色 ──────────────────────────────────
  static readonly GREEN = ColorTokens.SUCCESS_LIGHT;
  static readonly RED = ColorTokens.ERROR_LIGHT;
  static readonly GOLD = '#FFB5A7';               // 柔桃色（评分/收藏用，替代金色）
  static readonly PURPLE = '#7C5CBF';              // 保留紫色（ModelCompare 推理能力条）
  static readonly SECONDARY = ColorTokens.ACCENT_TEAL_LIGHT;
  static readonly SECONDARY_LIGHT = '#E0FAFB';     // 极浅青蓝
  static readonly SECONDARY_LIGHT_DARK = '#1A2E2E';

  // ── 分隔线 / 阴影 ────────────────────────────
  static readonly DIVIDER = ColorTokens.DIVIDER_LIGHT;
  static readonly DIVIDER_DARK_ALIAS = ColorTokens.DIVIDER_DARK;
  static readonly SHADOW_LIGHT = '#08000000';       // 极淡阴影
  static readonly SHADOW_MEDIUM = '#154A6BFF';      // 品牌色淡阴影（spec 推荐）

  // ── 深色模式兼容别名 ────────────────────────
  static readonly PRIMARY_LIGHT_DARK = '#2A2A2E';   // 深色模式下浅靛蓝背景
  static readonly ACCENT_LIGHT_DARK = '#2A2A2E';
  static readonly ACCENT_LIGHT = '#EDF0FF';         // 极浅靛蓝（标签底色，替代旧 PRIMARY_LIGHT）

  // ── 多彩色盘（Banner / 排行 / 图表） ──────────
  static readonly BANNER_COLORS: string[] = [
    '#4A6BFF', '#FF8FB1', '#C4B5FD', '#89CFEF', '#00C2CB'
  ];
  static readonly RANK_COLORS: string[] = [
    '#4A6BFF', '#FF8FB1', '#00C2CB', '#C4B5FD'
  ];

  // ── 小圆点装饰色盘 ────────────────────────────
  // 亮色模式：5 色缤纷
  static readonly DOT_COLORS_LIGHT: string[] = [
    '#4A6BFF', '#FF8FB1', '#C4B5FD', '#89CFEF', '#00C2CB'
  ];
  // 深色模式：仅纯白，靠大小和透明度变化
  static readonly DOT_COLOR_DARK = '#FFFFFF';

  // ── 兼容旧 API ──────────────────────────────
  static forType(type: string): string {
    return ColorTokens.typeColor(type, false);
  }

  // 旧代码可能用的深色工具方法
  static primaryLight(isDark: boolean): string {
    return isDark ? ColorTokens.PRIMARY_LIGHT_DARK : ColorTokens.PRIMARY_LIGHT;
  }
  static accentLight(isDark: boolean): string {
    return isDark ? ColorTokens.ACCENT_LIGHT_DARK : ColorTokens.ACCENT_LIGHT;
  }
  static secondaryLight(isDark: boolean): string {
    return isDark ? ColorTokens.SECONDARY_LIGHT_DARK : ColorTokens.SECONDARY_LIGHT;
  }
  static textDisabled(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_DISABLED_DARK : ColorTokens.TEXT_DISABLED;
  }
}
