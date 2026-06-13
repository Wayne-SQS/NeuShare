import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { BannerItem } from '../models/ResourceModel';

@Component
export struct BannerSwiper {
  @Prop banners: BannerItem[] = [];
  @State currentIndex: number = 0;
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

  private displayCount(): number {
    return new BpType<number>({ sm: 1, md: 2, lg: 2, xl: 3 }).getValue(this.currentBreakpoint) ?? 1;
  }

  private nextMarginValue(): Length {
    return new BpType<Length>({ sm: 0, md: 12, lg: 48, xl: 96 }).getValue(this.currentBreakpoint) ?? 0;
  }

  private isSmallScreen(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.SM || this.currentBreakpoint === BreakpointTypeEnum.XS;
  }

  isPostBanner(item: BannerItem): boolean {
    return item.linkType === 'post';
  }

  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.banners, (item: BannerItem, index: number) => {
          Stack() {
            // Banner 图片（如果有 imageUrl 则加载网络图片，否则用渐变背景）
            if (item.imageUrl && item.imageUrl.length > 0) {
              Image(item.imageUrl)
                .objectFit(ImageFit.Cover)
                .width('100%')
                .height(new BpType<number>({ sm: 180, md: 160, lg: 200, xl: 220 }).getValue(this.currentBreakpoint) ?? 180)
                .borderRadius(16)
            } else {
              // 渐变背景兜底
              Row()
                .width('100%')
                .height(new BpType<number>({ sm: 180, md: 160, lg: 200, xl: 220 }).getValue(this.currentBreakpoint) ?? 180)
                .borderRadius(16)
                .backgroundColor(item.gradientStart || ColorTokens.BANNER_COLORS[index % ColorTokens.BANNER_COLORS.length])
            }

            // 内容叠加层
            Row() {
              Column() {
                // 帖子标签
                if (this.isPostBanner(item)) {
                  Text('🔥 热门帖子')
                    .fontSize(11).fontWeight(FontWeight.Bold)
                    .fontColor('#FFD700')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor('#FFFFFF20')
                    .borderRadius(8).margin({ bottom: 8 })
                }

                Text(item.title)
                  .fontSize(new BpType<number>({ sm: 18, md: 16, lg: 20, xl: 22 }).getValue(this.currentBreakpoint) ?? 18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.TEXT_WHITE)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textShadow({ radius: 4, color: '#80000000', offsetX: 0, offsetY: 1 })

                if (item.subtitle && item.subtitle.length > 0) {
                  Text(item.subtitle)
                    .fontSize(new BpType<number>({ sm: 13, md: 12, lg: 14, xl: 14 }).getValue(this.currentBreakpoint) ?? 13)
                    .fontColor('#D0D8E8')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 6 })
                    .opacity(0.85)
                    .textShadow({ radius: 2, color: '#60000000', offsetX: 0, offsetY: 1 })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding({ left: 20 })

              // 右侧 emoji 装饰
              Text(item.emoji)
                .fontSize(new BpType<number>({ sm: 52, md: 44, lg: 60, xl: 64 }).getValue(this.currentBreakpoint) ?? 52)
                .margin({ right: 16 })
            }
            .width('100%')
            .height(new BpType<number>({ sm: 180, md: 160, lg: 200, xl: 220 }).getValue(this.currentBreakpoint) ?? 180)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .onClick(() => {
            this.onBannerTap(item);
          })
          .shadow({ radius: 12, color: '#20000000', offsetX: 0, offsetY: 4 })
        }, (item: BannerItem) => item.id.toString())
      }
      .autoPlay(true)
      .displayCount(this.displayCount())
      .displayMode(SwiperDisplayMode.STRETCH)
      .nextMargin(this.nextMarginValue())
      .indicator(this.isSmallScreen() ?
        Indicator.dot()
          .color('#40FFFFFF')
          .selectedColor(ColorTokens.PRIMARY) :
        false)
      .loop(true)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .margin({ top: 6 })
  }
}
