// ============================================================
// ColorTokens — Warm Academia palette
// Inspired by university press typography & modern editorial design
// ============================================================

export class ColorTokens {
  // ── Brand ────────────────────────────────────
  /** Deep navy-indigo — headers, primary actions */
  static readonly PRIMARY = '#2C3E6B';
  /** Soft powder blue — tags, highlights */
  static readonly PRIMARY_LIGHT = '#E8EDF6';
  /** Warm amber — accents, CTAs, ratings */
  static readonly ACCENT = '#D4914A';
  /** Warm amber light */
  static readonly ACCENT_LIGHT = '#FDF2E4';

  // ── Text ─────────────────────────────────────
  /** Rich charcoal — body */
  static readonly TEXT_PRIMARY = '#1E2130';
  /** Warm gray — secondary */
  static readonly TEXT_SECONDARY = '#6B6E7B';
  /** Muted slate — hints */
  static readonly TEXT_HINT = '#8E91A0';
  /** Disabled */
  static readonly TEXT_DISABLED = '#C0C2CC';
  /** On dark */
  static readonly TEXT_WHITE = '#FFFFFF';

  // ── Backgrounds ──────────────────────────────
  /** Warm paper white — page background */
  static readonly BG_PAGE = '#F7F5F2';
  /** Pure white — cards */
  static readonly BG_CARD = '#FFFFFF';
  /** Soft warm gray — inputs */
  static readonly BG_INPUT = '#F0EEEA';
  /** Avatar placeholder */
  static readonly BG_AVATAR = '#DDE3ED';

  // ── Type colors ──────────────────────────────
  static readonly TYPE_VIDEO = '#C0392B';
  static readonly TYPE_BOOK = '#D4914A';
  static readonly TYPE_SOFTWARE = '#2C7AB5';
  static readonly TYPE_TUTORIAL = '#3A8C6E';
  static readonly TYPE_DEFAULT = '#8E91A0';

  // ── Functional ───────────────────────────────
  static readonly GOLD = '#D4914A';
  static readonly GREEN = '#3A8C6E';
  static readonly RED = '#C0392B';
  static readonly PURPLE = '#7C5CBF';
  static readonly SECONDARY = '#3A8C6E';
  static readonly SECONDARY_LIGHT = '#EDF5F1';

  // ── Borders & Dividers ───────────────────────
  static readonly DIVIDER = '#EBE8E4';
  static readonly SHADOW_LIGHT = '#08000000';
  static readonly SHADOW_MEDIUM = '#12000000';

  // ── Banner gradients ─────────────────────────
  static readonly BANNER_GRADIENT_START: string[] = [
    '#2C3E6B', '#3A5276', '#2C7AB5', '#1E5A7A', '#2C3E6B'
  ];
  static readonly BANNER_GRADIENT_END: string[] = [
    '#4A6594', '#5C7DA4', '#4A9AC5', '#2C7AB5', '#5C7DA4'
  ];

  // ── Rank colors ──────────────────────────────
  static readonly RANK_COLORS: string[] = [
    '#C0392B', '#D4914A', '#2C7AB5', '#8E91A0'
  ];

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
