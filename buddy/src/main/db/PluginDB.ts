/**
 * 插件数据库
 * 负责从磁盘读取插件信息
 */
import { app } from 'electron';
import { join, dirname } from 'path';
import fs from 'fs';
import { PluginEntity } from '../entities/PluginEntity';
import { pluginLogger as logger } from '../managers/LogManager';

export class PluginDB {
  private static instance: PluginDB;

  // 插件目录
  private pluginsDir: string;
  private devPluginsDir: string;

  // 插件目录类型
  private static readonly PLUGIN_DIRS = {
    USER: 'user',
    DEV: 'dev',
  } as const;

  private constructor() {
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

    this.pluginsDir = join(pluginsRootDir, PluginDB.PLUGIN_DIRS.USER);
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
      dev: this.devPluginsDir,
    };
  }

  /**
   * 确保插件目录存在
   */
  async ensurePluginDirs(): Promise<void> {
    try {
      const dirs = [this.pluginsDir, this.devPluginsDir];

      for (const dir of dirs) {
        if (!fs.existsSync(dir)) {
          logger.info(`创建插件目录: ${dir}`);
          await fs.promises.mkdir(dir, { recursive: true });
        }
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
        const type = dir === this.devPluginsDir ? 'dev' : 'user';
        const plugin = await PluginEntity.fromDirectory(pluginPath, type);
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
    logger.info('获取所有插件列表');

    try {
      // 从各个目录读取插件
      const [userPlugins, devPlugins] = await Promise.all([
        this.readPluginsFromDir(this.pluginsDir),
        this.readPluginsFromDir(this.devPluginsDir),
      ]);

      // 合并所有插件列表
      const allPlugins = [...userPlugins, ...devPlugins];

      // 按照插件名称排序
      allPlugins.sort((a, b) => a.name.localeCompare(b.name));

      return allPlugins;
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
}

// 导出单例
export const pluginDB = PluginDB.getInstance();
