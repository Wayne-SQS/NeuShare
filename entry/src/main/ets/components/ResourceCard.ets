import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils, BreakpointTypeEnum, FontScale, Radii, Spacing, Elevation } from '@neushare/common';
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
    return this.isWide() ? Spacing.CARD : Spacing.LG;
  }

  private titleFontSize(): number {
    return this.isWide() ? FontScale.SUBTITLE : FontScale.BODY;
  }

  private descFontSize(): number {
    return this.isWide() ? FontScale.LABEL : FontScale.MICRO;
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
            .borderRadius({ topLeft: Radii.CARD, topRight: Radii.CARD })
            .backgroundColor(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '18') : ColorTokens.withAlpha(ResourceTypeUtils.typeColor(this.resource.type), '18'))
          Text(ColorTokens.typeAbbreviation(this.resource.type))
            .fontSize(FontScale.CAPTION)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1)
            .fontColor(ResourceTypeUtils.typeColor(this.resource.type))
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
              ForEach(this.resource.tags.slice(0, 2), (tag: string, idx: number) => {
                Text(tag)
                  .fontSize(FontScale.MICRO_SM).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  .borderRadius(Radii.XS).margin({ right: 4 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              }, (tag: string, idx: number) => 'tag_' + idx.toString())
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('赞' + this.resource.likeCount.toString())
                  .fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode))
              }
              Text('评分 ' + (this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无'))
                .fontSize(this.resource.rating > 0 ? FontScale.MICRO : FontScale.MICRO_SM)
                .fontColor(this.resource.rating > 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .width('100%').padding(this.cardPadding())
      }
      .width('100%')
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
      .borderRadius(Radii.CARD)
      .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
      .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
      .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
      .animation({ curve: Curve.EaseOut, duration: 200 })
      .hoverEffect(HoverEffect.Auto)
      .transition(TransitionEffect.OPACITY.animation({ curve: Curve.EaseOut, duration: 300 }))
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
            .width(this.isWide() ? 60 : 52).height(this.isWide() ? 80 : 68).borderRadius(Radii.XL)
            .backgroundColor(this.isDarkMode ? ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, '18') : ColorTokens.withAlpha(ResourceTypeUtils.typeColor(this.resource.type), '18'))
          Text(ColorTokens.typeAbbreviation(this.resource.type))
            .fontSize(FontScale.LABEL)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1)
            .fontColor(ResourceTypeUtils.typeColor(this.resource.type))
        }

        Column() {
          Text(this.resource.title)
            .fontSize(this.isWide() ? FontScale.SUBTITLE_MD : FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary(this.isDarkMode))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.resource.description)
            .fontSize(this.isWide() ? FontScale.CAPTION : FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(this.isWide() ? 19 : 17).margin({ top: 4 })

          Row() {
            if (this.resource.tags && this.resource.tags.length > 0) {
              ForEach(this.resource.tags.slice(0, 3), (tag: string, idx: number) => {
                Text(tag)
                  .fontSize(FontScale.TINY).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                  .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  .borderRadius(Radii.SM).margin({ right: 6 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              }, (tag: string, idx: number) => 'tag_' + idx.toString())
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('赞').fontSize(FontScale.MICRO)
                Text(this.resource.likeCount.toString()).fontSize(FontScale.MICRO)
                  .fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ left: 2, right: 8 })
              }
              Text('评分').fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode))
              Text(this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无')
                .fontSize(this.resource.rating > 0 ? FontScale.CAPTION : FontScale.TINY).fontWeight(this.resource.rating > 0 ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.resource.rating > 0 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode)).margin({ left: 2 })
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .layoutWeight(1).margin({ left: 14 })
      }
      .width('100%').padding(this.cardPadding())
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
      .borderRadius(Radii.CARD)
      .margin({ left: 4, right: 4, top: 4, bottom: 4 })
      .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
      .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
      .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
      .animation({ curve: Curve.EaseOut, duration: 200 })
      .hoverEffect(HoverEffect.Auto)
      .transition(TransitionEffect.OPACITY.animation({ curve: Curve.EaseOut, duration: 300 }))
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
