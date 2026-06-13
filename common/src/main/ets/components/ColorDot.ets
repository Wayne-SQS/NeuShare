// ============================================================
// ColorDot — 装饰小圆点组件
// 亮色模式：多彩点缀 / 深色模式：纯白星空
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct ColorDot {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @Prop size: number = 6;
  @Prop color: string = ''; // 空则自动选择
  @Prop opacity: number = 0.8;

  private get isDark(): boolean {
    return this.isDarkMode;
  }

  private get dotColor(): string {
    if (this.color) {
      return this.color;
    }
    // 自动选择颜色
    return this.isDark ? ColorTokens.PRIMARY_DARK : ColorTokens.PRIMARY_LIGHT;
  }

  build() {
    Circle({ width: this.size, height: this.size })
      .fill(this.dotColor)
      .opacity(this.opacity)
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
