/**
 * 更新相关路由
 * 处理应用更新相关的IPC通信
 */
import { BrowserWindow } from 'electron';
import { updateManager } from '../managers/UpdateManager';
import { IpcRoute } from '../services/RouterService';

// 检查更新处理函数
const checkForUpdates = async (): Promise<void> => {
  updateManager.checkForUpdates();
};

// 导出路由配置
export const routes: IpcRoute[] = [
  {
    channel: 'update:check',
    handler: checkForUpdates,
  },
];

// 向所有窗口发送更新事件
export const sendUpdateEvent = (event: string, data: any): void => {
  BrowserWindow.getAllWindows().forEach((window) => {
    if (!window.isDestroyed()) {
      window.webContents.send('update:event', event, data);
    }
  });
};
