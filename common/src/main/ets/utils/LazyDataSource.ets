// ============================================================
// LazyDataSource - 通用 LazyForEach 数据源
// 实现 IDataSource 接口，支持 LazyForEach 惰性渲染
// 用法: LazyForEach(new LazyDataSource(arr), (item, index) => { ... })
// ============================================================

class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private items: T[] = [];

  constructor(items: T[] = []) {
    this.items = items;
  }

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): T {
    return this.items[index];
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

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  updateItems(items: T[]): void {
    this.items = items;
    this.notifyDataReload();
  }

  getItems(): T[] {
    return this.items;
  }
}

export class LazyDataSource<T> extends BasicDataSource<T> {}
