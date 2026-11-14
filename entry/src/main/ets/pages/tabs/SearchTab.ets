import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum, FontScale, Spacing, EmptyState } from '@neushare/common';
import { SearchBar } from '../../components/SearchBar';

@Component
export struct SearchTab {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State appearOpacity: number = 0;

  aboutToAppear(): void {
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  private maxContentWidth(): number {
    return new BpType<number>({ sm: 9999, md: 576, lg: 656, xl: 900 }).getValue(this.currentBreakpoint) ?? 9999;
  }

  build() {
    Column() {
      Column() {
        SearchBar({
          placeholder: '搜索资源、标签、作者...',
          onSearch: (keyword: string) => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: keyword } }); }
        }).margin({ top: Spacing.SM, left: Spacing.PAGE, right: Spacing.PAGE })

        Column() {
          EmptyState({
            icon: '',
            message: '输入关键词搜索',
            hint: '支持搜索标题、标签、描述、作者'
          })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }
      .constraintSize({ maxWidth: this.maxContentWidth() })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').layoutWeight(1)
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }
}
