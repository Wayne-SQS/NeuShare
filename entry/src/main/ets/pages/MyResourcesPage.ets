import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { ResourceApi } from '../api/ResourceApi';
import { ResourceVO, adaptResource, ResourceItem } from '../models/ResourceModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct MyResourcesPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State resources: ResourceItem[] = [];
  @State isLoading: boolean = false;
  private resourceApi: ResourceApi = new ResourceApi();

  private statusLabels: string[] = ['待审核', '已发布', '已驳回'];
  private statusColors: string[] = [ColorTokens.WARNING_LIGHT, ColorTokens.SUCCESS_LIGHT, ColorTokens.ERROR_LIGHT];

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
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('我的资源').fontSize(18).fontWeight(FontWeight.Bolder)
          .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ left: 12 })
        Blank()
        Text('+ 上传').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.primary(this.isDarkMode))
          .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
      }
      .width('100%').height(52).padding({ left: 24, right: 24 }).backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      if (this.isLoading) {
        Column() { Text('加载中...').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode)) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.resources.length === 0) {
        Column() {
          Text('📦').fontSize(48).margin({ bottom: 16 })
          Text('还没有上传过资源').fontSize(16).fontColor(ColorTokens.textHint(this.isDarkMode))
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
                    .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  Text(item.description || '暂无描述').fontSize(12)
                    .fontColor(ColorTokens.textSecondary(this.isDarkMode)).maxLines(2)
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

                Text('删除').fontSize(13).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(8)
                  .onClick(() => { this.deleteResource(item.id); })
              }
              .width('100%').padding(16)
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
              .margin({ left: 24, right: 24, top: 8 })
            }
          }, (item: ResourceItem) => item.id.toString())
        }
        .width('100%').layoutWeight(1).margin({ top: 8 })
        .divider({ strokeWidth: 0 })
      }
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
