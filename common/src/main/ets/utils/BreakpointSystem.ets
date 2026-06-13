// ============================================================
// BreakpointSystem - 多设备断点适配（5档）
// 双通道检测：window 尺寸（初始值）+ mediaQuery（响应式更新）
// 用法: @StorageLink('currentBreakpoint') breakpoint: BreakpointTypeEnum
//       new BreakpointType({ sm: 1, md: 2, lg: 3 }).getValue(this.currentBreakpoint)
// ============================================================
import { mediaquery } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';

interface BreakpointTypeOption<T> {
  xs?: T
  sm?: T
  md?: T
  lg?: T
  xl?: T
}

/**
 * 按断点选值工具类，替代大量 if/else
 * 用法: new BreakpointType<number>({ sm: 1, md: 2, lg: 3 }).getValue(this.currentBreakpoint)
 */
export class BreakpointType<T> {
  options: BreakpointTypeOption<T>;

  constructor(option: BreakpointTypeOption<T>) {
    this.options = option
  }

  getValue(currentBreakPoint: string): T | undefined {
    return (this.options as Record<string, T | undefined>)[currentBreakPoint];
  }
}

class BreakpointItem {
  name: string = '';
  size: number = 0;
  mediaQueryListener?: mediaquery.MediaQueryListener;

  constructor(name: string, size: number) {
    this.name = name;
    this.size = size;
  }
}

export enum BreakpointTypeEnum {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

/**
 * 断点阈值定义 — 与 BreakpointItem 数组保持同步
 */
const BP_THRESHOLDS: [string, number][] = [
  ['xs', 0],
  ['sm', 320],
  ['md', 600],
  ['lg', 840],
  ['xl', 1500]
];

/**
 * 根据像素宽度计算断点名
 */
function widthToBreakpoint(width: number): string {
  let result = 'sm';
  for (let i = 0; i < BP_THRESHOLDS.length; i++) {
    if (width >= BP_THRESHOLDS[i][1]) {
      result = BP_THRESHOLDS[i][0];
    }
  }
  return result;
}

/**
 * 向后兼容别名 — 项目中大量使用 BreakpointType.SM/MD/LG
 * 保留旧名，指向新枚举值
 */
export class BreakpointTypeOld {
  SM: string = BreakpointTypeEnum.SM;
  MD: string = BreakpointTypeEnum.MD;
  LG: string = BreakpointTypeEnum.LG;
}

export class BreakpointSystem {
  private currentBreakpoint: string = BreakpointTypeEnum.SM;
  private breakpoints: BreakpointItem[] = [
    new BreakpointItem('xs', 0),
    new BreakpointItem('sm', 320),
    new BreakpointItem('md', 600),
    new BreakpointItem('lg', 840),
    new BreakpointItem('xl', 1500)
  ];
  private isRegistered: boolean = false;

  private static instance: BreakpointSystem | null = null;

  static getInstance(): BreakpointSystem {
    if (!BreakpointSystem.instance) {
      BreakpointSystem.instance = new BreakpointSystem();
    }
    return BreakpointSystem.instance;
  }

  private updateCurrentBreakpoint(breakpoint: string): void {
    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = breakpoint;
      AppStorage.setOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
    }
  }

  /**
   * 通过 window 尺寸直接检测断点（主力初始检测通道）
   * 在 EntryAbility.onWindowStageCreate 中调用
   */
  async detectFromWindow(windowStage: window.WindowStage): Promise<void> {
    try {
      const mainWindow = await windowStage.getMainWindow();
      const props = mainWindow.getWindowProperties();
      const w = props.windowRect.width;
      const bp = widthToBreakpoint(w);
      console.info('[BreakpointSystem] detectFromWindow: width=' + w + ' → ' + bp);
      this.updateCurrentBreakpoint(bp);
    } catch (e) {
      console.warn('[BreakpointSystem] detectFromWindow failed: ' + JSON.stringify(e));
    }
  }

  register(): void {
    if (this.isRegistered) {
      return;
    }
    this.isRegistered = true;
    this.breakpoints.forEach((breakpoint: BreakpointItem, index: number) => {
      let condition: string;
      if (index === this.breakpoints.length - 1) {
        condition = '(' + breakpoint.size + 'vp<=width)';
      } else {
        condition = '(' + breakpoint.size + 'vp<=width<' + this.breakpoints[index + 1].size + 'vp)';
      }
      breakpoint.mediaQueryListener = mediaquery.matchMediaSync(condition);
      breakpoint.mediaQueryListener.on('change', (mediaQueryResult: mediaquery.MediaQueryResult) => {
        if (mediaQueryResult.matches) {
          this.updateCurrentBreakpoint(breakpoint.name);
        }
      });
    });

    // 尝试从 mediaQuery 同步读取初始状态（fallback）
    for (let i = this.breakpoints.length - 1; i >= 0; i--) {
      const bp = this.breakpoints[i];
      if (bp.mediaQueryListener && bp.mediaQueryListener.matches) {
        if (this.currentBreakpoint !== bp.name) {
          this.currentBreakpoint = bp.name;
          AppStorage.setOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
        }
        break;
      }
    }
    // 确保 AppStorage 至少有一个兜底值
    if (AppStorage.get<string>('currentBreakpoint') === undefined) {
      AppStorage.setOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
    }
  }

  unregister(): void {
    this.breakpoints.forEach((breakpoint: BreakpointItem) => {
      if (breakpoint.mediaQueryListener) {
        breakpoint.mediaQueryListener.off('change');
      }
    });
    this.isRegistered = false;
  }

  static isLargeScreen(): boolean {
    const bp = AppStorage.get<string>('currentBreakpoint');
    return bp === BreakpointTypeEnum.LG || bp === BreakpointTypeEnum.XL;
  }
}

/**
 * 向后兼容：保留旧的 BreakpointType 枚举名
 * 项目中已有代码用 BreakpointType.SM / BreakpointType.MD / BreakpointType.LG
 */
export { BreakpointTypeEnum as BreakpointTypeValue }
