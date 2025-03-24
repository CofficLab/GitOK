/**
 * Command键相关IPC处理函数
 */
import { ipcMain } from 'electron';
import { BaseIPCManager } from './base';
import { commandKeyManager } from '../managers/CommandKeyManager';
import { ipcLogger as logger } from '../managers/LogManager';

export class CommandKeyIPCManager extends BaseIPCManager {
  private static instance: CommandKeyIPCManager;

  private constructor() {
    super('CommandKeyIPCManager');
  }

  /**
   * 获取 CommandKeyIPCManager 实例
   */
  public static getInstance(): CommandKeyIPCManager {
    if (!CommandKeyIPCManager.instance) {
      CommandKeyIPCManager.instance = new CommandKeyIPCManager();
    }
    return CommandKeyIPCManager.instance;
  }

  /**
   * 注册Command键相关的IPC处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册Command键相关IPC处理函数');

    // 检查Command键功能是否可用
    ipcMain.handle('checkCommandKey', () => {
      logger.debug('处理IPC请求: checkCommandKey');
      return process.platform === 'darwin';
    });

    // 检查Command键监听器状态
    ipcMain.handle('isCommandKeyEnabled', () => {
      logger.debug('处理IPC请求: isCommandKeyEnabled');
      return commandKeyManager.isListening();
    });

    // 启用Command键监听
    ipcMain.handle('enableCommandKey', async () => {
      logger.debug('处理IPC请求: enableCommandKey');
      const result = await commandKeyManager.enableCommandKeyListener();
      return result;
    });

    // 禁用Command键监听
    ipcMain.handle('disableCommandKey', () => {
      logger.debug('处理IPC请求: disableCommandKey');
      const result = commandKeyManager.disableCommandKeyListener();
      return result;
    });
  }
}

export const commandKeyIPCManager = CommandKeyIPCManager.getInstance();
