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

  private constructor() {
    super({
      name: 'PluginManager',
      enableLogging: true,
      logLevel: 'info',
    });
  }

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
      // 只需确保插件目录存在
      await pluginDB.ensurePluginDirs();
      logger.info('插件系统初始化完成');
    } catch (error) {
      this.handleError(error, '插件系统初始化失败', true);
    }
  }

  /**
   * 获取所有已安装的插件
   * 直接从磁盘读取，不做缓存
   */
  async getPlugins(): Promise<PluginEntity[]> {
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

  /**
   * 清理资源
   */
  public cleanup(): void {
    try {
      this.removeAllListeners();
    } catch (error) {
      this.handleError(error, '插件系统清理失败');
    }
  }
}

// 导出单例
export const pluginManager = PluginManager.getInstance();
