// ============================================================
// Skeleton - 骨架屏组件
// 通用加载占位组件，配合条件渲染在数据加载时展示
// ============================================================
import { ColorTokens } from '../theme/ColorTokens';

@Component
export struct Skeleton {
  @Prop skWidth: number = 60;
  @Prop skHeight: number = 14;
  @Prop skRadius: number = 4;
  @Prop skMargin: Margin = {};

  build() {
    Row()
      .width(this.skWidth)
      .height(this.skHeight)
      .borderRadius(this.skRadius)
      .backgroundColor(ColorTokens.BG_INPUT)
      .margin(this.skMargin)
  }
}

@Component
export struct ResourceSkeleton {
  build() {
    Row() {
      Skeleton({ skWidth: 60, skHeight: 80, skRadius: 8 })
      Column() {
        Skeleton({ skWidth: 120, skHeight: 15, skRadius: 4, skMargin: { bottom: 8 } })
        Skeleton({ skWidth: 80, skHeight: 12, skRadius: 4, skMargin: { bottom: 6 } })
        Row() {
          Skeleton({ skWidth: 40, skHeight: 10, skRadius: 3, skMargin: { right: 6 } })
          Skeleton({ skWidth: 40, skHeight: 10, skRadius: 3, skMargin: { right: 6 } })
          Skeleton({ skWidth: 40, skHeight: 10, skRadius: 3 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(ColorTokens.BG_CARD)
    .borderRadius(10)
    .margin({ left: 16, right: 16, top: 6, bottom: 6 })
  }
}
