import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';
import { SearchBar } from '../../components/SearchBar';

@Component
export struct SearchTab {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;

  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 640, lg: 780, xl: 920 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  private contentPadding(): number {
    return new BpType<number>({ sm: 24, md: 28, lg: 32, xl: 36 }).getValue(this.currentBreakpoint) ?? 24;
  }

  private hintIconSize(): number {
    return new BpType<number>({ sm: 48, md: 56, lg: 68, xl: 80 }).getValue(this.currentBreakpoint) ?? 48;
  }

  private hintTitleSize(): number {
    return new BpType<number>({ sm: 16, md: 18, lg: 22, xl: 26 }).getValue(this.currentBreakpoint) ?? 16;
  }

  private hintDescSize(): number {
    return new BpType<number>({ sm: 13, md: 14, lg: 16, xl: 18 }).getValue(this.currentBreakpoint) ?? 13;
  }

  build() {
    Column() {
      Column() {
        SearchBar({
          placeholder: '搜索资源、标签、作者...',
          onSearch: (keyword: string) => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: keyword } }); }
        }).margin({ top: 8, left: this.contentPadding(), right: this.contentPadding() })

        Column() {
          Text('🔍').fontSize(this.hintIconSize())
          Text('输入关键词搜索').fontSize(this.hintTitleSize()).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 12 })
          Text('支持搜索标题、标签、描述、作者').fontSize(this.hintDescSize()).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }
      .constraintSize({ maxWidth: this.maxContentWidth() })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%').layoutWeight(1)
  }
}
