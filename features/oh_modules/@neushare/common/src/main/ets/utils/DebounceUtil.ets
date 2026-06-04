// ============================================================
// DebounceUtil - 防抖工具
// 防止高频事件（搜索输入、滚动等）过度触发
// ============================================================

export class DebounceUtil {
  private static timers: Map<string, number> = new Map();

  /**
   * 防抖：在 wait 毫秒内只执行最后一次调用
   * @param key 唯一标识（通常用方法名）
   * @param fn 要执行的函数
   * @param wait 等待时间（毫秒），默认 300
   */
  static debounce(key: string, fn: () => void, wait: number = 300): void {
    const existing = DebounceUtil.timers.get(key);
    if (existing !== undefined) {
      clearTimeout(existing);
    }
    const timer = setTimeout(() => {
      DebounceUtil.timers.delete(key);
      fn();
    }, wait);
    DebounceUtil.timers.set(key, timer);
  }

  /**
   * 清除指定 key 的防抖计时器
   */
  static cancel(key: string): void {
    const existing = DebounceUtil.timers.get(key);
    if (existing !== undefined) {
      clearTimeout(existing);
      DebounceUtil.timers.delete(key);
    }
  }
}
