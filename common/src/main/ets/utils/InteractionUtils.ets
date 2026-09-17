// 按压缩放动画工具 — 为按钮/可点击元素提供统一的按压反馈
// 用法示例：
//   @State pressed: boolean = false;
//   Button(...)
//     .scale({ x: this.pressed ? PressableScale.SCALE_DOWN : 1, y: ... })
//     .onClick(() => { PressableScale.bounce(this, 'pressed'); ... })

export class PressableScale {
  static readonly SCALE_DOWN: number = 0.96;
  static readonly SCALE_DOWN_WIDE: number = 0.97;
  static readonly DURATION: number = 120;
  static readonly CURVE: Curve = Curve.FastOutSlowIn;

  /**
   * 执行弹跳缩放动画：先缩小再回弹
   * @param target 持有 pressed 状态的对象（通常是组件自身 this）
   * @param stateKey pressed 状态键名
   * @param scaleDown 缩小比例（可选，默认 0.96）
   */
  static bounce(target: Record<string, Object>, stateKey: string, scaleDown?: number): void {
    const scale = scaleDown ?? PressableScale.SCALE_DOWN;
    animateTo({ duration: PressableScale.DURATION, curve: PressableScale.CURVE }, () => {
      target[stateKey] = true;
    });
    setTimeout(() => {
      animateTo({ duration: PressableScale.DURATION, curve: PressableScale.CURVE }, () => {
        target[stateKey] = false;
      });
    }, PressableScale.DURATION);
  }
}
