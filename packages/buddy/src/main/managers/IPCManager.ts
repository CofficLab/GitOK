/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { ipcMain } from 'electron';
import { EventEmitter } from 'events';
import { configManager } from './ConfigManager';
import { commandKeyManager } from './CommandKeyManager';
import { Logger } from '../utils/Logger';
import { pluginManager } from './PluginManager';
import { shell } from 'electron';
import { join } from 'path';
import { app } from 'electron';

class IPCManager extends EventEmitter {
  private static instance: IPCManager;
  private configManager = configManager;
  private commandKeyManager = commandKeyManager;
  private logger: Logger;

  private constructor() {
    super();
    // 从配置文件中读取日志配置
    const config = this.configManager.getConfig().ipc || {};
    this.logger = new Logger('IPCManager', {
      enabled: config.enableLogging,
      level: config.logLevel,
    });
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
    ipcMain.handle('plugin:getStorePlugins', async () => {
      this.logger.debug('处理IPC请求: plugin:getStorePlugins');
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
    ipcMain.handle('plugin:install', async (_, pluginId: string) => {
      this.logger.debug('处理IPC请求: plugin:install', { pluginId });
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
    ipcMain.handle('plugin:uninstall', async (_, pluginId: string) => {
      this.logger.debug('处理IPC请求: plugin:uninstall', { pluginId });
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

    // 获取已安装的插件列表
    ipcMain.handle('plugin:getPlugins', async () => {
      this.logger.debug('处理IPC请求: plugin:getPlugins');
      try {
        const plugins = pluginManager.getPlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 打开插件目录
    ipcMain.handle('plugin:openDirectory', async (_, directory: string) => {
      try {
        // 如果是相对路径，则转换为绝对路径
        const absolutePath = directory.startsWith('/')
          ? directory
          : join(app.getPath('userData'), directory);

        // 使用系统默认程序打开目录
        await shell.openPath(absolutePath);

        return {
          success: true,
        };
      } catch (error) {
        this.logger.error('Failed to open directory:', {
          error: error instanceof Error ? error.message : String(error),
        });
        return {
          success: false,
          error: '无法打开目录',
        };
      }
    });
  }
}

// 导出单例
export const ipcManager = IPCManager.getInstance();
