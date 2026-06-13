import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
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
      sm: this.isDarkMode ? 220 : 180,
      md: this.isDarkMode ? 240 : 200,
      lg: this.isDarkMode ? 400 : 320,
      xl: this.isDarkMode ? 440 : 360
    }).getValue(this.currentBreakpoint) ?? 180;
    return base;
  }

  /** 标题字号 */
  private bannerFontSize(): number {
    return new BpType<number>({ 
      sm: 18, 
      md: 18, 
      lg: 28,  // 电脑端大字号
      xl: 32 
    }).getValue(this.currentBreakpoint) ?? 18;
  }

  /** 副标题字号 */
  private bannerSubtitleFontSize(): number {
    return new BpType<number>({ 
      sm: 13, 
      md: 13, 
      lg: 16, 
      xl: 18 
    }).getValue(this.currentBreakpoint) ?? 13;
  }

  /** Emoji装饰大小 */
  private bannerEmojiSize(): number {
    return new BpType<number>({ 
      sm: 48, 
      md: 52, 
      lg: 80,  // 电脑端大装饰
      xl: 90 
    }).getValue(this.currentBreakpoint) ?? 48;
  }

  /** 圆角大小 */
  private bannerBorderRadius(): number {
    return new BpType<number>({ 
      sm: 16, 
      md: 18, 
      lg: 24, 
      xl: 28 
    }).getValue(this.currentBreakpoint) ?? 16;
  }

  /** 内容区域内边距 */
  private contentPadding(): number {
    return new BpType<number>({ 
      sm: 20, 
      md: 24, 
      lg: 48,  // 电脑端更宽松
      xl: 56 
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
          .color(this.isDarkMode ? '#30FFFFFF' : (this.isDesktop() ? '#60FFFFFF' : '#40FFFFFF'))
          .selectedColor(this.isDarkMode ? '#FFFFFF' : ColorTokens.primary(this.isDarkMode))
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
      left: this.isDesktop() ? 24 : 0, 
      right: this.isDesktop() ? 24 : 0 
    })
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
              .backgroundColor('#60000000')
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
                .fill('#FFFFFF')
                .opacity(dot.opacity)
                .position({ x: dot.x + '%', y: dot.y + '%' })
            }, (dot: StarDot, i: number) => `${index}-${i}`)

            // 底部微光渐变
            Column()
              .width('100%').height('40%')
              .linearGradient({
                direction: GradientDirection.Bottom,
                colors: [['#00000000', 0], ['#0AFFFFFF', 1]]
              })
              .position({ x: 0, y: '60%' })
          } else if (this.isDesktop()) {
            // ── 亮色模式电脑端：添加装饰性渐变遮罩 ──
            Column()
              .width('100%')
              .height('100%')
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [['#00000000', 0], ['#20000000', 0.5], ['#40000000', 1]]
              })

            // 装饰性圆形光晕
            Column()
              .width(200)
              .height(200)
              .borderRadius(100)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [['#30FFFFFF', 0], ['#00FFFFFF', 1]]
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
                if (this.isDarkMode) {
                  Circle({ width: 6, height: 6 }).fill('#FFFFFF').opacity(0.8)
                } else {
                  Text('🔥')
                    .fontSize(this.isDesktop() ? 14 : 12)
                }
                Text('热门帖子')
                  .fontSize(this.isDesktop() ? 13 : 11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDarkMode ? '#FFFFFF' : ColorTokens.GOLD)
                  .margin({ left: 4 })
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.isDarkMode ? '#15FFFFFF' : '#FFFFFF25')
              .borderRadius(12)
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
                color: '#90000000', 
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
                  color: '#70000000', 
                  offsetX: 0, 
                  offsetY: 1 
                })
            }

            // 电脑端：添加查看详情按钮
            if (this.isDesktop()) {
              Row() {
                Text('查看详情')
                  .fontSize(14)
                  .fontColor(ColorTokens.TEXT_WHITE)
                Text(' →')
                  .fontSize(14)
                  .fontColor(ColorTokens.TEXT_WHITE)
              }
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(this.isDarkMode ? '#20FFFFFF' : '#FFFFFF30')
              .borderRadius(20)
              .margin({ top: 20 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧：Emoji装饰
          if (!this.isDesktop()) {
            // 手机/平板：右侧Emoji或白色圆点
            if (this.isDarkMode) {
              Circle({ width: 40, height: 40 })
                .fill('#FFFFFF')
                .opacity(0.12)
                .margin({ right: 16 })
            } else {
              Text(item.emoji)
                .fontSize(this.bannerEmojiSize())
                .margin({ right: 16 })
            }
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 电脑端：Emoji或白色圆点放在底部右侧作为装饰
        if (this.isDesktop()) {
          Blank()

          Row() {
            Blank()
            if (this.isDarkMode) {
              Circle({ width: 60, height: 60 })
                .fill('#FFFFFF')
                .opacity(0.08)
                .margin({ right: this.contentPadding(), bottom: 20 })
            } else {
              Text(item.emoji)
                .fontSize(this.bannerEmojiSize())
                .opacity(0.9)
                .margin({ right: this.contentPadding(), bottom: 20 })
            }
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
      color: this.isDarkMode ? '#00000000' : (this.isDesktop() ? '#20000000' : ColorTokens.SHADOW_MEDIUM),
      offsetX: 0,
      offsetY: this.isDesktop() ? 8 : 4
    })
    .scale({ x: 1, y: 1 })
    .animation({ curve: Curve.FastOutSlowIn, duration: 200 })
  }
}
