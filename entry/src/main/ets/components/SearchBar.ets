import { ColorTokens, FontScale, Radii, Spacing, ControlSize } from '@neushare/common';

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索学习资源...';
  @State inputValue: string = '';
  @State focused: boolean = false;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  onSearch: (keyword: string) => void = () => {};

  build() {
    Row() {
      TextInput({ placeholder: this.placeholder, text: this.inputValue })
        .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Medium).layoutWeight(1).height(ControlSize.BUTTON_LG)
        .backgroundColor(Color.Transparent).borderRadius(Radii.NONE)
        .padding({ left: Spacing.LG, right: Spacing.LG })
        .onSubmit(() => { this.onSearch(this.inputValue); })
        .onChange((value: string) => { this.inputValue = value; })
        .onFocus(() => { this.focused = true; })
        .onBlur(() => { this.focused = false; })

      if (this.inputValue.length > 0) {
        Text('清除')
          .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textHint(this.isDarkMode))
          .margin({ right: Spacing.MD })
          .onClick(() => { this.inputValue = ''; this.onSearch(''); })
      }
    }
    .width('100%').height(ControlSize.BUTTON_LG)
    .backgroundColor(ColorTokens.bgInput(this.isDarkMode))
    .borderRadius(Radii.PILL)
    .border({ width: this.focused ? 1 : 0, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '30'), radius: Radii.PILL })
    .shadow({ radius: this.focused ? 8 : 3, color: this.focused ? ColorTokens.SHADOW_CARD_LIGHT : ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
    .animation({ curve: Curve.EaseOut, duration: 150 })
  }
}
