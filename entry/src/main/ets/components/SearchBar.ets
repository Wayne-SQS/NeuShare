import { ColorTokens } from '@neushare/common';

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索学习资源...';
  @State inputValue: string = '';
  @State focused: boolean = false;
  onSearch: (keyword: string) => void = () => {};

  build() {
    Row() {
      Text('🔍').fontSize(15).margin({ left: 16 })

      TextInput({ placeholder: this.placeholder, text: this.inputValue })
        .fontSize(14).layoutWeight(1).height(46)
        .backgroundColor(Color.Transparent).borderRadius(0)
        .onSubmit(() => { this.onSearch(this.inputValue); })
        .onChange((value: string) => { this.inputValue = value; })
        .onFocus(() => { this.focused = true; })
        .onBlur(() => { this.focused = false; })

      if (this.inputValue.length > 0) {
        Text('✕')
          .fontSize(13).fontColor(ColorTokens.TEXT_HINT)
          .margin({ right: 14 })
          .onClick(() => { this.inputValue = ''; this.onSearch(''); })
      }
    }
    .width('100%').height(46)
    .backgroundColor(ColorTokens.BG_INPUT)
    .borderRadius(23)
    .border({ width: this.focused ? 1.5 : 0, color: ColorTokens.PRIMARY + '30', radius: 23 })
    .shadow({ radius: this.focused ? 8 : 3, color: this.focused ? '#12000000' : '#06000000', offsetX: 0, offsetY: 1 })
    .animation({ curve: Curve.EaseOut, duration: 150 })
  }
}
