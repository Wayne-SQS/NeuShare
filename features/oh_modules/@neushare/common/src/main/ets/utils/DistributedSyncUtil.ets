// ============================================================
// DistributedSyncUtil - 分布式数据同步工具（预留）
// 后续通过 @kit.DistributedData 实现跨设备数据同步
// ============================================================

export interface SyncData {
  favoriteIds: string;
  historyIds: string;
}

export class DistributedSyncUtil {
  private static instance: DistributedSyncUtil;
  private onChangeCallback: ((data: SyncData) => void) | null = null;

  static getInstance(): DistributedSyncUtil {
    if (!DistributedSyncUtil.instance) {
      DistributedSyncUtil.instance = new DistributedSyncUtil();
    }
    return DistributedSyncUtil.instance;
  }

  init(sessionId: string): void {
    console.info('DistributedSync init with session: ' + sessionId);
  }

  setFavorites(ids: number[]): void {
    console.info('DistributedSync setFavorites: ' + ids.length + ' items');
  }

  setHistory(ids: number[]): void {
    console.info('DistributedSync setHistory: ' + ids.length + ' items');
  }

  getData(): SyncData | null {
    return null;
  }

  onChange(callback: (data: SyncData) => void): void {
    this.onChangeCallback = callback;
  }

  destroy(): void {
    this.onChangeCallback = null;
  }
}
