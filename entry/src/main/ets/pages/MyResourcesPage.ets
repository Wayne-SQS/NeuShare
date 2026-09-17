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
  @State showDeleteDialog: boolean = false;
  @State deleteTargetId: number = 0;
  @State deleteTargetTitle: string = '';
  private resourceApi: ResourceApi = new ResourceApi();

  async aboutToAppear(): Promise<void> {
    await this.loadResources();
  }

  async loadResources(): Promise<void> {
    this.isLoading = true;
    try {
      const resp = await this.resourceApi.getUserResources();
      if (resp.code === 200 && resp.data) {
        this.resources = (resp.data.records || []).map(vo => adaptResource(vo));
      } else {
        promptAction.showToast({ message: '加载失败: ' + (resp.message || '') });
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器' });
    }
    this.isLoading = false;
  }

  confirmDelete(id: number, title: string): void {
    this.deleteTargetId = id;
    this.deleteTargetTitle = title;
    this.showDeleteDialog = true;
  }

  async deleteResource(): Promise<void> {
    this.showDeleteDialog = false;
    const id = this.deleteTargetId;
    this.deleteTargetId = 0;
    this.deleteTargetTitle = '';
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

  getStatusLabel(status: number): string {
    const labels: string[] = ['待审核', '已发布', '已驳回'];
    return labels[status] || '未知';
  }

  getStatusColor(status: number): string {
    switch (status) {
      case 1: return '#4CAF50';
      case 2: return '#F44336';
      default: return '#FF9800';
    }
  }

  build() {
    Stack() {
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
            Text('点击右上角上传你的第一个资源').fontSize(13).fontColor(ColorTokens.textDisabled(this.isDarkMode))
              .margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.resources, (item: ResourceItem) => {
              ListItem() {
                Row() {
                  Column() {
                    Row() {
                      Text(item.title).fontSize(15).fontWeight(FontWeight.Bold)
                        .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                      Text(this.getStatusLabel(item.status))
                        .fontSize(10).fontColor('#FFFFFF')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor(this.getStatusColor(item.status)).borderRadius(4)
                        .margin({ left: 8 })
                    }.width('100%')
                    Text(item.description || '暂无描述').fontSize(12)
                      .fontColor(ColorTokens.textSecondary(this.isDarkMode)).maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                      .margin({ top: 6 })
                    Row() {
                      Text(item.publishDate || '').fontSize(11)
                        .fontColor(ColorTokens.textDisabled(this.isDarkMode))
                      if (item.likeCount > 0) {
                        Text(' 👍 ' + item.likeCount).fontSize(11)
                          .fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: 8 })
                      }
                    }.margin({ top: 6 })
                  }.layoutWeight(1)

                  Text('删除').fontSize(13).fontColor(ColorTokens.TEXT_WHITE)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .backgroundColor('#F44336').borderRadius(8)
                    .onClick(() => { this.confirmDelete(item.id, item.title); })
                }
                .width('100%').padding(16)
                .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(12)
                .margin({ left: 24, right: 24, top: 8 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                })
              }
            }, (item: ResourceItem) => item.id.toString())
          }
          .width('100%').layoutWeight(1).margin({ top: 8 })
          .divider({ strokeWidth: 0 })
        }
      }
      .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))

      // Delete confirmation dialog
      if (this.showDeleteDialog) {
        Column() {
          Column() {
            Text('确认删除').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ bottom: 12 })
            Text('确定要删除「' + this.deleteTargetTitle + '」吗？')
              .fontSize(14).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ bottom: 8 })
            Text('删除后无法恢复').fontSize(12).fontColor(ColorTokens.error(this.isDarkMode)).margin({ bottom: 20 })
            Row() {
              Text('取消').fontSize(14).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .layoutWeight(1).height(40).textAlign(TextAlign.Center)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(10)
                .onClick(() => { this.showDeleteDialog = false; })
              Text('删除').fontSize(14).fontColor(ColorTokens.TEXT_WHITE)
                .layoutWeight(1).height(40).textAlign(TextAlign.Center)
                .backgroundColor('#F44336').borderRadius(10)
                .margin({ left: 12 })
                .onClick(() => { this.deleteResource(); })
            }.width('100%')
          }
          .width('80%').padding(24)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(16)
        }
        .width('100%').height('100%')
        .backgroundColor('#66000000')
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showDeleteDialog = false; })
      }
    }
    .width('100%').height('100%')
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
