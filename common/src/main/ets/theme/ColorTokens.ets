// ============================================================
// ColorTokens — Flat modern palette with dark mode support
// Primary: Coral red, no gradients, no navy blue
// ============================================================

export class ColorTokens {
  // ── Brand ────────────────────────────────────
  static readonly PRIMARY = '#FF5A5F';
  static readonly PRIMARY_LIGHT = '#FFF0F0';
  static readonly ACCENT = '#FF5A5F';
  static readonly ACCENT_LIGHT = '#FFF0F0';

  // ── Text (light) ─────────────────────────────
  static readonly TEXT_PRIMARY = '#000000';
  static readonly TEXT_SECONDARY = '#444444';
  static readonly TEXT_HINT = '#999999';
  static readonly TEXT_DISABLED = '#CCCCCC';
  static readonly TEXT_WHITE = '#FFFFFF';

  // ── Text (dark) ──────────────────────────────
  static readonly TEXT_PRIMARY_DARK = '#E8E8E8';
  static readonly TEXT_SECONDARY_DARK = '#BBBBBB';
  static readonly TEXT_HINT_DARK = '#888888';
  static readonly TEXT_DISABLED_DARK = '#555555';

  // ── Backgrounds (light) ──────────────────────
  static readonly BG_PAGE = '#FFFFFF';
  static readonly BG_CARD = '#FFFFFF';
  static readonly BG_INPUT = '#F5F5F5';
  static readonly BG_AVATAR = '#F0F0F0';

  // ── Backgrounds (dark) ───────────────────────
  static readonly BG_PAGE_DARK = '#121212';
  static readonly BG_CARD_DARK = '#1E1E1E';
  static readonly BG_INPUT_DARK = '#2C2C2C';
  static readonly BG_AVATAR_DARK = '#333333';
  static readonly PRIMARY_LIGHT_DARK = '#3D1A1A';
  static readonly ACCENT_LIGHT_DARK = '#3D1A1A';

  // ── Type colors ──────────────────────────────
  static readonly TYPE_VIDEO = '#FF5A5F';
  static readonly TYPE_BOOK = '#FF8C42';
  static readonly TYPE_SOFTWARE = '#4A90D9';
  static readonly TYPE_TUTORIAL = '#3A8C6E';
  static readonly TYPE_DEFAULT = '#999999';

  // ── Functional ───────────────────────────────
  static readonly GOLD = '#FF8C42';
  static readonly GREEN = '#3A8C6E';
  static readonly RED = '#FF5A5F';
  static readonly PURPLE = '#7C5CBF';
  static readonly SECONDARY = '#3A8C6E';
  static readonly SECONDARY_LIGHT = '#EDF5F1';
  static readonly SECONDARY_LIGHT_DARK = '#1A2E24';

  // ── Borders & Dividers ───────────────────────
  static readonly DIVIDER = '#EEEEEE';
  static readonly DIVIDER_DARK = '#333333';
  static readonly SHADOW_LIGHT = '#08000000';
  static readonly SHADOW_MEDIUM = '#12000000';

  // ── Banner backgrounds (flat, no gradients) ──
  static readonly BANNER_COLORS: string[] = [
    '#FF5A5F', '#FF8C42', '#4A90D9', '#3A8C6E', '#7C5CBF'
  ];

  // ── Rank colors ──────────────────────────────
  static readonly RANK_COLORS: string[] = [
    '#FF5A5F', '#FF8C42', '#4A90D9', '#999999'
  ];

  // ── Dark mode resolution ─────────────────────
  /**
   * 根据当前主题模式解析颜色值
   * @param token 浅色色值
   * @param darkToken 深色色值
   * @param isDark 是否深色模式
   */
  static resolve(token: string, darkToken: string, isDark: boolean): string {
    return isDark ? darkToken : token;
  }

  // ── Convenience methods for common tokens ─────
  static textPrimary(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_PRIMARY_DARK : ColorTokens.TEXT_PRIMARY;
  }
  static textSecondary(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_SECONDARY_DARK : ColorTokens.TEXT_SECONDARY;
  }
  static textHint(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_HINT_DARK : ColorTokens.TEXT_HINT;
  }
  static textDisabled(isDark: boolean): string {
    return isDark ? ColorTokens.TEXT_DISABLED_DARK : ColorTokens.TEXT_DISABLED;
  }
  static bgPage(isDark: boolean): string {
    return isDark ? ColorTokens.BG_PAGE_DARK : ColorTokens.BG_PAGE;
  }
  static bgCard(isDark: boolean): string {
    return isDark ? ColorTokens.BG_CARD_DARK : ColorTokens.BG_CARD;
  }
  static bgInput(isDark: boolean): string {
    return isDark ? ColorTokens.BG_INPUT_DARK : ColorTokens.BG_INPUT;
  }
  static primaryLight(isDark: boolean): string {
    return isDark ? ColorTokens.PRIMARY_LIGHT_DARK : ColorTokens.PRIMARY_LIGHT;
  }
  static accentLight(isDark: boolean): string {
    return isDark ? ColorTokens.ACCENT_LIGHT_DARK : ColorTokens.ACCENT_LIGHT;
  }
  static divider(isDark: boolean): string {
    return isDark ? ColorTokens.DIVIDER_DARK : ColorTokens.DIVIDER;
  }
  static secondaryLight(isDark: boolean): string {
    return isDark ? ColorTokens.SECONDARY_LIGHT_DARK : ColorTokens.SECONDARY_LIGHT;
  }

  // ── Utils ────────────────────────────────────
  static forType(type: string): string {
    switch (type) {
      case 'video': return ColorTokens.TYPE_VIDEO;
      case 'book': return ColorTokens.TYPE_BOOK;
      case 'software': return ColorTokens.TYPE_SOFTWARE;
      case 'tutorial': return ColorTokens.TYPE_TUTORIAL;
      default: return ColorTokens.TYPE_DEFAULT;
    }
  }

  static withAlpha(color: string, alphaHex: string): string {
    return color + alphaHex;
  }
}
