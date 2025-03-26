/**
 * 更新功能模块
 * 提供应用更新相关的IPC通信
 */
import { ipcRenderer } from 'electron';

export const updateApi = {
  /**
   * 检查更新
   */
  checkForUpdates: (): Promise<void> => {
    return ipcRenderer.invoke('update:check');
  },

  /**
   * 监听更新事件
   * @param callback 回调函数，接收更新状态和信息
   * @returns 取消监听的函数
   */
  onUpdateEvent: (
    callback: (event: string, data: any) => void
  ): (() => void) => {
    const handler = (_: any, event: string, data: any) => callback(event, data);
    ipcRenderer.on('update:event', handler);
    return () => {
      ipcRenderer.removeListener('update:event', handler);
    };
  },
};
