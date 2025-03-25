/**
 * 配置相关IPC处理函数
 */
import { ipcMain } from 'electron';
import { BaseIPCManager } from './base';
import { configManager } from '../managers/ConfigManager';
import { ipcLogger as logger } from '../managers/LogManager';

export class ConfigIPCManager extends BaseIPCManager {
  private static instance: ConfigIPCManager;

  private constructor() {
    super('ConfigIPCManager');
  }

  /**
   * 获取 ConfigIPCManager 实例
   */
  public static getInstance(): ConfigIPCManager {
    if (!ConfigIPCManager.instance) {
      ConfigIPCManager.instance = new ConfigIPCManager();
    }
    return ConfigIPCManager.instance;
  }

  /**
   * 注册配置相关的IPC处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册配置相关IPC处理函数');

    // 获取窗口配置
    ipcMain.handle('getWindowConfig', () => {
      logger.debug('处理IPC请求: getWindowConfig');
      return configManager.getWindowConfig();
    });
  }
}

export const configIPCManager = ConfigIPCManager.getInstance();
