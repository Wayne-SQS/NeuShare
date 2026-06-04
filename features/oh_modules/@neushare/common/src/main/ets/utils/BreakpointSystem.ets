// ============================================================
// BreakpointSystem - 多设备断点适配
// 基于 mediaQuery 响应屏幕宽度变化
// 用法: @StorageLink('currentBreakpoint') breakpoint: BreakpointType
// ============================================================
import { mediaquery } from '@kit.ArkUI';

export enum BreakpointType {
  SM = 'sm',
  MD = 'md',
  LG = 'lg'
}

export class BreakpointSystem {
  private static listener: mediaquery.MediaQueryListener | null = null;

  static register(): void {
    const query = '(min-width: 840vp)';
    BreakpointSystem.listener = mediaquery.matchMediaSync(query);
    BreakpointSystem.updateBreakpoint(BreakpointSystem.listener);

    BreakpointSystem.listener.on('change', (result: mediaquery.MediaQueryResult) => {
      BreakpointSystem.updateBreakpoint(result);
    });

    const mdQuery = '(min-width: 600vp) and (max-width: 839vp)';
    const mdListener = mediaquery.matchMediaSync(mdQuery);
    mdListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        AppStorage.setOrCreate('currentBreakpoint', BreakpointType.MD);
      }
    });

    AppStorage.setOrCreate('currentBreakpoint', BreakpointType.SM);
  }

  private static updateBreakpoint(result: mediaquery.MediaQueryResult): void {
    if (result.matches) {
      AppStorage.setOrCreate('currentBreakpoint', BreakpointType.LG);
    } else {
      AppStorage.setOrCreate('currentBreakpoint', BreakpointType.SM);
    }
  }

  static isLargeScreen(): boolean {
    const bp = AppStorage.get<BreakpointType>('currentBreakpoint');
    return bp === BreakpointType.LG || bp === BreakpointType.MD;
  }
}
