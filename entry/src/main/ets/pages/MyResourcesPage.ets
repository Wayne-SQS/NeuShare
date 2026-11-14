import router from '@ohos.router';
import { ColorTokens, FontScale, Radii, Spacing, ControlSize, Elevation, GridLayout, PageScaffold, StateView, ViewState } from '@neushare/common';
import { ResourceApi } from '../api/ResourceApi';
import { ResourceVO, adaptResource, ResourceItem } from '../models/ResourceModel';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct MyResourcesPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State resources: ResourceItem[] = [];
  @State isLoading: boolean = false;
  @State loadFailed: boolean = false;
  @State showDeleteDialog: boolean = false;
  @State deleteTargetId: number = 0;
  @State deleteTargetTitle: string = '';
  private resourceApi: ResourceApi = new ResourceApi();

  async aboutToAppear(): Promise<void> {
    await this.loadResources();
  }

  async loadResources(): Promise<void> {
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const resp = await this.resourceApi.getUserResources();
      if (resp.code === 200 && resp.data) {
        this.resources = (resp.data.records || []).map(vo => adaptResource(vo));
      } else {
        promptAction.showToast({ message: '加载失败: ' + (resp.message || '') });
        this.loadFailed = true;
      }
    } catch (e) {
      promptAction.showToast({ message: '无法连接服务器' });
      this.loadFailed = true;
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
      case 1: return ColorTokens.STATUS_SUCCESS_LIGHT;
      case 2: return ColorTokens.ERROR_LIGHT;
      default: return ColorTokens.STATUS_WARNING_LIGHT;
    }
  }

  build() {
    Stack() {
      PageScaffold({ title: '我的资源' }) {
        Column() {
        // 操作行
        Row() {
          Text('共 ' + this.resources.length.toString() + ' 个资源')
            .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textHint(this.isDarkMode))
          Blank()
          Text('上传资源')
            .fontSize(FontScale.CAPTION).fontColor(ColorTokens.primary(this.isDarkMode))
            .height(ControlSize.TOUCH).padding({ left: Spacing.MD, right: Spacing.MD })
            .textAlign(TextAlign.Center)
            .onClick(() => { router.pushUrl({ url: 'pages/UploadPage' }); })
        }
        .width('100%').padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM })

        if (this.isLoading) {
          StateView({ state: ViewState.LOADING, message: '正在加载我的资源' })
        } else if (this.loadFailed) {
          StateView({
            state: ViewState.ERROR,
            message: '加载失败',
            hint: '请检查网络后重试',
            onRetry: () => { this.loadResources(); }
          })
        } else if (this.resources.length === 0) {
          StateView({
            state: ViewState.EMPTY,
            message: '还没有上传过资源',
            hint: '点击上方「上传资源」开始分享'
          })
        } else {
          GridRow({
            columns: { xs: 1, sm: 1, md: 2, lg: 3, xl: 4 },
            gutter: { x: Spacing.SM, y: Spacing.SM },
            breakpoints: { value: GridLayout.BREAKPOINTS, reference: BreakpointsReference.WindowSize }
          }) {
            ForEach(this.resources, (item: ResourceItem) => {
              GridCol({ span: 1 }) {
                Column() {
                  Row() {
                    Text(item.title).fontSize(FontScale.BODY).fontWeight(FontWeight.Bold)
                      .fontColor(ColorTokens.textPrimary(this.isDarkMode)).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                    Text(this.getStatusLabel(item.status))
                      .fontSize(FontScale.TINY).fontColor(ColorTokens.TEXT_WHITE)
                      .padding({ left: Spacing.XS, right: Spacing.XS, top: Spacing.XXS, bottom: Spacing.XXS })
                      .backgroundColor(this.getStatusColor(item.status)).borderRadius(Radii.XS)
                      .margin({ left: Spacing.SM })
                  }.width('100%')
                  Text(item.description || '暂无描述').fontSize(FontScale.LABEL)
                    .fontColor(ColorTokens.textSecondary(this.isDarkMode)).maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                    .margin({ top: Spacing.XS })
                  Row() {
                    Text(item.publishDate || '').fontSize(FontScale.MICRO)
                      .fontColor(ColorTokens.textDisabled(this.isDarkMode))
                    if (item.likeCount > 0) {
                      Text('赞 ' + item.likeCount).fontSize(FontScale.MICRO)
                        .fontColor(ColorTokens.textDisabled(this.isDarkMode)).margin({ left: Spacing.SM })
                    }
                    Blank()
                    Text('删除').fontSize(FontScale.CAPTION).fontColor(ColorTokens.error(this.isDarkMode))
                      .height(ControlSize.BUTTON).padding({ left: Spacing.MD, right: Spacing.MD })
                      .textAlign(TextAlign.Center)
                      .onClick(() => { this.confirmDelete(item.id, item.title); })
                  }.width('100%').margin({ top: Spacing.XS })
                }
                .width('100%').padding(Spacing.CARD)
                .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
                .border({ width: Elevation.BORDER_WIDTH, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
                .shadow({ radius: Elevation.CARD_SHADOW_RADIUS, color: ColorTokens.shadowCard(this.isDarkMode), offsetX: 0, offsetY: Elevation.CARD_SHADOW_OFFSET_Y })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/DetailPage', params: { resourceId: item.id } });
                })
              }
            }, (item: ResourceItem) => item.id.toString())
          }
          .width('100%')
          .padding({ left: Spacing.PAGE, right: Spacing.PAGE, top: Spacing.SM, bottom: Spacing.HUGE })
        }
        }
        .width('100%')
      }

      // Delete confirmation dialog
      if (this.showDeleteDialog) {
        Column() {
          Column() {
            Text('确认删除').fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold)
              .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ bottom: 12 })
            Text('确定要删除「' + this.deleteTargetTitle + '」吗？')
              .fontSize(FontScale.BODY_SM).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ bottom: 8 })
            Text('删除后无法恢复').fontSize(FontScale.LABEL).fontColor(ColorTokens.error(this.isDarkMode)).margin({ bottom: 20 })
            Row() {
              Text('取消').fontSize(FontScale.BODY_SM).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                .layoutWeight(1).height(40).textAlign(TextAlign.Center)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.LG)
                .onClick(() => { this.showDeleteDialog = false; })
              Text('删除').fontSize(FontScale.BODY_SM).fontColor(ColorTokens.TEXT_WHITE)
                .layoutWeight(1).height(40).textAlign(TextAlign.Center)
                .backgroundColor(ColorTokens.ERROR_LIGHT).borderRadius(Radii.LG)
                .margin({ left: 12 })
                .onClick(() => { this.deleteResource(); })
            }.width('100%')
          }
          .width('80%').padding(24)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XXL)
        }
        .width('100%').height('100%')
        .backgroundColor(ColorTokens.OVERLAY)
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
