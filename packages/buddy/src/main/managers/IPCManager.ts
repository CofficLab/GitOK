/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { ipcMain, BrowserWindow } from 'electron';
import { EventEmitter } from 'events';
import { ConfigManager, type WindowConfig } from './ConfigManager';
import { WindowManager } from './WindowManager';
import { CommandKeyManager } from './CommandKeyManager';
import { Logger } from '../utils/Logger';

export class IPCManager extends EventEmitter {
  private configManager: ConfigManager;
  private windowManager: WindowManager;
  private commandKeyManager: CommandKeyManager;
  private logger: Logger;

  constructor(
    configManager: ConfigManager,
    windowManager: WindowManager,
    commandKeyManager: CommandKeyManager
  ) {
    super();
    this.configManager = configManager;
    this.windowManager = windowManager;
    this.commandKeyManager = commandKeyManager;
    this.logger = new Logger('IPCManager');
    this.logger.info('IPCManager 初始化');
  }

  /**
   * 注册所有IPC处理函数
   */
  public registerHandlers(): void {
    this.logger.info('开始注册IPC处理函数');
    this.registerConfigHandlers();
    this.registerCommandKeyHandlers();
    this.logger.info('IPC处理函数注册完成');
  }

  /**
   * 注册配置相关的IPC处理函数
   */
  private registerConfigHandlers(): void {
    this.logger.debug('注册配置相关IPC处理函数');

    // 获取窗口配置
    ipcMain.handle('getWindowConfig', () => {
      this.logger.debug('处理IPC请求: getWindowConfig');
      return this.configManager.getWindowConfig();
    });

    // 保存窗口配置
    ipcMain.handle('saveWindowConfig', (_, config) => {
      this.logger.debug('处理IPC请求: saveWindowConfig', { config });
      this.configManager.setWindowConfig(config);
      return true;
    });

    // 重置窗口配置
    ipcMain.handle('resetWindowConfig', () => {
      this.logger.debug('处理IPC请求: resetWindowConfig');
      const config = this.configManager.resetWindowConfig();
      return config;
    });
  }

  /**
   * 注册Command键相关的IPC处理函数
   */
  private registerCommandKeyHandlers(): void {
    this.logger.debug('注册Command键相关IPC处理函数');

    // 检查Command键功能是否可用
    ipcMain.handle('checkCommandKey', () => {
      this.logger.debug('处理IPC请求: checkCommandKey');
      return process.platform === 'darwin';
    });

    // 检查Command键监听器状态
    ipcMain.handle('isCommandKeyEnabled', () => {
      this.logger.debug('处理IPC请求: isCommandKeyEnabled');
      return this.commandKeyManager.isListening();
    });

    // 启用Command键监听
    ipcMain.handle('enableCommandKey', async () => {
      this.logger.debug('处理IPC请求: enableCommandKey');
      const result = await this.commandKeyManager.enableCommandKeyListener();
      return result;
    });

    // 禁用Command键监听
    ipcMain.handle('disableCommandKey', () => {
      this.logger.debug('处理IPC请求: disableCommandKey');
      const result = this.commandKeyManager.disableCommandKeyListener();
      return result;
    });
  }
}
