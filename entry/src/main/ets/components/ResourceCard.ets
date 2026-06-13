import router from '@ohos.router';
import { ColorTokens, ResourceTypeUtils, BreakpointTypeEnum } from '@neushare/common';
import { ResourceItem } from '../models/ResourceModel';

@Component
export struct ResourceCard {
  @Prop resource: ResourceItem;
  @Prop isFavorite: boolean = false;
  @State pressed: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  onTap: () => void = () => {};

  private isWide(): boolean {
    return this.currentBreakpoint === BreakpointTypeEnum.LG ||
           this.currentBreakpoint === BreakpointTypeEnum.XL;
  }

  build() {
    if (this.isWide()) {
      // ─── 桌面端：纵向卡片，适合多列网格 ───
      Column() {
        // 顶部：类型图标区
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%').height(100)
            .borderRadius({ topLeft: 16, topRight: 16 })
            .backgroundColor(ResourceTypeUtils.typeColor(this.resource.type) + '18')
          Text(ResourceTypeUtils.typeEmoji(this.resource.type))
            .fontSize(36)
        }
        .width('100%')

        // 底部：信息区
        Column() {
          Text(this.resource.title)
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.TEXT_PRIMARY)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.resource.description)
            .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(16).margin({ top: 4 })

          Row() {
            if (this.resource.tags && this.resource.tags.length > 0) {
              ForEach(this.resource.tags.slice(0, 2), (tag: string) => {
                Text(tag)
                  .fontSize(9).fontColor(ColorTokens.PRIMARY)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                  .borderRadius(4).margin({ right: 4 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              })
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('👍' + this.resource.likeCount.toString())
                  .fontSize(10).fontColor(ColorTokens.TEXT_HINT)
              }
              Text(' ★ ' + (this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无'))
                .fontSize(this.resource.rating > 0 ? 11 : 9)
                .fontColor(this.resource.rating > 0 ? ColorTokens.ACCENT : ColorTokens.TEXT_HINT)
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .width('100%').padding(14)
      }
      .width('100%')
      .backgroundColor('#FCFCFC')
      .borderRadius(16)
      .shadow({ radius: 8, color: '#12000000', offsetX: 0, offsetY: 2 })
      .border({ width: 1, color: '#0A000000', radius: 16 })
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
            .width(52).height(68).borderRadius(14)
            .backgroundColor(ResourceTypeUtils.typeColor(this.resource.type) + '18')
          Text(ResourceTypeUtils.typeEmoji(this.resource.type))
            .fontSize(26)
        }

        Column() {
          Text(this.resource.title)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.TEXT_PRIMARY)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.resource.description)
            .fontSize(12).fontColor(ColorTokens.TEXT_HINT)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(17).margin({ top: 4 })

          Row() {
            if (this.resource.tags && this.resource.tags.length > 0) {
              ForEach(this.resource.tags.slice(0, 3), (tag: string) => {
                Text(tag)
                  .fontSize(10).fontColor(ColorTokens.PRIMARY)
                  .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                  .borderRadius(6).margin({ right: 6 })
                  .onClick(() => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: tag } }); })
              })
            }
            Blank()
            Row() {
              if (this.resource.likeCount > 0) {
                Text('👍').fontSize(11)
                Text(this.resource.likeCount.toString()).fontSize(11)
                  .fontColor(ColorTokens.TEXT_HINT).margin({ left: 2, right: 8 })
              }
              Text('★').fontSize(13).fontColor(ColorTokens.ACCENT)
              Text(this.resource.rating > 0 ? this.resource.rating.toFixed(1) : '暂无')
                .fontSize(this.resource.rating > 0 ? 13 : 10).fontWeight(this.resource.rating > 0 ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.resource.rating > 0 ? ColorTokens.ACCENT : ColorTokens.TEXT_HINT).margin({ left: 2 })
            }
          }
          .width('100%').margin({ top: 8 })
        }
        .layoutWeight(1).margin({ left: 14 })
      }
      .width('100%').padding(14)
      .backgroundColor('#FCFCFC')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 6, bottom: 6 })
      .shadow({ radius: 8, color: '#12000000', offsetX: 0, offsetY: 2 })
      .border({ width: 1, color: '#0A000000', radius: 16 })
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
