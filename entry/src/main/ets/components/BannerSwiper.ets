import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, BreakpointSystem, FontScale, Radii, Spacing } from '@neushare/common';
import { BannerItem } from '../models/ResourceModel';

// 星空点数据
interface StarDot {
  size: number;
  opacity: number;
  x: number;
  y: number;
}

/**
 * BannerSwiper - 响应式轮播图组件
 * 
 * 设计理念：
 * - 手机端：紧凑的单图轮播，高度180px
 * - 平板端：双图并排轮播，高度200px
 * - 电脑端：大尺寸单图轮播，高度320px，带渐变遮罩和装饰元素
 */
@Component
export struct BannerSwiper {
  @Prop banners: BannerItem[] = [];
  @State currentIndex: number = 0;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  onBannerTap: (item: BannerItem) => void = () => {};
  private swiperController: SwiperController = new SwiperController();
  private timer: number = -1;

  aboutToAppear(): void {
    if (this.banners.length > 1) {
      this.timer = setInterval(() => {
        this.swiperController.showNext();
      }, 4000);
    }
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  // ── 响应式参数 ─────────────────────────────────────────

  /** 显示数量：手机1个，平板2个，电脑1个大图 */
  private displayCount(): number {
    return new BpType<number>({ 
      sm: 1, 
      md: 2, 
      lg: 1,  // 电脑端显示单个大图
      xl: 1 
    }).getValue(this.currentBreakpoint) ?? 1;
  }

  /** 轮播间距 */
  private nextMarginValue(): Length {
    return new BpType<Length>({ 
      sm: 0, 
      md: 16, 
      lg: 0, 
      xl: 0 
    }).getValue(this.currentBreakpoint) ?? 0;
  }

  /** 轮播高度：电脑端显著加高，深色模式更高 */
  private bannerHeight(): number {
    const base = new BpType<number>({
      sm: this.isDarkMode ? 260 : 220,
      md: this.isDarkMode ? 280 : 240,
      lg: this.isDarkMode ? 480 : 420,
      xl: this.isDarkMode ? 560 : 480
    }).getValue(this.currentBreakpoint) ?? 220;
    // 首屏 hero 不超过屏幕高度的 1/3，避免挤占下方内容
    return Math.min(base, BreakpointSystem.heroMaxHeight(base));
  }

  /** 标题字号 */
  private bannerFontSize(): number {
    return new BpType<number>({
      sm: FontScale.SECTION,
      md: FontScale.SECTION,
      lg: FontScale.HERO_LG,  // 电脑端大字号
      xl: FontScale.BRAND
    }).getValue(this.currentBreakpoint) ?? 18;
  }

  /** 副标题字号 */
  private bannerSubtitleFontSize(): number {
    return new BpType<number>({
      sm: FontScale.CAPTION,
      md: FontScale.CAPTION,
      lg: FontScale.SUBTITLE,
      xl: FontScale.TITLE_SM
    }).getValue(this.currentBreakpoint) ?? 13;
  }

  /** 圆角大小 */
  private bannerBorderRadius(): number {
    return 0;
  }

  /** 内容区域内边距 */
  private contentPadding(): number {
    return new BpType<number>({
      sm: 20,
      md: 24,
      lg: 48,  // 电脑端更宽松
      xl: 64
    }).getValue(this.currentBreakpoint) ?? 20;
  }

  /** 判断是否为小屏幕 */
  private isSmallScreen(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.SM || 
           this.currentBreakpoint === BreakpointTypeEnum.XS;
  }

  /** 判断是否为电脑端 */
  private isDesktop(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.LG || 
           this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  /** 判断是否为帖子类型Banner */
  isPostBanner(item: BannerItem): boolean {
    return item.linkType === 'post';
  }

  /** 生成星空点（深色模式Banner装饰） */
  private getStarDots(bannerIndex: number): StarDot[] {
    const dots: StarDot[] = [];
    // 使用 bannerIndex 作为伪随机种子，确保每次渲染一致
    const seed = bannerIndex * 7 + 13;
    const count = 15 + (bannerIndex % 6);
    for (let i = 0; i < count; i++) {
      const v = ((seed * (i + 1) * 31) % 1000) / 1000;
      const v2 = ((seed * (i + 1) * 47) % 1000) / 1000;
      const v3 = ((seed * (i + 1) * 73) % 1000) / 1000;
      dots.push({
        size: 2 + v3 * 6,  // 2~8vp
        opacity: 0.15 + v * 0.55,  // 15%~70%
        x: v * 90 + 5,  // 5%~95%
        y: v2 * 85 + 5   // 5%~90%
      });
    }
    return dots;
  }

  // ── 构建UI ─────────────────────────────────────────────

  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.banners, (item: BannerItem, index: number) => {
          this.BannerItemBuilder(item, index)
        }, (item: BannerItem) => item.id.toString())
      }
      .autoPlay(true)
      .displayCount(this.displayCount())
      .displayMode(SwiperDisplayMode.STRETCH)
      .nextMargin(this.nextMarginValue())
      .indicator(
        Indicator.dot()
          .itemWidth(this.isDesktop() ? 10 : 8)
          .itemHeight(this.isDesktop() ? 10 : 8)
          .selectedItemWidth(this.isDesktop() ? 10 : 8)
          .selectedItemHeight(this.isDesktop() ? 10 : 8)
          .color(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '30') : (this.isDesktop() ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '60') : ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '40')))
          .selectedColor(this.isDarkMode ? ColorTokens.TEXT_WHITE : ColorTokens.primary(this.isDarkMode))
          .bottom(this.isDesktop() ? 20 : 12)
      )
      .loop(true)
      .curve(Curve.FastOutSlowIn)
      .duration(400)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .margin({ top: this.isDesktop() ? 16 : 8 })
    .padding({
      left: 0,
      right: 0
    })
    .transition(TransitionEffect.OPACITY.animation({ curve: Curve.EaseOut, duration: 300 }))
  }

  // ── 单个Banner构建器 ───────────────────────────────────

  @Builder
  BannerItemBuilder(item: BannerItem, index: number) {
    Stack({ alignContent: Alignment.BottomStart }) {
      // ── 背景层 ───────────────────────────────────────
      if (item.imageUrl && item.imageUrl.length > 0) {
        // 网络图片背景
        Stack() {
          Image(item.imageUrl)
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height(this.bannerHeight())
            .borderRadius(this.bannerBorderRadius())
          // 深色模式：叠加暗色遮罩降低亮度
          if (this.isDarkMode) {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor(ColorTokens.OVERLAY)
              .borderRadius(this.bannerBorderRadius())
          }
        }
        .width('100%')
        .height(this.bannerHeight())
        .borderRadius(this.bannerBorderRadius())
        .clip(true)
      } else {
        // 纯色背景（带装饰渐变）
        Stack() {
          // 主背景色
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.isDarkMode
              ? ColorTokens.BG_CARD_DARK
              : (item.gradientStart || ColorTokens.BANNER_COLORS[index % ColorTokens.BANNER_COLORS.length]))

          if (this.isDarkMode) {
            // ── 深色模式：星空点装饰 ──
            ForEach(this.getStarDots(index), (dot: StarDot) => {
              Circle({ width: dot.size, height: dot.size })
                .fill(ColorTokens.TEXT_WHITE)
                .opacity(dot.opacity)
                .position({ x: dot.x + '%', y: dot.y + '%' })
            }, (dot: StarDot, i: number) => `${index}-${i}`)

            // 底部微光渐变
            Column()
              .width('100%').height('40%')
              .linearGradient({
                direction: GradientDirection.Bottom,
                colors: [[ColorTokens.TRANSPARENT, 0], [ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '0A'), 1]]
              })
              .position({ x: 0, y: '60%' })
          } else if (this.isDesktop()) {
            // ── 亮色模式电脑端：添加装饰性渐变遮罩 ──
            Column()
              .width('100%')
              .height('100%')
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [[ColorTokens.TRANSPARENT, 0], [ColorTokens.OVERLAY_LIGHT, 0.5], [ColorTokens.OVERLAY_LIGHT, 1]]
              })

            // 装饰性圆形光晕
            Column()
              .width(200)
              .height(200)
              .borderRadius(Radii.PILL)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [[ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '30'), 0], [ColorTokens.TRANSPARENT, 1]]
              })
              .position({ x: '60%', y: -20 })
              .blur(40)
          }
        }
        .width('100%')
        .height(this.bannerHeight())
        .borderRadius(this.bannerBorderRadius())
      }

      // ── 内容叠加层 ─────────────────────────────────────
      Column() {
        Row() {
          // 左侧：文字内容
          Column() {
            // 帖子标签
            if (this.isPostBanner(item)) {
              Row() {
                Circle({ width: 6, height: 6 }).fill(ColorTokens.TEXT_WHITE).opacity(0.8)
                Text('热门帖子')
                  .fontSize(this.isDesktop() ? FontScale.CAPTION : FontScale.MICRO)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDarkMode ? ColorTokens.TEXT_WHITE : ColorTokens.GOLD)
                  .margin({ left: 4 })
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '15') : ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '25'))
              .borderRadius(Radii.CARD)
              .margin({ bottom: this.isDesktop() ? 16 : 10 })
            }

            // 主标题
            Text(item.title)
              .fontSize(this.bannerFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_WHITE)
              .maxLines(this.isDesktop() ? 2 : 1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textShadow({ 
                radius: this.isDesktop() ? 8 : 4, 
                color: ColorTokens.OVERLAY, 
                offsetX: 0, 
                offsetY: this.isDesktop() ? 3 : 1 
              })

            // 副标题
            if (item.subtitle && item.subtitle.length > 0) {
              Text(item.subtitle)
                .fontSize(this.bannerSubtitleFontSize())
                .fontColor(ColorTokens.TEXT_WHITE)
                .maxLines(this.isDesktop() ? 2 : 1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: this.isDesktop() ? 12 : 6 })
                .opacity(0.9)
                .textShadow({ 
                  radius: this.isDesktop() ? 4 : 2, 
                  color: ColorTokens.OVERLAY, 
                  offsetX: 0, 
                  offsetY: 1 
                })
            }

            // 电脑端：添加查看详情按钮
            if (this.isDesktop()) {
              Row() {
                Text('查看详情')
                  .fontSize(FontScale.BODY_SM)
                  .fontColor(ColorTokens.TEXT_WHITE)
              }
              .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.SM, bottom: Spacing.SM })
              .backgroundColor(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '20') : ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '30'))
              .borderRadius(Radii.HUGE)
              .margin({ top: Spacing.XL })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧：几何装饰（不使用 emoji）
          if (!this.isDesktop()) {
            Circle({ width: 40, height: 40 })
              .fill(ColorTokens.TEXT_WHITE)
              .opacity(this.isDarkMode ? 0.12 : 0.18)
              .margin({ right: Spacing.LG })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 电脑端：几何装饰放在底部右侧
        if (this.isDesktop()) {
          Blank()

          Row() {
            Blank()
            Circle({ width: 60, height: 60 })
              .fill(ColorTokens.TEXT_WHITE)
              .opacity(this.isDarkMode ? 0.08 : 0.14)
              .margin({ right: this.contentPadding(), bottom: Spacing.XL })
          }
          .width('100%')
        }
      }
      .width('100%')
      .height(this.bannerHeight())
      .padding({ 
        left: this.contentPadding(), 
        right: this.contentPadding(),
        top: this.isDesktop() ? 40 : 20,
        bottom: this.isDesktop() ? 20 : 0
      })
      .justifyContent(this.isDesktop() ? FlexAlign.Start : FlexAlign.Center)
    }
    .width('100%')
    .height(this.bannerHeight())
    .borderRadius(this.bannerBorderRadius())
    .clip(true)
    .onClick(() => {
      this.onBannerTap(item);
    })
    .shadow({
      radius: this.isDesktop() ? 20 : 12,
      color: this.isDarkMode ? ColorTokens.TRANSPARENT : (this.isDesktop() ? ColorTokens.OVERLAY_LIGHT : ColorTokens.SHADOW_MEDIUM),
      offsetX: 0,
      offsetY: this.isDesktop() ? 8 : 4
    })
    .scale({ x: 1, y: 1 })
    .animation({ curve: Curve.EaseOut, duration: 200 })
  }
}
