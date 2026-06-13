/**
 * 通用 IDataSource 实现，用于 LazyForEach 懒加载列表。
 * 用法：const ds = new ArrayDataSource<T>(items); LazyForEach(ds, ...)
 */
export class ArrayDataSource<T> implements IDataSource {
  private dataList: T[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: T[] = []) {
    this.dataList = data;
  }

  totalCount(): number {
    return this.dataList.length;
  }

  getData(index: number): T {
    return this.dataList[index];
  }

  /** 全量替换数据并通知刷新 */
  replaceAll(data: T[]): void {
    this.dataList = data;
    for (const listener of this.listeners) {
      listener.onDataReloaded();
    }
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
}
