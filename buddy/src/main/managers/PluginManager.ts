/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 */
import { BaseManager } from './BaseManager';
import { PluginEntity } from '../entities/PluginEntity';
import { userPluginDB } from '../db/UserPluginDB';
import { devPluginDB } from '../db/DevPluginDB';

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
      // 只需确保插件目录存在
      await userPluginDB.ensurePluginDirs();
    } catch (error) {
      this.handleError(error, '插件系统初始化失败', true);
    }
  }

  /**
   * 加载插件模块
   * @param plugin 插件实例
   * @returns 插件模块
   */
  public async loadPluginModule(plugin: PluginEntity): Promise<any> {
    try {
      return await userPluginDB.loadPluginModule(plugin);
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

  async getPlugins(): Promise<PluginEntity[]> {
    return [...await userPluginDB.getAllPlugins(), ...await devPluginDB.getAllPlugins()];
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
