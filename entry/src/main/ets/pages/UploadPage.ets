import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceApi } from '../api/ResourceApi';
import { ResourceService } from '../services/ResourceService';
import { CategoryItem } from '../models/ResourceModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct UploadPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State title: string = '';
  @State categoryId: number = 0;
  @State type: string = 'tutorial';
  @State description: string = '';
  @State contentUrl: string = '';
  @State coverUrl: string = '';
  @State source: string = '';
  @State isLoading: boolean = false;
  @State btnPressed: boolean = false; // 按钮按压状态（教程 §16.3 生命力原则）
  @State categories: CategoryItem[] = [];
  private resourceApi: ResourceApi = new ResourceApi();
  private resourceService: ResourceService = ResourceService.getInstance();

  private types: string[][] = [
    ['tutorial', '教程'], ['book', '书籍'], ['video', '视频'], ['software', '软件']
  ];

  aboutToAppear(): void {
    this.categories = this.resourceService.getLocalCategories();
  }

  async doUpload(): Promise<void> {
    if (!this.title.trim()) { promptAction.showToast({ message: '请输入标题' }); return; }
    if (this.categoryId === 0) { promptAction.showToast({ message: '请选择分类' }); return; }
    if (!this.contentUrl.trim()) { promptAction.showToast({ message: '请输入资源链接' }); return; }
    this.isLoading = true;
    try {
      const resp = await this.resourceApi.create({
        title: this.title.trim(),
        categoryId: this.categoryId,
        type: this.type,
        description: this.description.trim(),
        contentUrl: this.contentUrl.trim(),
        coverUrl: this.coverUrl.trim(),
        source: this.source.trim()
      });
      if (resp.code === 200) {
        promptAction.showToast({ message: '上传成功，等待审核' });
        setTimeout(() => { router.back(); }, 1500);
      } else {
        promptAction.showToast({ message: resp.message || '上传失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器，请确认后端已启动' });
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('上传资源').fontSize(18).fontWeight(FontWeight.Bolder)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
      }
      .width('100%').height(52).padding({ left: 24 }).backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          Column() {
            Text('标题 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%')
            TextInput({ text: this.title, placeholder: '资源标题' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
              .onChange((value: string) => { this.title = value; })

            Text('分类 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.categories, (cat: CategoryItem) => {
                Text(cat.title)
                  .fontSize(13).fontColor(this.categoryId === cat.id ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textPrimary(this.isDarkMode))
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .backgroundColor(this.categoryId === cat.id ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius(20).margin({ right: 8, top: 8 })
                  .onClick(() => { this.categoryId = cat.id; })
              })
            }.width('100%').margin({ top: 8 })

            Text('类型').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            Row() {
              ForEach(this.types, (item: string[]) => {
                Row() {
                  Text(item[0] === 'tutorial' ? '📝' : item[0] === 'book' ? '📖' :
                    item[0] === 'video' ? '🎬' : '💻').fontSize(14)
                  Text(item[1]).fontSize(13).margin({ left: 4 })
                    .fontColor(this.type === item[0] ? (this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE) : ColorTokens.textPrimary(this.isDarkMode))
                }
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.type === item[0] ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                .borderRadius(20).margin({ right: 8, top: 8 })
                .onClick(() => { this.type = item[0]; })
              })
            }.width('100%').margin({ top: 8 })

            Text('资源链接 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.contentUrl, placeholder: 'https://...' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
              .onChange((value: string) => { this.contentUrl = value; })

            Text('来源网站（选填）').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.source, placeholder: '如：B站、GitHub、慕课网、东北大学教务处...' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
              .onChange((value: string) => { this.source = value; })

            Text('封面图链接（选填）').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.coverUrl, placeholder: 'https://...image.jpg' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
              .onChange((value: string) => { this.coverUrl = value; })

            Text('描述').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextArea({ text: this.description, placeholder: '资源描述...' })
              .fontSize(15).width('100%').height(100)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
              .padding(16).margin({ top: 8 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: 12 })
              .onChange((value: string) => { this.description = value; })

            Button(this.isLoading ? '上传中...' : '提交上传')
              .width('100%').height(48)
              .fontSize(16).fontWeight(FontWeight.Bolder).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
              .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(14)
              .margin({ top: 24 })
              .enabled(!this.isLoading)
              .scale({ x: this.btnPressed ? 0.96 : 1, y: this.btnPressed ? 0.96 : 1 })
              .animation({ curve: Curve.FastOutSlowIn, duration: 120 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.btnPressed = true; }
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.btnPressed = false; }
              })
              .onClick(() => { this.doUpload(); })

            Text('上传后将进入待审核状态，审核通过后即可公开')
              .fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
              .margin({ top: 12 }).width('100%').textAlign(TextAlign.Center)
          }
          .width('100%').padding(24)
          .margin({ top: 12, left: 24, right: 24 })

          Column().height(60)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
