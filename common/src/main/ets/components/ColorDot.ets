// ============================================================
// ColorDot — 装饰小圆点组件
// 亮色模式：多彩点缀 / 深色模式：纯白星空（微闪烁）
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct ColorDot {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop size: number = 6;
  @Prop color: string = ''; // 空则自动选择
  @Prop opacity: number = 0.8;

  // ── 星空闪烁状态（深色模式专用） ─────────────
  @State private twinkleOpacity: number = 0.8;
  @State private twinkleDuration: number = 2500; // 固定随机值，避免 build() 中 Math.random()

  private get isDark(): boolean {
    return this.isDarkMode;
  }

  private get dotColor(): string {
    if (this.color) {
      return this.color;
    }
    // 自动选择颜色
    return this.isDark ? ColorTokens.DOT_COLOR_DARK : ColorTokens.PRIMARY_LIGHT;
  }

  aboutToAppear(): void {
    // 在初始化时生成固定随机值，避免 build() 中每帧重新随机
    this.twinkleDuration = 2000 + Math.random() * 1000;
    if (this.isDark) {
      this.startTwinkle();
    }
  }

  // ── 星空闪烁动画 ────────────────────────────
  private startTwinkle(): void {
    // 随机延迟启动，让多个圆点不同步闪烁
    const delay = Math.random() * 2000;
    setTimeout(() => {
      this.twinkleOpacity = 0.3;
    }, delay);
  }

  build() {
    Circle({ width: this.size, height: this.size })
      .fill(this.dotColor)
      .opacity(this.isDark ? this.twinkleOpacity : this.opacity)
      .animation(
        this.isDark
          ? { duration: this.twinkleDuration, curve: Curve.EaseInOut, iterations: -1 }
          : undefined
      )
  }
}

// ============================================================
// 使用示例
// ============================================================

/*
// 基础用法
ColorDot()

// 自定义大小和颜色
ColorDot({
  size: 10,
  color: ColorTokens.ACCENT_PINK_LIGHT,
  opacity: 0.6
})

// 列表项前的装饰点
Row() {
  ColorDot({ size: 4, color: ColorTokens.typeColor(item.type, this.isDark) })
  Text(item.title)
}

// 卡片角落装饰
Stack({ alignContent: Alignment.TopEnd }) {
  // 卡片内容
  ColorDot({ size: 12, opacity: 0.8 })
    .margin({ top: 12, right: 12 })
}
*/
