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
import { remotePluginDB } from '../db/RemotePluginDB';
import { packageDownloaderDB } from '../db/PackageDownloaderDB';
import * as fs from 'fs';
import * as path from 'path';

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
   * 获取远程插件列表
   * 使用RemotePluginDB服务获取数据
   */
  public async getRemotePlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    try {
      const plugins = await remotePluginDB.getRemotePlugins();
      return { success: true, data: plugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取远程插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 下载并安装插件
   * 使用PackageDownloaderDB服务处理下载和解压
   */
  public async downloadPlugin(
    plugin: SuperPlugin
  ): Promise<IpcResponse<boolean>> {
    try {
      if (!plugin.npmPackage) {
        logger.error('下载失败：缺少NPM包名称', { plugin });
        return {
          success: false,
          error: '缺少NPM包名称',
        };
      }

      // 获取用户插件目录
      const directories = pluginDB.getPluginDirectories();
      const userPluginDir = directories.user;

      // 确保目录存在
      if (!fs.existsSync(userPluginDir)) {
        fs.mkdirSync(userPluginDir, { recursive: true });
      }

      // 使用插件ID或干净的包名作为目录名（而不是原始包名）
      // 这样可以避免@scope/name形式的包名导致的路径问题
      const safePluginId = plugin.id.replace(/[@/]/g, '-');

      // 创建插件目录
      const pluginDir = path.join(userPluginDir, safePluginId);
      if (!fs.existsSync(pluginDir)) {
        fs.mkdirSync(pluginDir, { recursive: true });
      }

      logger.info(`开始下载插件`, {
        pluginName: plugin.name,
        pluginId: plugin.id,
        safePluginId,
        npmPackage: plugin.npmPackage,
        pluginDir,
      });

      try {
        // 使用包下载服务下载并解压插件
        await packageDownloaderDB.downloadAndExtractPackage(
          plugin.npmPackage,
          pluginDir
        );

        // 重新扫描插件目录
        await pluginDB.getAllPlugins();

        logger.info(`插件 ${plugin.name} 安装成功`);
        return { success: true, data: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('下载插件过程中出错', {
          error: errorMessage,
          pluginName: plugin.name,
          pluginId: plugin.id,
          npmPackage: plugin.npmPackage,
        });
        return { success: false, error: errorMessage };
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('下载插件初始化失败', {
        error: errorMessage,
        pluginName: plugin.name,
        pluginId: plugin.id,
        npmPackage: plugin.npmPackage,
      });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取插件目录信息
   */
  public getDirectories(): IpcResponse<{ user: string }> {
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
  public async getPlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    try {
      const plugins = await pluginManager.getPlugins();
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

  /**
   * 卸载插件
   * @param pluginId 要卸载的插件ID
   */
  public async uninstallPlugin(
    pluginId: string
  ): Promise<IpcResponse<boolean>> {
    try {
      logger.info(`准备卸载插件: ${pluginId}`);

      // 获取插件实例
      const plugin = await pluginDB.find(pluginId);
      if (!plugin) {
        logger.error(`卸载插件失败: 找不到插件 ${pluginId}`);
        return {
          success: false,
          error: `找不到插件: ${pluginId}`,
        };
      }

      // 只允许卸载用户安装的插件，不能卸载开发中的插件
      if (plugin.type !== 'user') {
        logger.error(`卸载插件失败: 无法卸载开发中的插件 ${pluginId}`);
        return {
          success: false,
          error: '无法卸载开发中的插件',
        };
      }

      // 获取插件目录路径
      const pluginPath = plugin.path;
      if (!pluginPath || !fs.existsSync(pluginPath)) {
        logger.error(`卸载插件失败: 插件目录不存在 ${pluginPath}`);
        return {
          success: false,
          error: '插件目录不存在',
        };
      }

      logger.info(`删除插件目录: ${pluginPath}`);

      // 删除插件目录
      fs.rmdirSync(pluginPath, { recursive: true });

      logger.info(`插件 ${pluginId} 卸载成功`);
      return { success: true, data: true };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`卸载插件失败: ${errorMessage}`, { pluginId });
      return {
        success: false,
        error: `卸载插件失败: ${errorMessage}`,
      };
    }
  }
}

export const pluginStoreController = PluginStoreController.getInstance();
