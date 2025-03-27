/**
 * 插件数据库
 * 负责从磁盘读取插件信息
 */
import { app } from 'electron';
import { join } from 'path';
import fs from 'fs';
import { PluginEntity } from '../entities/PluginEntity';
import { logger } from '../managers/LogManager';

export class PluginDB {
  private static instance: PluginDB;

  // 插件目录
  private pluginsDir: string;

  private constructor() {
    // 初始化插件目录
    const userDataPath = app.getPath('userData');
    this.pluginsDir = join(userDataPath, 'plugins');

    logger.info('插件目录初始化完成', {
      pluginsDir: this.pluginsDir,
    });
  }

  /**
   * 获取 PluginDB 实例
   */
  public static getInstance(): PluginDB {
    if (!PluginDB.instance) {
      PluginDB.instance = new PluginDB();
    }
    return PluginDB.instance;
  }

  /**
   * 获取插件目录信息
   */
  getPluginDirectories() {
    return {
      user: this.pluginsDir,
    };
  }

  /**
   * 确保插件目录存在
   */
  async ensurePluginDirs(): Promise<void> {
    try {
      if (!fs.existsSync(this.pluginsDir)) {
        logger.info(`创建插件目录: ${this.pluginsDir}`);
        await fs.promises.mkdir(this.pluginsDir, { recursive: true });
      }
    } catch (error) {
      logger.error('创建插件目录失败', error);
      throw error;
    }
  }

  /**
   * 从指定目录读取插件信息
   */
  private async readPluginsFromDir(dir: string): Promise<PluginEntity[]> {
    if (!fs.existsSync(dir)) {
      return [];
    }

    const plugins: PluginEntity[] = [];
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (!entry.isDirectory()) continue;

      const pluginPath = join(dir, entry.name);

      try {
        const plugin = await PluginEntity.fromDirectory(pluginPath, 'user');
        plugins.push(plugin);
      } catch (error) {
        logger.error(`读取插件信息失败: ${pluginPath}`, error);
      }
    }

    return plugins;
  }

  /**
   * 获取所有插件列表
   */
  async getAllPlugins(): Promise<PluginEntity[]> {
    try {
      // 读取插件
      const plugins = await this.readPluginsFromDir(this.pluginsDir);

      // 按照插件名称排序
      plugins.sort((a, b) => a.name.localeCompare(b.name));

      return plugins;
    } catch (error) {
      logger.error('获取插件列表失败', error);
      return [];
    }
  }

  /**
   * 加载插件模块
   * @param plugin 插件实例
   * @returns 插件模块
   */
  public async loadPluginModule(plugin: PluginEntity): Promise<any> {
    try {
      // 使用 package.json 中的 main 字段作为入口文件
      const mainFilePath = plugin.mainFilePath;
      if (!fs.existsSync(mainFilePath)) {
        throw new Error(`插件入口文件不存在: ${mainFilePath}`);
      }

      // 清除缓存以确保重新加载
      delete require.cache[require.resolve(mainFilePath)];

      // 动态导入插件模块
      const module = require(mainFilePath);

      // 标记插件为已加载
      plugin.markAsLoaded();

      return module;
    } catch (error: any) {
      // 设置错误状态
      plugin.setStatus('error', error.message);
      throw error;
    }
  }

  /**
   * 根据插件ID查找插件
   * @param id 插件ID
   * @returns 找到的插件实例，如果未找到则返回 null
   */
  public async find(id: string): Promise<PluginEntity | null> {
    try {
      const plugins = await this.getAllPlugins();
      return plugins.find((plugin) => plugin.id === id) || null;
    } catch (error) {
      logger.error(`查找插件失败: ${id}`, error);
      return null;
    }
  }
}

// 导出单例
export const pluginDB = PluginDB.getInstance();
