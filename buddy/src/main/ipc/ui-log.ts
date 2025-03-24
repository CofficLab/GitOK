/**
 * UI 日志相关 IPC 处理函数
 */
import { ipcMain } from 'electron';
import { BaseIPCManager } from './base';
import { uiLogger as logger } from '../managers/LogManager';

export class UILogIPCManager extends BaseIPCManager {
  private static instance: UILogIPCManager;

  private constructor() {
    super('UILogIPCManager');
  }

  /**
   * 获取 UILogIPCManager 实例
   */
  public static getInstance(): UILogIPCManager {
    if (!UILogIPCManager.instance) {
      UILogIPCManager.instance = new UILogIPCManager();
    }
    return UILogIPCManager.instance;
  }

  /**
   * 注册日志相关的 IPC 处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册 UI 日志相关 IPC 处理函数');

    // 处理 info 级别的日志
    ipcMain.handle('ui:log:info', (_, message: string) => {
      logger.info(`${message}`);
    });

    // 处理 error 级别的日志
    ipcMain.handle('ui:log:error', (_, message: string) => {
      logger.error(`${message}`);
    });

    // 处理 warn 级别的日志
    ipcMain.handle('ui:log:warn', (_, message: string) => {
      logger.warn(`${message}`);
    });

    // 处理 debug 级别的日志
    ipcMain.handle('ui:log:debug', (_, message: string) => {
      logger.debug(`${message}`);
    });
  }
}

export const uiLogIPCManager = UILogIPCManager.getInstance();
