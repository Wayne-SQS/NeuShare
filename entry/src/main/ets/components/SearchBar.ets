import { ColorTokens } from '@neushare/common';

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索学习资源...';
  @State inputValue: string = '';
  @State focused: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSearch: (keyword: string) => void = () => {};

  build() {
    Row() {
      Text('🔍').fontSize(17).margin({ left: 16 })

      TextInput({ placeholder: this.placeholder, text: this.inputValue })
        .fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1).height(52)
        .backgroundColor(Color.Transparent).borderRadius(0)
        .onSubmit(() => { this.onSearch(this.inputValue); })
        .onChange((value: string) => { this.inputValue = value; })
        .onFocus(() => { this.focused = true; })
        .onBlur(() => { this.focused = false; })

      if (this.inputValue.length > 0) {
        Text('✕')
          .fontSize(14).fontColor(ColorTokens.textHint(this.isDarkMode))
          .margin({ right: 14 })
          .onClick(() => { this.inputValue = ''; this.onSearch(''); })
      }
    }
    .width('100%').height(52)
    .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
    .borderRadius(26)
    .border({ width: this.focused ? 1.5 : 0, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '30'), radius: 26 })
    .shadow({ radius: this.focused ? 8 : 3, color: this.focused ? '#12000000' : '#06000000', offsetX: 0, offsetY: 1 })
    .animation({ curve: Curve.EaseOut, duration: 150 })
  }
}
