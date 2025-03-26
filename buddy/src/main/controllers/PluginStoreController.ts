/**
 * 插件商店控制器
 * 负责处理与插件商店相关的业务逻辑
 */
import { shell } from 'electron';
import { IpcResponse } from '@/types/ipc';
import { SuperPlugin } from '@/types/super_plugin';
import { pluginManager } from '../managers/PluginManager';
import { logger } from '../managers/LogManager';
import { pluginDB } from '../db/PluginDB';

export class PluginStoreController {
  private static instance: PluginStoreController;

  private constructor() {}

  public static getInstance(): PluginStoreController {
    if (!PluginStoreController.instance) {
      PluginStoreController.instance = new PluginStoreController();
    }
    return PluginStoreController.instance;
  }

  /**
   * 获取插件商店列表
   */
  public async getStorePlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    try {
      const plugins = await pluginDB.getAllPlugins();
      return { success: true, data: plugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取插件目录信息
   */
  public getDirectories(): IpcResponse<{ user: string; dev: string }> {
    try {
      const directories = pluginDB.getPluginDirectories();
      return { success: true, data: directories };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件目录信息失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取已安装的插件列表
   */
  public getPlugins(): IpcResponse<SuperPlugin[]> {
    try {
      const plugins = pluginManager.getPlugins();
      return { success: true, data: plugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 打开插件目录
   */
  public openDirectory(directory: string): IpcResponse<void> {
    try {
      shell.openPath(directory);
      return { success: true, data: undefined };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('打开插件目录失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }
}

export const pluginStoreController = PluginStoreController.getInstance();
