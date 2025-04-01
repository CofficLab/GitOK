/**
 * 被覆盖应用相关IPC处理函数
 */
import { BrowserWindow } from 'electron';
import { appStateManager } from '../managers/StateManager';
import { logger } from '../managers/LogManager';
import { IpcRoute } from '../provider/RouterService';
import { IPC_METHODS } from '@/types/ipc-methods';

/**
 * 被覆盖应用相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  // 获取当前被覆盖应用信息
  {
    channel: IPC_METHODS.GET_CURRENT_APP,
    handler: () => {
      logger.debug('处理IPC请求: 获取当前被覆盖应用');
      return appStateManager.getOverlaidApp();
    },
  },
  // 手动设置被覆盖应用
  {
    channel: IPC_METHODS.SET_CURRENT_APP,
    handler: (_, appInfo: any) => {
      logger.debug('处理IPC请求: 设置当前被覆盖应用', appInfo);
      appStateManager.setOverlaidApp(appInfo);
      return { success: true };
    },
  },
];

/**
 * 初始化被覆盖应用相关的事件监听
 * 这个函数应该在主进程启动时调用
 */
export function initOverlaidAppEvents(): void {
  logger.debug('初始化被覆盖应用相关事件监听');

  // 监听被覆盖应用变化事件
  appStateManager.on('overlaid-app-changed', (app: any) => {
    // 向所有渲染进程广播被覆盖应用变化事件
    const windows = BrowserWindow.getAllWindows();
    windows.forEach((window) => {
      window.webContents.send('overlaid-app-changed', app);
    });
  });
}
