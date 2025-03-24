/**
 * 插件商店相关IPC处理函数
 */
import { ipcMain, shell } from 'electron';
import { BaseIPCManager } from './base';
import { pluginManager } from '../managers/PluginManager';
import { pluginStoreLogger as logger } from '../managers/LogManager';

export class PluginStoreIPCManager extends BaseIPCManager {
  private static instance: PluginStoreIPCManager;

  private constructor() {
    super('PluginStoreIPCManager');
  }

  /**
   * 获取 PluginStoreIPCManager 实例
   */
  public static getInstance(): PluginStoreIPCManager {
    if (!PluginStoreIPCManager.instance) {
      PluginStoreIPCManager.instance = new PluginStoreIPCManager();
    }
    return PluginStoreIPCManager.instance;
  }

  /**
   * 注册插件商店相关的IPC处理函数
   */
  public registerHandlers(): void {
    logger.debug('注册插件商店相关IPC处理函数');

    // 获取插件商店列表
    ipcMain.handle('plugin:getStorePlugins', async () => {
      logger.debug('处理IPC请求: plugin:getStorePlugins');
      try {
        const plugins = await pluginManager.getStorePlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取插件目录信息
    ipcMain.handle('plugin:getDirectories', () => {
      logger.debug('处理IPC请求: plugin:getDirectories');
      try {
        const directories = pluginManager.getPluginDirectories();
        return { success: true, directories };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件目录信息失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取已安装的插件列表
    ipcMain.handle('plugin:getPlugins', async () => {
      logger.debug('处理IPC请求: plugin:getPlugins');
      try {
        const plugins = pluginManager.getPlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 打开插件目录
    ipcMain.handle('plugin:openDirectory', (_, directory: string) => {
      logger.debug('处理IPC请求: plugin:openDirectory', { directory });
      try {
        shell.openPath(directory);
        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('打开插件目录失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });
  }
}

export const pluginStoreIPCManager = PluginStoreIPCManager.getInstance();
