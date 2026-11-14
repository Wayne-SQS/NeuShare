import router from '@ohos.router';
import { ColorTokens, FontScale, Radii, Spacing, ControlSize, PageHeader } from '@neushare/common';
import { ResourceApi, ResourceCreateData } from '../api/ResourceApi';
import { ApiResponse } from '@neushare/common';
import { ResourceService } from '../services/ResourceService';
import { CategoryItem } from '../models/ResourceModel';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import promptAction from '@ohos.promptAction';

const SUPPORTED_FILE_TYPES: string[] = [
  '.pdf',
  '.docx', '.doc',
  '.pptx', '.ppt',
  '.xlsx', '.xls', '.csv',
  '.zip', '.rar', '.7z',
  '.png', '.jpg', '.jpeg', '.svg', '.gif', '.webp', '.bmp',
  '.mp4', '.avi', '.mov',
  '.mp3', '.wav', '.flac',
  '.txt', '.md', '.markdown',
  '.py', '.java', '.cpp', '.c', '.js', '.ts', '.html', '.css'
];

interface PickedFile {
  name: string;
  uri: string;
  size: number;
}

function formatFileSize(bytes: number): string {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return bytes + ' B';
  const kb = bytes / 1024;
  if (kb < 1024) return kb.toFixed(1) + ' KB';
  const mb = kb / 1024;
  return mb.toFixed(1) + ' MB';
}

@Entry
@Component
struct UploadPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('topSafeAreaVp') topSafeArea: number = 0;
  @State title: string = '';
  @State categoryId: number = 0;
  @State type: string = '';
  @State description: string = '';
  @State contentUrl: string = '';
  @State coverUrl: string = '';
  @State source: string = '';
  @State isLoading: boolean = false;
  @State btnPressed: boolean = false;
  @State categories: CategoryItem[] = [];
  @State pickedFile: PickedFile | null = null;
  @State useFileUpload: boolean = false; // true=文件上传, false=URL上传
  private resourceApi: ResourceApi = new ResourceApi();
  private resourceService: ResourceService = ResourceService.getInstance();

  private types: string[][] = [
    ['tutorial', '教程'], ['book', '书籍'], ['video', '视频'], ['software', '软件']
  ];

  aboutToAppear(): void {
    this.categories = this.resourceService.getLocalCategories();
    // 异步拉取完整分类列表（服务器有12个，本地JSON只有5个）
    this.resourceService.fetchCategories().then((cats: CategoryItem[]) => {
      if (cats && cats.length > 0) {
        this.categories = cats;
      }
    }).catch((e: Error) => {
      console.error('fetchCategories in UploadPage failed: ' + JSON.stringify(e));
    });
  }

  async pickFile(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const uris: string[] = await documentPicker.select({
        maxSelectNumber: 1,
        fileSuffixFilters: SUPPORTED_FILE_TYPES
      });
      if (uris && uris.length > 0) {
        const uri = uris[0];
        const parts = uri.split('/');
        const name = parts[parts.length - 1] || 'unknown';
        let size = 0;
        try {
          const stat = fileIo.statSync(uri);
          size = stat.size;
        } catch (e) {
          console.warn('get file size failed: ' + JSON.stringify(e));
        }
        this.pickedFile = { name, uri, size };
        this.useFileUpload = true;
        // 自动用文件名填充标题
        if (!this.title.trim()) {
          const dotIdx = name.lastIndexOf('.');
          this.title = dotIdx >= 0 ? name.substring(0, dotIdx) : name;
        }
      }
    } catch (e) {
      console.error('pickFile failed: ' + JSON.stringify(e));
      // 用户取消选择不报错
    }
  }

  removeFile(): void {
    this.pickedFile = null;
    this.useFileUpload = false;
  }

  async doUpload(): Promise<void> {
    if (!this.title.trim()) { promptAction.showToast({ message: '请输入标题' }); return; }
    if (this.categoryId === 0) { promptAction.showToast({ message: '请选择分类' }); return; }
    if (this.useFileUpload) {
      if (!this.pickedFile) { promptAction.showToast({ message: '请选择文件' }); return; }
    } else {
      if (!this.contentUrl.trim()) { promptAction.showToast({ message: '请输入资源链接' }); return; }
    }
    this.isLoading = true;
    try {
      const resourceData: ResourceCreateData = {
        title: this.title.trim(),
        categoryId: this.categoryId,
        type: this.type,
        description: this.description.trim(),
        contentUrl: this.useFileUpload ? (this.pickedFile!.name) : this.contentUrl.trim(),
        coverUrl: this.coverUrl.trim(),
        source: this.source.trim()
      };
      let resp: ApiResponse<null>;
      if (this.useFileUpload && this.pickedFile) {
        resp = await this.resourceApi.createWithFile(resourceData, this.pickedFile.uri);
      } else {
        resp = await this.resourceApi.create(resourceData);
      }
      if (resp.code === 200) {
        promptAction.showToast({ message: '上传成功，等待审核' });
        setTimeout(() => { router.back(); }, 1500);
      } else {
        promptAction.showToast({ message: resp.message || '上传失败' });
      }
    } catch (e) {
      const msg = String(e);
      if (msg.includes('timeout') || msg.includes('Timeout')) {
        promptAction.showToast({ message: '上传超时，文件可能过大，请重试' });
      } else if (msg.includes('401')) {
        promptAction.showToast({ message: '登录已过期，请重新登录' });
      } else {
        promptAction.showToast({ message: '上传失败: ' + (msg.length > 40 ? msg.substring(0, 40) + '...' : msg) });
      }
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      PageHeader({ title: '上传资源', subtitle: '支持链接或本地文件' })

      Scroll() {
        Column() {
          Column() {
            // ── 上传模式切换 ──
            Row() {
              Text('上传方式').fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textPrimary(this.isDarkMode))
              Blank()
              Row() {
                Text('链接').fontSize(FontScale.LABEL)
                  .fontWeight(!this.useFileUpload ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(!this.useFileUpload ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .backgroundColor(!this.useFileUpload ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius({ topLeft: Radii.CARD, bottomLeft: Radii.CARD })
                  .onClick(() => { this.useFileUpload = false; })
                Text('文件').fontSize(FontScale.LABEL)
                  .fontWeight(this.useFileUpload ? FontWeight.Bold : FontWeight.Regular)
                  .fontColor(this.useFileUpload ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textHint(this.isDarkMode))
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .backgroundColor(this.useFileUpload ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius({ topRight: Radii.CARD, bottomRight: Radii.CARD })
                  .onClick(() => { this.useFileUpload = true; })
              }
            }
            .width('100%').margin({ top: 8 })

            // ── 文件选择器 ──
            if (this.useFileUpload) {
              if (this.pickedFile) {
                Row() {
                  Column() {
                    Text(this.pickedFile.name)
                      .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Medium)
                      .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(formatFileSize(this.pickedFile.size))
                      .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  Text('删除').fontSize(FontScale.MICRO).fontColor(ColorTokens.error(this.isDarkMode))
                    .height(ControlSize.BUTTON).padding({ left: Spacing.SM, right: Spacing.SM })
                    .textAlign(TextAlign.Center)
                    .onClick(() => { this.removeFile(); })
                }
                .width('100%').padding(12)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
                .border({ width: 1, color: ColorTokens.primary(this.isDarkMode), radius: Radii.CARD })
                .margin({ top: 10 })
              } else {
                Row() {
                  Text('点击选择设备上的文件').fontSize(FontScale.BODY_SM).fontColor(ColorTokens.primary(this.isDarkMode))
                  Blank()
                  Text('选择').fontSize(FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode))
                }
                .width('100%').padding(16)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
                .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD, style: BorderStyle.Dashed })
                .margin({ top: 10 })
                .onClick(() => { this.pickFile(); })
              }
              Text('支持 PDF · Word · PPT · Excel · 压缩包 · 图片 · 代码等')
                .fontSize(FontScale.MICRO).fontColor(ColorTokens.textDisabled(this.isDarkMode))
                .margin({ top: 6, left: 4 })
            } else {
              // URL 模式下的链接输入
              Text('资源链接 *').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
                .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 12 })
              TextInput({ text: this.contentUrl, placeholder: 'https://...' })
                .fontSize(FontScale.BODY).width('100%').height(48)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
                .padding({ left: 16 })
                .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
                .onChange((value: string) => { this.contentUrl = value; })
            }

            Text('标题 *').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.title, placeholder: '资源标题' })
              .fontSize(FontScale.BODY).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding({ left: 16 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.title = value; })

            Text('分类 *').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.categories, (cat: CategoryItem, idx: number) => {
                Text(cat.title)
                  .fontSize(FontScale.CAPTION).fontColor(this.categoryId === cat.id ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .backgroundColor(this.categoryId === cat.id ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius(Radii.HUGE).margin({ right: 8, top: 8 })
                  .onClick(() => { this.categoryId = cat.id; })
              }, (cat: CategoryItem, idx: number) => 'cat_' + cat.id.toString())
            }.width('100%')

            Text('类型').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            Row() {
              ForEach(this.types, (item: string[], idx: number) => {
                Text(item[1])
                  .fontSize(FontScale.CAPTION)
                  .fontColor(this.type === item[0] ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textPrimary(this.isDarkMode))
                  .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.SM, bottom: Spacing.SM })
                  .backgroundColor(this.type === item[0] ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                  .borderRadius(Radii.SM).margin({ right: Spacing.SM, top: Spacing.SM })
                  .onClick(() => { this.type = item[0]; })
              }, (item: string[], idx: number) => 'type_' + idx.toString())
            }.width('100%')

            Text('来源网站（选填）').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.source, placeholder: '如：B站、GitHub、慕课网、东北大学教务处...' })
              .fontSize(FontScale.BODY).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding({ left: 16 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.source = value; })

            Text('封面图链接（选填）').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextInput({ text: this.coverUrl, placeholder: 'https://...image.jpg' })
              .fontSize(FontScale.BODY).width('100%').height(48)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding({ left: 16 })
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.coverUrl = value; })

            Text('描述').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).width('100%').margin({ top: 16 })
            TextArea({ text: this.description, placeholder: '资源描述...' })
              .fontSize(FontScale.BODY).width('100%').height(100)
              .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
              .padding(16)
              .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
              .onChange((value: string) => { this.description = value; })

            Button(this.isLoading ? '上传中...' : '提交上传')
              .width('100%').height(ControlSize.BUTTON)
              .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.BUTTON)
              .margin({ top: Spacing.XXL })
              .enabled(!this.isLoading)
              .scale({ x: this.btnPressed ? 0.96 : 1, y: this.btnPressed ? 0.96 : 1 })
              .animation({ curve: Curve.EaseOut, duration: 200 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.btnPressed = true; }
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.btnPressed = false; }
              })
              .onClick(() => { this.doUpload(); })

            Text('上传后将进入待审核状态，审核通过后即可公开')
              .fontSize(FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode))
              .margin({ top: 12 }).width('100%').textAlign(TextAlign.Center)
          }
          .width('100%').padding(24)
          .margin({ top: 12, left: 24, right: 24 })

          Column().height(60)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .padding({ top: this.topSafeArea })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.9)
  }
}
