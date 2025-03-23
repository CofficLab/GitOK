/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { ipcMain, BrowserWindow } from 'electron';
import { EventEmitter } from 'events';
import { configManager } from './ConfigManager';
import { windowManager } from './WindowManager';
import { commandKeyManager } from './CommandKeyManager';
import { Logger } from '../utils/Logger';
import { pluginManager } from './PluginManager';

class IPCManager extends EventEmitter {
  private static instance: IPCManager;
  private configManager = configManager;
  private windowManager = windowManager;
  private commandKeyManager = commandKeyManager;
  private logger: Logger;

  private constructor() {
    super();
    this.logger = new Logger('IPCManager');
    this.logger.info('IPCManager 初始化');
  }

  /**
   * 获取 IPCManager 实例
   */
  public static getInstance(): IPCManager {
    if (!IPCManager.instance) {
      IPCManager.instance = new IPCManager();
    }
    return IPCManager.instance;
  }

  /**
   * 注册所有IPC处理函数
   */
  public registerHandlers(): void {
    this.logger.info('开始注册IPC处理函数');
    this.registerConfigHandlers();
    this.registerCommandKeyHandlers();
    this.registerPluginHandlers();
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

  /**
   * 注册插件相关的IPC处理函数
   */
  private registerPluginHandlers(): void {
    this.logger.debug('注册插件相关IPC处理函数');

    // 获取插件商店列表
    ipcMain.handle('get-store-plugins', async () => {
      this.logger.debug('处理IPC请求: get-store-plugins');
      try {
        const plugins = await pluginManager.getStorePlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件商店列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 从商店安装插件
    ipcMain.handle('install-store-plugin', async (_, pluginId: string) => {
      this.logger.debug('处理IPC请求: install-store-plugin', { pluginId });
      try {
        const success = await pluginManager.installStorePlugin(pluginId);
        return { success };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('安装插件失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 卸载插件
    ipcMain.handle('uninstall-plugin', async (_, pluginId: string) => {
      this.logger.debug('处理IPC请求: uninstall-plugin', { pluginId });
      try {
        const success = await pluginManager.uninstallPlugin(pluginId);
        return { success };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('卸载插件失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });
  }
}

// 导出单例
export const ipcManager = IPCManager.getInstance();
