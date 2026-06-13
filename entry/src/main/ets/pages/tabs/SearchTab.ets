import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { SearchBar } from '../../components/SearchBar';

@Component
export struct SearchTab {
  build() {
    Column() {
      SearchBar({
        placeholder: '搜索资源、标签、作者...',
        onSearch: (keyword: string) => { router.pushUrl({ url: 'pages/SearchPage', params: { keyword: keyword } }); }
      }).margin({ top: 8, left: 16, right: 16 })

      Column() {
        Text('🔍').fontSize(48).margin({ top: 80 })
        Text('输入关键词搜索').fontSize(16).fontColor(ColorTokens.TEXT_HINT).margin({ top: 12 })
        Text('支持搜索标题、标签、描述、作者').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 4 })
      }
      .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').layoutWeight(1)
  }
}
