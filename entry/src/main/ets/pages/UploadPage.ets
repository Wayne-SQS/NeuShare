import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceApi } from '../api/ResourceApi';
import { ResourceService } from '../services/ResourceService';
import { CategoryItem } from '../models/ResourceModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct UploadPage {
  @State title: string = '';
  @State categoryId: number = 0;
  @State type: string = 'tutorial';
  @State description: string = '';
  @State contentUrl: string = '';
  @State coverUrl: string = '';
  @State isLoading: boolean = false;
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
        coverUrl: this.coverUrl.trim()
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
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('上传资源').fontSize(18).fontWeight(FontWeight.Bolder)
          .fontColor(ColorTokens.TEXT_PRIMARY).margin({ left: 12 })
      }
      .width('100%').height(52).padding({ left: 16 }).backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          Column() {
            Text('标题 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%')
            TextInput({ text: this.title, placeholder: '资源标题' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.title = value; })

            Text('分类 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%').margin({ top: 16 })
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.categories, (cat: CategoryItem) => {
                Text(cat.title)
                  .fontSize(13).fontColor(this.categoryId === cat.id ? '#FFFFFF' : ColorTokens.TEXT_PRIMARY)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .backgroundColor(this.categoryId === cat.id ? ColorTokens.PRIMARY : '#F5F5F5')
                  .borderRadius(20).margin({ right: 8, top: 8 })
                  .onClick(() => { this.categoryId = cat.id; })
              })
            }.width('100%').margin({ top: 8 })

            Text('类型').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%').margin({ top: 16 })
            Row() {
              ForEach(this.types, (item: string[]) => {
                Row() {
                  Text(item[0] === 'tutorial' ? '📝' : item[0] === 'book' ? '📖' :
                    item[0] === 'video' ? '🎬' : '💻').fontSize(14)
                  Text(item[1]).fontSize(13).margin({ left: 4 })
                    .fontColor(this.type === item[0] ? '#FFFFFF' : ColorTokens.TEXT_PRIMARY)
                }
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.type === item[0] ? ColorTokens.PRIMARY : '#F5F5F5')
                .borderRadius(20).margin({ right: 8, top: 8 })
                .onClick(() => { this.type = item[0]; })
              })
            }.width('100%').margin({ top: 8 })

            Text('资源链接 *').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%').margin({ top: 16 })
            TextInput({ text: this.contentUrl, placeholder: 'https://...' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.contentUrl = value; })

            Text('封面图链接（选填）').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%').margin({ top: 16 })
            TextInput({ text: this.coverUrl, placeholder: 'https://...image.jpg' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 }).margin({ top: 8 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.coverUrl = value; })

            Text('描述').fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.TEXT_PRIMARY).width('100%').margin({ top: 16 })
            TextArea({ text: this.description, placeholder: '资源描述...' })
              .fontSize(15).width('100%').height(100)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding(16).margin({ top: 8 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.description = value; })

            Button(this.isLoading ? '上传中...' : '提交上传')
              .width('100%').height(48)
              .fontSize(16).fontWeight(FontWeight.Bolder).fontColor('#FFFFFF')
              .backgroundColor(ColorTokens.PRIMARY).borderRadius(14)
              .margin({ top: 24 })
              .enabled(!this.isLoading)
              .onClick(() => { this.doUpload(); })

            Text('上传后将进入待审核状态，审核通过后即可公开')
              .fontSize(12).fontColor(ColorTokens.TEXT_HINT)
              .margin({ top: 12 }).width('100%').textAlign(TextAlign.Center)
          }
          .width('100%').padding(24)
          .margin({ top: 12, left: 16, right: 16 })

          Column().height(60)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
