import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils, BreakpointTypeEnum } from '@neushare/common';
import { ResourceItem } from '../models/ResourceModel';

@Component
export struct ResourceCard {
  @Prop resource: ResourceItem;
  @Prop isFavorite: boolean = false;
  @State pressed: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  onTap: () => void = () => {};

  private isWide(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.LG ||
           this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  private cardPadding(): Padding | number {
    return this.isWide() ? 16 : 14;
  }

  private titleFontSize(): number {
    return this.isWide() ? 16 : 15;
  }

  private descFontSize(): number {
    return this.isWide() ? 12 : 11;
  }

  private iconSize(): number {
    return this.isWide() ? 42 : 36;
  }

  private iconContainerHeight(): number {
    return this.isWide() ? 120 : 100;
  }

  build() {
    if (this.isWide()) {
      // ─── 桌面端：纵向卡片，适合多列网格 ───
      Column() {
        // 顶部：类型图标区
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%').height(this.iconContainerHeight())
            .borderRadius({ topLeft: 16, topRight: 16 })
            .backgroundColor(this.isDarkMode ? '#18FFFFFF' : ColorTokens.withAlpha(ResourceTypeUtils.typeColor(this.resource.type), '18'))
          Text(ResourceTypeUtils.typeEmoji(this.resource.type))
            .fontSize(this.iconSize())
        }
        .width('100%')

        // 底部：信息区
        Column() {
          Text(this.resource.title)
            .fontSize(this.titleFontSize()).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.resource.description)
            .fontSize(this.descFontSize()).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(this.isWide() ? 18 : 16).margin({ top: 4 })

          Row() {
            if (this.resource.tags && this.resource.tags.length > 0) {
              ForEach(this.resource.tags.slice(0, 2), (tag: string) => {
                Text(tag)
                  .fontSize(9).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  .borderRadius(4).margin({ right: 4 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              })
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('👍' + this.resource.likeCount.toString())
                  .fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
              }
              Text(' ★ ' + (this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无'))
                .fontSize(this.resource.rating > 0 ? 11 : 9)
                .fontColor(this.resource.rating > 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .width('100%').padding(this.cardPadding())
      }
      .width('100%')
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
      .borderRadius(16)
      .shadow({ radius: 8, color: ColorTokens.SHADOW_MEDIUM, offsetX: 0, offsetY: 2 })
      .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 16 })
      .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
      .animation({ curve: Curve.FastOutSlowIn, duration: 150 })
      .onClick(() => { this.onTap(); })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
    } else {
      // ─── 手机/平板：横向卡片，适合全宽列表 ───
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(this.isWide() ? 60 : 52).height(this.isWide() ? 80 : 68).borderRadius(14)
            .backgroundColor(this.isDarkMode ? '#18FFFFFF' : ColorTokens.withAlpha(ResourceTypeUtils.typeColor(this.resource.type), '18'))
          Text(ResourceTypeUtils.typeEmoji(this.resource.type))
            .fontSize(this.isWide() ? 30 : 26)
        }

        Column() {
          Text(this.resource.title)
            .fontSize(this.isWide() ? 17 : 16).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.resource.description)
            .fontSize(this.isWide() ? 13 : 12).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(this.isWide() ? 19 : 17).margin({ top: 4 })

          Row() {
            if (this.resource.tags && this.resource.tags.length > 0) {
              ForEach(this.resource.tags.slice(0, 3), (tag: string) => {
                Text(tag)
                  .fontSize(10).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                  .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  .borderRadius(6).margin({ right: 6 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              })
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('👍').fontSize(11)
                Text(this.resource.likeCount.toString()).fontSize(11)
                  .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 2, right: 8 })
              }
              Text('★').fontSize(13).fontColor(ColorTokens.primary(this.isDarkMode))
              Text(this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无')
                .fontSize(this.resource.rating > 0 ? 13 : 10).fontWeight(this.resource.rating > 0 ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.resource.rating > 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode)).margin({ left: 2 })
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .layoutWeight(1).margin({ left: 14 })
      }
      .width('100%').padding(this.cardPadding())
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
      .borderRadius(16)
      .margin({ left: 4, right: 4, top: 4, bottom: 4 })
      .shadow({ radius: 8, color: ColorTokens.SHADOW_MEDIUM, offsetX: 0, offsetY: 2 })
      .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 16 })
      .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
      .animation({ curve: Curve.FastOutSlowIn, duration: 150 })
      .onClick(() => { this.onTap(); })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false;
        }
      })
    }
  }
}
