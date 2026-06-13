import { pasteboard } from '@kit.BasicServicesKit';
import promptAction from '@ohos.promptAction';

/**
 * 分享服务
 * 使用系统剪贴板完成分享（ShareKit 在当前 SDK 不可用）
 */
export class ShareHelper {
  private static instance: ShareHelper;

  private constructor() {}

  static getInstance(): ShareHelper {
    if (!ShareHelper.instance) {
      ShareHelper.instance = new ShareHelper();
    }
    return ShareHelper.instance;
  }

  /**
   * 分享文本链接（复制到剪贴板）
   */
  async shareText(title: string, url: string): Promise<boolean> {
    const text: string = title + ' - NEUShare | ' + url;
    return this.copyToClipboard(text);
  }

  /**
   * 分享资源链接
   */
  async shareResource(resourceId: number, title: string): Promise<boolean> {
    const url: string = 'https://neushare.cn/resource/' + resourceId;
    return this.shareText(title, url);
  }

  /**
   * 复制文本到剪贴板
   */
  private async copyToClipboard(text: string): Promise<boolean> {
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      promptAction.showToast({ message: '链接已复制到剪贴板' });
      return true;
    } catch (e) {
      console.error('copyToClipboard failed: ' + JSON.stringify(e));
      promptAction.showToast({ message: '分享失败' });
      return false;
    }
  }
}
