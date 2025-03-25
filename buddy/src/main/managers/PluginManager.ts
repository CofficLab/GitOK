/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 */
import { BaseManager } from './BaseManager';
import { PluginEntity } from '../entities/PluginEntity';
import { logger } from './LogManager';
import { pluginDB } from '../db/PluginDB';

class PluginManager extends BaseManager {
  private static instance: PluginManager;
  private plugins: Map<string, PluginEntity> = new Map();

  // 插件目录
  private pluginsDir: string;
  private devPluginsDir: string;

  private constructor() {
    super({
      name: 'PluginManager',
      enableLogging: true,
      logLevel: 'info',
    });

    // 从 PluginDB 获取插件目录
    const dirs = pluginDB.getPluginDirectories();
    this.pluginsDir = dirs.user;
    this.devPluginsDir = dirs.dev;

    logger.info('插件目录初始化完成', {
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
    try {
      // 移除所有事件监听器
      this.removeAllListeners();
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
