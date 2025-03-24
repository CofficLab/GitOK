/**
 * IPC基础管理器
 * 定义IPC管理器的基础类和公共方法
 */
import { ipcMain } from 'electron';
import { BaseManager } from '../managers/BaseManager';
import { configManager } from '../managers/ConfigManager';
import { ipcLogger as logger } from '../managers/LogManager';

export abstract class BaseIPCManager extends BaseManager {
  protected constructor(name: string) {
    const config = configManager.getConfig().ipc || {};
    super({
      name,
      enableLogging: config.enableLogging,
      logLevel: config.logLevel,
    });
  }

  /**
   * 注册IPC处理函数
   */
  public abstract registerHandlers(): void;

  /**
   * 清理资源
   */
  public cleanup(): void {
    try {
      // 移除所有IPC事件监听器
      ipcMain.removeAllListeners();
    } catch (error) {
      this.handleError(error, 'IPC管理器资源清理失败');
    }
  }
}
