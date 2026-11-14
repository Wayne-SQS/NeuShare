// ============================================================
// DesignTokens — 尺寸 / 字号 / 圆角 / 间距 / 层级 / 控件尺寸
// 与 ColorTokens 分工：ColorTokens 管颜色，本文件管几何与排版
// 页面中禁止直接写数字字号、数字圆角，统一引用这里的常量
// ============================================================

// ── 间距刻度（vp，4 的倍数） ─────────────────────
export class Spacing {
  static readonly NONE = 0;
  static readonly XXS = 2;
  static readonly XS = 4;
  static readonly SM = 8;
  static readonly MD = 12;
  static readonly LG = 16;
  static readonly XL = 20;
  static readonly XXL = 24;
  static readonly XXXL = 32;
  static readonly HUGE = 40;

  /** 页面左右安全边距 */
  static readonly PAGE = 16;
  /** 区块之间的纵向间距 */
  static readonly SECTION = 20;
  /** 卡片内边距 */
  static readonly CARD = 16;
  /** 列表项之间的间距 */
  static readonly LIST_GAP = 8;
}

// ── 圆角刻度 ────────────────────────────────────
export class Radii {
  static readonly NONE = 0;
  static readonly XXS = 2;
  static readonly XS = 4;
  static readonly SM = 6;
  static readonly MD = 8;
  static readonly LG = 10;
  /** 卡片统一圆角 */
  static readonly CARD = 12;
  static readonly XL = 14;
  static readonly XXL = 16;
  static readonly HUGE = 20;
  /** 胶囊 / 圆形（大于任意控件边长即可） */
  static readonly PILL = 999;
  /** 输入框圆角 */
  static readonly INPUT = 12;
  /** 按钮圆角 */
  static readonly BUTTON = 12;
}

// ── 字号刻度（fp） ──────────────────────────────
// 页面大标题 24/700，区块标题 18/600，正文 15，辅助 13
export class FontScale {
  static readonly NANO = 8;
  static readonly MICRO_SM = 9;
  static readonly TINY = 10;
  static readonly MICRO = 11;
  static readonly LABEL = 12;
  /** 辅助文案 */
  static readonly CAPTION = 13;
  static readonly BODY_SM = 14;
  /** 正文 */
  static readonly BODY = 15;
  static readonly SUBTITLE = 16;
  static readonly SUBTITLE_MD = 17;
  /** 区块标题 */
  static readonly SECTION = 18;
  static readonly TITLE_SM = 20;
  static readonly TITLE_MD = 22;
  /** 页面大标题 */
  static readonly HERO = 24;
  static readonly HERO_SM = 26;
  static readonly HERO_LG = 28;
  static readonly DISPLAY = 30;
  static readonly DISPLAY_MD = 32;
  static readonly DISPLAY_LG = 34;
  static readonly BRAND = 36;
  static readonly ICON_XL = 40;
  static readonly DISPLAY_XL = 44;
  static readonly ICON_XXL = 48;
}

// ── 字重 ────────────────────────────────────────
export class FontWeights {
  static readonly REGULAR: FontWeight = FontWeight.Regular;
  static readonly MEDIUM: FontWeight = FontWeight.Medium;
  static readonly SEMIBOLD: FontWeight = FontWeight.Bold;
  static readonly BOLD: FontWeight = FontWeight.Bold;
  static readonly DISPLAY: FontWeight = FontWeight.Bolder;
}

// ── 控件尺寸 ────────────────────────────────────
export class ControlSize {
  /** 统一操作按钮高度 */
  static readonly BUTTON = 40;
  static readonly BUTTON_LG = 48;
  /** 最小点击热区 */
  static readonly TOUCH = 40;
  static readonly INPUT = 44;
  static readonly INPUT_LG = 48;
  static readonly HEADER = 56;
  /** 底部 Tab 栏高度 */
  static readonly TAB_BAR = 56;
  static readonly ICON = 24;
  static readonly ICON_LG = 48;
}

// ── 描边 / 阴影 ─────────────────────────────────
export class Elevation {
  static readonly BORDER_WIDTH = 1;
  static readonly CARD_SHADOW_RADIUS = 8;
  static readonly CARD_SHADOW_OFFSET_Y = 2;
  static readonly HERO_SHADOW_RADIUS = 12;
  static readonly HERO_SHADOW_OFFSET_Y = 4;
}

// ── 层级 ────────────────────────────────────────
export class ZIndex {
  static readonly BASE = 1;
  static readonly STICKY = 10;
  static readonly FAB = 20;
  static readonly OVERLAY = 100;
  static readonly MODAL = 200;
  static readonly TOAST = 300;
}

// ── 布局约束 ────────────────────────────────────
export class Layout {
  /** 首屏 hero / 轮播最多占屏幕高度的比例 */
  static readonly HERO_MAX_RATIO = 1 / 3;
  /** 正文最大可读宽度（大屏居中） */
  static readonly CONTENT_MAX_SM = 9999;
  static readonly CONTENT_MAX_MD = 576;
  static readonly CONTENT_MAX_LG = 656;
  static readonly CONTENT_MAX_XL = 900;
  /** 列表栅格列数：xs/sm 1 列、md 2 列、lg 3 列、xl 4 列 */
  static readonly GRID_COLUMNS_XS = 1;
  static readonly GRID_COLUMNS_SM = 1;
  static readonly GRID_COLUMNS_MD = 2;
  static readonly GRID_COLUMNS_LG = 3;
  static readonly GRID_COLUMNS_XL = 4;
}

// ── 透明度 ──────────────────────────────────────
export class Opacity {
  static readonly DISABLED = 0.4;
  static readonly SECONDARY = 0.72;
  static readonly HINT = 0.56;
  static readonly OVERLAY = 0.4;
}

// ── 栅格：GridRow 五档断点（与 BreakpointSystem 阈值一致） ──
// xs 0-320 / sm 320-600 / md 600-840 / lg 840-1200 / xl 1200+
export class GridLayout {
  static readonly BREAKPOINTS: string[] = ['320vp', '600vp', '840vp', '1200vp'];

  static columns(): GridRowColumnOption {
    return {
      xs: Layout.GRID_COLUMNS_XS,
      sm: Layout.GRID_COLUMNS_SM,
      md: Layout.GRID_COLUMNS_MD,
      lg: Layout.GRID_COLUMNS_LG,
      xl: Layout.GRID_COLUMNS_XL
    };
  }

  static options(): GridRowOptions {
    return {
      columns: GridLayout.columns(),
      gutter: { x: Spacing.MD, y: Spacing.MD },
      breakpoints: {
        value: GridLayout.BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    };
  }
}
