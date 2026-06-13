import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceApi } from '../api/ResourceApi';
import { ResourceVO, adaptResource, ResourceItem } from '../models/ResourceModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct MyResourcesPage {
  @State resources: ResourceItem[] = [];
  @State isLoading: boolean = false;
  private resourceApi: ResourceApi = new ResourceApi();

  private statusLabels: string[] = ['待审核', '已发布', '已驳回'];
  private statusColors: string[] = ['#FF9800', '#4CAF50', '#F44336'];

  async aboutToAppear(): Promise<void> {
    await this.loadResources();
  }

  async loadResources(): Promise<void> {
    this.isLoading = true;
    try {
      const resp = await this.resourceApi.getUserResources();
      if (resp.code === 200 && resp.data) {
        this.resources = resp.data.map(vo => adaptResource(vo));
      } else {
        promptAction.showToast({ message: '加载失败: ' + (resp.message || '') });
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器' });
    }
    this.isLoading = false;
  }

  async deleteResource(id: number): Promise<void> {
    try {
      const resp = await this.resourceApi.deleteResource(id);
      if (resp.code === 200) {
        this.resources = this.resources.filter(r => r.id !== id);
        promptAction.showToast({ message: '删除成功' });
      } else {
        promptAction.showToast({ message: '删除失败: ' + (resp.message || '') });
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器' });
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('我的资源').fontSize(18).fontWeight(FontWeight.Bolder)
          .fontColor(ColorTokens.TEXT_PRIMARY).margin({ left: 12 })
        Blank()
        Text('+ 上传').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.PRIMARY)
          .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor(ColorTokens.BG_CARD)

      if (this.isLoading) {
        Column() { Text('加载中...').fontSize(16).fontColor(ColorTokens.TEXT_HINT) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.resources.length === 0) {
        Column() {
          Text('📦').fontSize(48).margin({ bottom: 16 })
          Text('还没有上传过资源').fontSize(16).fontColor(ColorTokens.TEXT_HINT)
          Text('点击右上角上传你的第一个资源').fontSize(13).fontColor(ColorTokens.TEXT_DISABLED)
            .margin({ top: 8 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.resources, (item: ResourceItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Bold)
                    .fontColor(ColorTokens.TEXT_PRIMARY).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  Text(item.description || '暂无描述').fontSize(12)
                    .fontColor(ColorTokens.TEXT_SECONDARY).maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                    .margin({ top: 6 })
                  Row() {
                    Text(item.publishDate || '').fontSize(11)
                      .fontColor(ColorTokens.TEXT_DISABLED)
                    if (item.likeCount > 0) {
                      Text(' 👍 ' + item.likeCount).fontSize(11)
                        .fontColor(ColorTokens.TEXT_DISABLED).margin({ left: 8 })
                    }
                  }.margin({ top: 6 })
                }.layoutWeight(1)

                Text('删除').fontSize(13).fontColor('#FF5A5F')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('#FFF0F0').borderRadius(8)
                  .onClick(() => { this.deleteResource(item.id); })
              }
              .width('100%').padding(16)
              .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
              .margin({ left: 16, right: 16, top: 8 })
            }
          }, (item: ResourceItem) => item.id.toString())
        }
        .width('100%').layoutWeight(1).margin({ top: 8 })
        .divider({ strokeWidth: 0 })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }
}
