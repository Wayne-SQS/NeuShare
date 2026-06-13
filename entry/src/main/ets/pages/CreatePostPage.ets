import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { CommunityService } from '../services/CommunityService';
import { Post, PostFile, formatFileSize, fileIcon } from '../models/PostModel';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { Context } from '@ohos.abilityAccessCtrl';

const SUPPORTED_TYPES: string[] = [
  '.zip', '.rar', '.7z',
  '.png', '.jpg', '.jpeg', '.svg', '.gif', '.webp', '.bmp',
  '.md', '.txt', '.markdown',
  '.docx', '.doc',
  '.xlsx', '.xls', '.csv',
  '.pptx', '.ppt',
  '.pdf',
  '.mp4', '.avi', '.mov',
  '.mp3', '.wav', '.flac'
];

const PRESET_TAGS: string[] = [
  '人工智能', '机器学习', '深度学习', '计算机视觉', '自然语言处理',
  '云计算', '大数据', '物联网',
  '计算机网络', '数据结构', '操作系统', '数据库',
  '软件工程', '前端开发', '后端开发', '移动开发',
  '网络安全', '区块链',
  '高等数学', '线性代数', '概率统计', '离散数学',
  '考研', '期末速成', '英语四六级', '英语',
  '实验报告', '课程设计', '毕业设计', '论文',
  '面试题', '课后答案', '历年真题', '笔记整理'
];

@Entry
@Component
struct CreatePostPage {
  @State title: string = '';
  @State content: string = '';
  @State author: string = '';
  @State selectedTags: string[] = [];
  @State files: PostFile[] = [];
  @State isSubmitting: boolean = false;
  private communityService: CommunityService = CommunityService.getInstance();

  toggleTag(tag: string): void {
    const idx = this.selectedTags.indexOf(tag);
    if (idx >= 0) {
      const updated: string[] = [];
      for (let i = 0; i < this.selectedTags.length; i++) {
        if (i !== idx) { updated.push(this.selectedTags[i]); }
      }
      this.selectedTags = updated;
    } else {
      this.selectedTags = [...this.selectedTags, tag];
    }
  }

  isTagSelected(tag: string): boolean {
    return this.selectedTags.indexOf(tag) >= 0;
  }

  async pickFiles(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const uris: string[] = await documentPicker.select({
        maxSelectNumber: 10,
        fileSuffixFilters: SUPPORTED_TYPES
      });

      if (uris && uris.length > 0) {
        const newFiles: PostFile[] = [];
        for (let i = 0; i < uris.length; i++) {
          const uri = uris[i];
          const parts = uri.split('/');
          const name = parts[parts.length - 1] || 'unknown';
          const dotIdx = name.lastIndexOf('.');
          const ext = dotIdx >= 0 ? name.substring(dotIdx).toLowerCase() : '';
          let size = 0;
          try {
            const stat = fileIo.statSync(uri);
            size = stat.size;
          } catch (e) {}
          newFiles.push({ name: name, uri: uri, type: ext, size: size });
        }
        this.files = [...this.files, ...newFiles];
      }
    } catch (e) {
      console.error('pickFiles failed: ' + JSON.stringify(e));
    }
  }

  removeFile(index: number): void {
    const updated: PostFile[] = [];
    for (let i = 0; i < this.files.length; i++) {
      if (i !== index) { updated.push(this.files[i]); }
    }
    this.files = updated;
  }

  async submitPost(): Promise<void> {
    if (!this.title.trim() || !this.content.trim() || this.isSubmitting) return;
    this.isSubmitting = true;

    const post: Post = {
      id: Date.now().toString(),
      title: this.title.trim(),
      content: this.content.trim(),
      author: this.author.trim() || '匿名',
      tags: this.selectedTags.slice(),
      createdAt: new Date().toISOString().slice(0, 10),
      recommended: false,
      likes: 0,
      favorites: 0,
      commentsCount: 0,
      imageUrls: [],
      files: this.files.slice()
    };

    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.communityService.init(context);
      await this.communityService.createPost(post);
    } catch (e) {
      console.error('CreatePostPage submit failed: ' + JSON.stringify(e));
    }

    router.back();
  }

  aboutToAppear(): void {}

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Blank()
        Text('发布帖子').fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
        Blank()
        Text('发布')
          .fontSize(15).fontWeight(FontWeight.Bold)
          .fontColor(this.title.trim() && this.content.trim() ? ColorTokens.PRIMARY : ColorTokens.TEXT_DISABLED)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.title.trim() && this.content.trim() ? ColorTokens.PRIMARY_LIGHT : ColorTokens.BG_INPUT)
          .onClick(() => { this.submitPost(); })
      }
      .width('100%').height(52).padding({ left: 12, right: 12 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Author
          Row() {
            Text('👤').fontSize(16)
            TextInput({ text: this.author, placeholder: '你的昵称（选填，默认「匿名」）' })
              .fontSize(14).layoutWeight(1).height(46)
              .backgroundColor(ColorTokens.BG_PAGE)
              .onChange((value: string) => { this.author = value; })
          }
          .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(ColorTokens.BG_CARD)

          Divider().color(ColorTokens.DIVIDER)

          // Title
          TextInput({ text: this.title, placeholder: '帖子标题...' })
            .fontSize(17).fontWeight(FontWeight.Bold)
            .width('100%').height(52)
            .backgroundColor(ColorTokens.BG_PAGE)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.title = value; })

          Divider().color(ColorTokens.DIVIDER)

          // Content
          TextArea({ text: this.content, placeholder: '分享你的学习心得、问题、资源...' })
            .fontSize(15).lineHeight(22)
            .width('100%').height(200)
            .backgroundColor(ColorTokens.BG_PAGE)
            .padding(16)
            .onChange((value: string) => { this.content = value; })

          Divider().color(ColorTokens.DIVIDER)

          // File picker
          Column() {
            Row() {
              Text('📂').fontSize(16)
              Text('添加附件').fontSize(14).fontColor(ColorTokens.TEXT_PRIMARY).margin({ left: 8 })
              Blank()
              Text('＋ 选择文件').fontSize(13).fontWeight(FontWeight.Bold).fontColor(ColorTokens.PRIMARY)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(ColorTokens.PRIMARY_LIGHT).borderRadius(16)
                .onClick(() => { this.pickFiles(); })
            }
            .width('100%').padding({ left: 16, right: 12 })

            Text('支持 zip · png · svg · md · docx · xlsx · ppt · pptx · pdf · txt 等')
              .fontSize(11).fontColor(ColorTokens.TEXT_DISABLED)
              .padding({ left: 16 }).margin({ top: 6 })

            if (this.files.length > 0) {
              Column() {
                ForEach(this.files, (file: PostFile, idx: number) => {
                  Row() {
                    Text(fileIcon(file.type)).fontSize(18)
                    Column() {
                      Text(file.name)
                        .fontSize(13).fontColor(ColorTokens.TEXT_PRIMARY)
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(file.type.toUpperCase().replace('.', '') + (file.size > 0 ? ' · ' + formatFileSize(file.size) : ''))
                        .fontSize(11).fontColor(ColorTokens.TEXT_DISABLED).margin({ top: 2 })
                    }
                    .margin({ left: 10 }).layoutWeight(1)

                    Text('✕').fontSize(12).fontColor(ColorTokens.RED)
                      .width(22).height(22).borderRadius(11)
                      .backgroundColor(ColorTokens.RED + '15').textAlign(TextAlign.Center)
                      .onClick(() => { this.removeFile(idx); })
                  }
                  .width('100%').padding(12)
                  .backgroundColor(ColorTokens.BG_INPUT).borderRadius(10)
                  .margin({ top: 6 })
                }, (file: PostFile, idx: number) => 'file' + idx.toString())
              }
              .width('100%').padding({ left: 16, right: 16 }).margin({ top: 4 })
            }
          }
          .width('100%').padding({ top: 10, bottom: 10 })
          .backgroundColor(ColorTokens.BG_PAGE)

          Divider().color(ColorTokens.DIVIDER)

          // Tags
          Column() {
            Row() {
              Text('🏷️').fontSize(15)
              Text('选择标签').fontSize(14).fontColor(ColorTokens.TEXT_PRIMARY).margin({ left: 6 })
              if (this.selectedTags.length > 0) {
                Text('（已选' + this.selectedTags.length.toString() + '个）')
                  .fontSize(12).fontColor(ColorTokens.ACCENT).margin({ left: 4 })
              }
            }
            .width('100%').padding({ left: 16, right: 16 }).margin({ top: 10 })

            // Selected tags
            if (this.selectedTags.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.selectedTags, (tag: string) => {
                  Text(tag)
                    .fontSize(12).fontColor('#FFFFFF')
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .backgroundColor(ColorTokens.PRIMARY).borderRadius(14)
                    .margin({ right: 6, top: 6 })
                    .onClick(() => { this.toggleTag(tag); })
                })
              }
              .width('100%').padding({ left: 16, right: 16 }).margin({ top: 8 })
            }

            // Preset tags
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(PRESET_TAGS, (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .fontColor(this.isTagSelected(tag) ? ColorTokens.PRIMARY : ColorTokens.TEXT_HINT)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(this.isTagSelected(tag) ? ColorTokens.PRIMARY_LIGHT : ColorTokens.BG_INPUT)
                  .border({ width: 1, color: this.isTagSelected(tag) ? ColorTokens.PRIMARY + '30' : '#00000000', radius: 14 })
                  .margin({ right: 6, top: 6 })
                  .onClick(() => { this.toggleTag(tag); })
              })
            }
            .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 10 })
          }
          .width('100%').backgroundColor(ColorTokens.BG_PAGE)

          Column().height(60)
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
