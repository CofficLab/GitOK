/**
 * 被覆盖应用相关IPC处理函数
 */
import { BrowserWindow } from 'electron';
import { BaseIPCManager } from './base';
import { appStateManager } from '../managers/AppStateManager';
import { ipcLogger as logger } from '../managers/LogManager';

export class OverlaidAppIPCManager extends BaseIPCManager {
  private static instance: OverlaidAppIPCManager;

  private constructor() {
    super('OverlaidAppIPCManager');
    this.registerHandlers();
  }

  /**
   * 获取 OverlaidAppIPCManager 实例
   */
  public static getInstance(): OverlaidAppIPCManager {
    if (!OverlaidAppIPCManager.instance) {
      OverlaidAppIPCManager.instance = new OverlaidAppIPCManager();
    }
    return OverlaidAppIPCManager.instance;
  }

  /**
   * 注册被覆盖应用相关的IPC处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册被覆盖应用相关IPC处理函数');

    // 监听被覆盖应用变化事件
    appStateManager.on('overlaid-app-changed', (app: any) => {
      // 向所有渲染进程广播被覆盖应用变化事件
      logger.debug('广播被覆盖应用变化事件', app);
      const windows = BrowserWindow.getAllWindows();
      windows.forEach((window) => {
        window.webContents.send('overlaid-app-changed', app);
      });
    });
  }
}

export const overlaidAppIPCManager = OverlaidAppIPCManager.getInstance();
