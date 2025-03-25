/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { BaseIPCManager } from '../router/base';
import { configIPCManager } from '../router/config';
import { commandKeyIPCManager } from '../router/command-key';
import { overlaidAppIPCManager } from '../router/overlaid-app';
import { ipcLogger as logger } from '../managers/LogManager';
import { uiLogIPCManager } from '../router/ui-log';

class IPCManager {
  private static instance: IPCManager;
  private managers: BaseIPCManager[] = [];

  private constructor() {
    // 初始化时，自动添加所有IPC管理器
    this.addManager(configIPCManager);
    this.addManager(commandKeyIPCManager);
    this.addManager(uiLogIPCManager);
    // 被覆盖应用IPC管理器在构造函数中已自行注册处理函数
    // 此处只需添加到管理器列表中，不需要手动调用registerHandlers
    this.managers.push(overlaidAppIPCManager);
  }

  /**
   * 获取IPCManager实例
   */
  public static getInstance(): IPCManager {
    if (!IPCManager.instance) {
      IPCManager.instance = new IPCManager();
    }
    return IPCManager.instance;
  }

  /**
   * 添加IPC管理器
   */
  private addManager(manager: BaseIPCManager): void {
    this.managers.push(manager);
  }

  /**
   * 注册所有IPC处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册所有IPC处理函数');

    // 依次注册各个管理器的处理函数
    this.managers.forEach((manager) => {
      if (manager !== overlaidAppIPCManager) {
        // 被覆盖应用IPC管理器已在构造函数中注册
        manager.registerHandlers();
      }
    });
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    logger.debug('清理IPC管理器资源');

    // 依次清理各个管理器的资源
    this.managers.forEach((manager) => {
      manager.cleanup();
    });
  }
}

// 导出单例
export const ipcManager = IPCManager.getInstance();
