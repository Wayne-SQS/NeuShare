// ============================================================
// GlassCard — 毛玻璃卡片组件
// 亮色模式：多彩玻璃质感 / 深色模式：极简黑白
// ============================================================

import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct GlassCard {
  // ── 主题状态 ────────────────────────────────
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  // ── 可配置属性 ──────────────────────────────
  @Prop padding: Padding = { left: 16, right: 16, top: 16, bottom: 16 };
  @Prop margin: Margin = { left: 0, right: 0, top: 0, bottom: 12 };
  @Prop width: string | number = '100%';
  @Prop height: string | number | undefined = undefined;
  @Prop blurRadius: number = 40; // 毛玻璃模糊半径
  @Prop showDot: boolean = false; // 是否显示装饰小圆点
  @Prop dotColor: string = ''; // 小圆点颜色（空则使用主色）
  @Prop dotSize: number = 10; // 小圆点尺寸

  // ── 计算属性 ────────────────────────────────
  private get isDark(): boolean {
    return this.isDarkMode;
  }

  private get bgColor(): string {
    return this.isDark ? ColorTokens.BG_CARD_DARK : ColorTokens.BG_CARD_LIGHT;
  }

  private get borderColor(): string {
    return this.isDark ? ColorTokens.DIVIDER_DARK : '#FFFFFF80';
  }

  private get shadowColor(): string {
    return this.isDark ? '#00000040' : '#4A6BFF15';
  }

  private get cardRadius(): number {
    return ColorTokens.cardRadius(this.isDark);
  }

  private get dotColorValue(): string {
    if (this.dotColor) {
      return this.dotColor;
    }
    return this.isDark ? ColorTokens.PRIMARY_DARK : ColorTokens.PRIMARY_LIGHT;
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // ── 主卡片内容 ──────────────────────────
      Column() {
        // 子组件通过 this.$slots.default() 插入
      }
      .width(this.width)
      .height(this.height)
      .padding(this.padding)
      .margin(this.margin)
      .backgroundColor(this.bgColor)
      .backdropBlur(this.blurRadius)
      .borderRadius(this.cardRadius)
      .border({ width: 1, color: this.borderColor })
      .shadow({
        radius: 24,
        color: this.shadowColor,
        offsetX: 0,
        offsetY: 6
      })

      // ── 装饰小圆点（可选） ──────────────────
      if (this.showDot) {
        Circle({ width: this.dotSize, height: this.dotSize })
          .fill(this.dotColorValue)
          .opacity(0.8)
          .margin({ top: 12, right: 12 })
      }
    }
    .width(this.width)
  }
}

// ============================================================
// 使用示例
// ============================================================

/*
// 基础用法
GlassCard() {
  Column() {
    Text('标题')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(ColorTokens.textPrimary(this.isDark))

    Text('描述内容')
      .fontSize(14)
      .fontColor(ColorTokens.textSecondary(this.isDark))
      .margin({ top: 8 })
  }
  .width('100%')
}

// 带装饰圆点
GlassCard({
  showDot: true,
  dotColor: ColorTokens.ACCENT_PINK_LIGHT,
  dotSize: 12
}) {
  // 内容
}

// 自定义模糊度和内边距
GlassCard({
  blurRadius: 60,
  padding: { left: 20, right: 20, top: 24, bottom: 24 }
}) {
  // 内容
}

// 列表中的卡片
ForEach(this.resourceList, (item: ResourceItem) => {
  GlassCard({
    showDot: true,
    dotColor: ColorTokens.typeColor(item.type, this.isDark)
  }) {
    ResourceCard({ resource: item })
  }
})
*/
