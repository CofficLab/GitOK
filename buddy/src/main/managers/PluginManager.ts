/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 *
 * 插件目录结构：
 * {app.getPath('userData')}/plugins/
 * ├── user/                    # 用户安装的插件
 * │   ├── plugin-1/           # 插件目录
 * │   │   ├── package.json   # 插件信息
 * │   │   ├── main.js       # 插件主文件
 * │   │   └── ...           # 其他资源
 * │   └── plugin-2/
 * │       └── ...
 * └── dev/                   # 开发中的插件
 *     ├── plugin-5/
 *     │   └── ...
 *     └── plugin-6/
 *         └── ...
 */
import { app } from 'electron';
import { join, dirname } from 'path';
import fs from 'fs';
import { configManager } from './ConfigManager';
import { BaseManager } from './BaseManager';
import { PluginEntity } from '../entities/PluginEntity';
import { pluginLogger as logger } from './LogManager';
import { pluginDB } from '../db/PluginDB';

class PluginManager extends BaseManager {
  private static instance: PluginManager;
  private plugins: Map<string, PluginEntity> = new Map();

  // 插件目录
  private pluginsDir: string;
  private devPluginsDir: string;

  // 插件目录类型
  private static readonly PLUGIN_DIRS = {
    USER: 'user',
    DEV: 'dev',
  } as const;

  private constructor() {
    const config = configManager.getPluginConfig();
    super({
      name: 'PluginManager',
      enableLogging: config.enableLogging,
      logLevel: config.logLevel,
    });

    // 初始化插件目录
    const userDataPath = app.getPath('userData');
    const pluginsRootDir = join(userDataPath, 'plugins');

    // 计算项目根目录：从当前文件位置向上查找，直到找到包含 package.json 的目录
    let workspaceRoot = __dirname;
    while (!fs.existsSync(join(workspaceRoot, 'package.json'))) {
      const parentDir = dirname(workspaceRoot);
      if (parentDir === workspaceRoot) {
        throw new Error('找不到项目根目录');
      }
      workspaceRoot = parentDir;
    }
    // 回退到项目根目录
    workspaceRoot = join(workspaceRoot, '..');

    this.pluginsDir = join(pluginsRootDir, PluginManager.PLUGIN_DIRS.USER);
    // 开发中的插件目录指向项目根目录的 plugins 目录
    this.devPluginsDir = join(workspaceRoot, 'plugins');

    logger.info('插件目录初始化完成', {
      pluginsRootDir,
      workspaceRoot,
      pluginsDir: this.pluginsDir,
      devPluginsDir: this.devPluginsDir,
    });
  }

  /**
   * 获取 PluginManager 实例
   */
  public static getInstance(): PluginManager {
    if (!PluginManager.instance) {
      PluginManager.instance = new PluginManager();
    }
    return PluginManager.instance;
  }

  /**
   * 初始化插件系统
   */
  async initialize(): Promise<void> {
    try {
      logger.info('开始初始化插件系统');

      // 确保插件目录存在
      await pluginDB.ensurePluginDirs();

      // 加载插件
      await this.loadPlugins();

      logger.info('插件系统初始化完成');
    } catch (error) {
      this.handleError(error, '插件系统初始化失败', true);
    }
  }

  /**
   * 获取插件目录信息
   */
  getPluginDirectories() {
    return pluginDB.getPluginDirectories();
  }

  /**
   * 加载所有插件
   */
  private async loadPlugins(): Promise<void> {
    logger.info('开始加载插件');

    try {
      // 从 PluginDB 获取所有插件
      const plugins = await pluginDB.getAllPlugins();

      // 将插件添加到管理器中
      for (const plugin of plugins) {
        this.plugins.set(plugin.id, plugin);
        logger.info(`已加载插件: ${plugin.name} v${plugin.version}`);
      }

      logger.info(`已加载 ${this.plugins.size} 个插件`);
    } catch (error) {
      this.handleError(error, '加载插件失败', true);
    }
  }

  /**
   * 清理资源
   * 在应用退出前调用，用于清理插件系统
   */
  public cleanup(): void {
    logger.info('开始清理插件系统');

    try {
      // 清理所有插件
      for (const [pluginId] of this.plugins.entries()) {
        try {
          logger.debug(`清理插件: ${pluginId}`);
          this.plugins.delete(pluginId);
        } catch (error) {
          this.handleError(error, `清理插件失败: ${pluginId}`);
        }
      }

      // 清空插件集合
      this.plugins.clear();

      // 移除所有事件监听器
      this.removeAllListeners();

      logger.info('插件系统清理完成');
    } catch (error) {
      this.handleError(error, '插件系统清理失败');
    }
  }

  /**
   * 获取所有已安装的插件
   */
  getPlugins(): PluginEntity[] {
    return Array.from(this.plugins.values());
  }

  /**
   * 获取指定插件
   */
  getPlugin(pluginId: string): PluginEntity | undefined {
    return this.plugins.get(pluginId);
  }

  /**
   * 获取插件商店列表
   */
  async getStorePlugins(): Promise<PluginEntity[]> {
    return await pluginDB.getAllPlugins();
  }

  /**
   * 加载插件模块
   * @param plugin 插件实例
   * @returns 插件模块
   */
  public async loadPluginModule(plugin: PluginEntity): Promise<any> {
    try {
      return await pluginDB.loadPluginModule(plugin);
    } catch (error: any) {
      throw new Error(
        this.handleError(
          error,
          `加载插件模块失败: ${plugin.id} (${plugin.path})`,
          false
        )
      );
    }
  }
}

// 导出单例
export const pluginManager = PluginManager.getInstance();
