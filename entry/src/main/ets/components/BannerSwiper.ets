import { ColorTokens } from '@neushare/common';
import { BannerItem } from '../models/ResourceModel';

@Component
export struct BannerSwiper {
  @Prop banners: BannerItem[] = [];
  @State currentIndex: number = 0;
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

  makeDotIndices(): number[] {
    const indices: number[] = [];
    for (let i = 0; i < this.banners.length; i++) {
      indices.push(i);
    }
    return indices;
  }

  isPostBanner(item: BannerItem): boolean {
    return item.linkType === 'post';
  }

  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.banners, (item: BannerItem, index: number) => {
          Stack() {
            // Gradient background
            Row()
              .width('100%')
              .height(180)
              .borderRadius(20)
              .linearGradient({
                angle: 135,
                colors: [
                  [item.gradientStart || ColorTokens.BANNER_GRADIENT_START[index % ColorTokens.BANNER_GRADIENT_START.length], 0.0],
                  [item.gradientEnd || ColorTokens.BANNER_GRADIENT_END[index % ColorTokens.BANNER_GRADIENT_END.length], 1.0]
                ]
              })

            // Content overlay
            Row() {
              Column() {
                // Post badge
                if (this.isPostBanner(item)) {
                  Text('🔥 热门帖子 #' + (index - 4 + 1).toString())
                    .fontSize(11).fontWeight(FontWeight.Bold)
                    .fontColor('#FFD700')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .backgroundColor('#FFFFFF20')
                    .borderRadius(8).margin({ bottom: 8 })
                }

                Text(item.title)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.TEXT_WHITE)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(item.subtitle)
                  .fontSize(13)
                  .fontColor('#D0D8E8')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
                  .opacity(0.85)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding({ left: 24 })

              // Right: emoji
              Text(item.emoji)
                .fontSize(64)
                .margin({ right: 20 })
            }
            .width('100%')
            .height(180)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .margin({ left: 16, right: 16 })
          .onClick(() => {
            this.onBannerTap(item);
          })
          .shadow({ radius: 12, color: '#20000000', offsetX: 0, offsetY: 4 })
        }, (item: BannerItem) => item.id.toString())
      }
      .autoPlay(false)
      .indicator(false)
      .loop(true)
      .borderRadius(20)
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // Dot indicators
      if (this.banners.length > 1) {
        Row() {
          ForEach(this.makeDotIndices(), (dotIndex: number) => {
            if (dotIndex === this.currentIndex) {
              Row()
                .width(24).height(4).borderRadius(2)
                .backgroundColor('#FFFFFF')
                .margin({ left: 3, right: 3 })
            } else {
              Row()
                .width(6).height(6).borderRadius(3)
                .backgroundColor('#40FFFFFF')
                .margin({ left: 3, right: 3 })
            }
          })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .position({ x: 0, y: 160 })
      }
    }
    .width('100%')
    .margin({ top: 6 })
  }
}
