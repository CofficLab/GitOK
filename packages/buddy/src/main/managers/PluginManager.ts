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
import type {
  Plugin,
  PluginPackage,
  StorePlugin,
  PluginValidation,
} from '../../types';

class PluginManager extends BaseManager {
  private static instance: PluginManager;
  private plugins: Map<string, Plugin> = new Map();

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
    // 回退到项目根目录（因为 buddy 在 packages 目录下）
    workspaceRoot = join(workspaceRoot, '../..');

    this.pluginsDir = join(pluginsRootDir, PluginManager.PLUGIN_DIRS.USER);
    // 开发中的插件目录指向项目根目录的 plugins 目录
    this.devPluginsDir = join(workspaceRoot, 'plugins');

    this.logger.info('插件目录初始化完成', {
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
      this.logger.info('开始初始化插件系统');

      // 确保插件目录存在
      await this.ensurePluginDirs();

      // 加载插件
      await this.loadPlugins();

      this.logger.info('插件系统初始化完成');
    } catch (error) {
      this.handleError(error, '插件系统初始化失败', true);
    }
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
  private async ensurePluginDirs(): Promise<void> {
    try {
      const dirs = [this.pluginsDir, this.devPluginsDir];

      for (const dir of dirs) {
        if (!fs.existsSync(dir)) {
          this.logger.info(`创建插件目录: ${dir}`);
          await fs.promises.mkdir(dir, { recursive: true });
        }
      }
    } catch (error) {
      this.handleError(error, '创建插件目录失败', true);
    }
  }

  /**
   * 加载所有插件
   */
  private async loadPlugins(): Promise<void> {
    this.logger.info('开始加载插件');

    try {
      // 加载用户安装的插件
      await this.loadUserPlugins();

      // 加载开发中的插件
      await this.loadDevPlugins();

      this.logger.info(`已加载 ${this.plugins.size} 个插件`);
    } catch (error) {
      this.handleError(error, '加载插件失败', true);
    }
  }

  /**
   * 清理资源
   * 在应用退出前调用，用于清理插件系统
   */
  public cleanup(): void {
    this.logger.info('开始清理插件系统');

    try {
      // 清理所有插件
      for (const [pluginId, plugin] of this.plugins.entries()) {
        try {
          // 清除插件的 require 缓存
          const mainFilePath = join(plugin.path, 'index.js');
          if (require.cache[require.resolve(mainFilePath)]) {
            delete require.cache[require.resolve(mainFilePath)];
          }

          this.logger.debug(`清理插件: ${pluginId}`);
          this.plugins.delete(pluginId);
        } catch (error) {
          this.handleError(error, `清理插件失败: ${pluginId}`);
        }
      }

      // 清空插件集合
      this.plugins.clear();

      // 移除所有事件监听器
      this.removeAllListeners();

      this.logger.info('插件系统清理完成');
    } catch (error) {
      this.handleError(error, '插件系统清理失败');
    }
  }

  /**
   * 从指定目录加载插件
   * @param dir 插件目录
   * @param type 插件类型
   */
  private async loadPluginsFromDir(
    dir: string,
    type: 'user' | 'dev'
  ): Promise<void> {
    if (!fs.existsSync(dir)) {
      this.logger.info(`${type} 插件目录不存在，跳过加载`);
      return;
    }

    try {
      const entries = await fs.promises.readdir(dir, {
        withFileTypes: true,
      });

      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(join(dir, entry.name), type === 'dev');
        }
      }
    } catch (error) {
      this.handleError(error, `加载 ${type} 插件失败`);
    }
  }

  /**
   * 加载用户安装的插件
   */
  private async loadUserPlugins(): Promise<void> {
    await this.loadPluginsFromDir(this.pluginsDir, 'user');
  }

  /**
   * 加载开发中的插件
   */
  private async loadDevPlugins(): Promise<void> {
    await this.loadPluginsFromDir(this.devPluginsDir, 'dev');
  }

  /**
   * 加载单个插件
   */
  private async loadPlugin(
    pluginPath: string,
    isDev: boolean = false
  ): Promise<void> {
    try {
      const packageJsonPath = join(pluginPath, 'package.json');
      if (!fs.existsSync(packageJsonPath)) {
        this.logger.warn(`插件 ${pluginPath} 缺少 package.json，跳过加载`);
        return;
      }

      const packageJson = JSON.parse(
        await fs.promises.readFile(packageJsonPath, 'utf8')
      ) as PluginPackage;

      // 验证插件包信息
      const validation = this.validatePluginPackage(packageJson);
      if (!validation.isValid) {
        this.logger.warn(
          `插件 ${pluginPath} 的 package.json 格式无效，跳过加载`,
          { validation: validation.errors }
        );
        return;
      }

      // 优先使用 gitokPlugin.id 作为插件ID，其次使用包名
      const pluginId = packageJson.gitokPlugin?.id || packageJson.name;

      // 检查是否是 GitOK 插件
      if (!packageJson.gitokPlugin && isDev) {
        this.logger.warn(
          `开发中的项目 ${pluginPath} 不是 GitOK 插件（缺少 gitokPlugin 配置），跳过加载`
        );
        return;
      }

      const plugin: Plugin = {
        id: pluginId,
        name: packageJson.name,
        description: packageJson.description,
        version: packageJson.version,
        author: packageJson.author,
        path: pluginPath,
        isDev,
      };

      this.plugins.set(plugin.id, plugin);
      this.logger.info(`已加载插件: ${plugin.name} v${plugin.version}`);
    } catch (error) {
      this.handleError(error, `加载插件失败: ${pluginPath}`);
    }
  }

  /**
   * 验证插件包信息
   */
  private validatePluginPackage(pkg: PluginPackage): PluginValidation {
    const errors: string[] = [];

    // 检查基本字段
    if (!pkg.name) errors.push('缺少插件名称');
    if (!pkg.version) errors.push('缺少插件版本');
    if (!pkg.description) errors.push('缺少插件描述');
    if (!pkg.author) errors.push('缺少作者信息');
    if (!pkg.main) errors.push('缺少入口文件');

    // 检查 gitokPlugin 配置
    if (!pkg.gitokPlugin) {
      errors.push('缺少 gitokPlugin 配置');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * 获取所有已安装的插件
   */
  getPlugins(): Plugin[] {
    return Array.from(this.plugins.values());
  }

  /**
   * 获取指定插件
   */
  getPlugin(pluginId: string): Plugin | undefined {
    return this.plugins.get(pluginId);
  }

  /**
   * 从目录中读取插件信息
   */
  private async readPluginsFromDir(dir: string): Promise<StorePlugin[]> {
    if (!fs.existsSync(dir)) {
      return [];
    }

    const plugins: StorePlugin[] = [];
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });
    const directories = this.getPluginDirectories();

    for (const entry of entries) {
      if (!entry.isDirectory()) continue;

      const pluginPath = join(dir, entry.name);
      const packageJsonPath = join(pluginPath, 'package.json');

      try {
        if (!fs.existsSync(packageJsonPath)) {
          this.logger.warn(`插件 ${pluginPath} 缺少 package.json，跳过`);
          continue;
        }

        const packageJson = JSON.parse(
          await fs.promises.readFile(packageJsonPath, 'utf8')
        ) as PluginPackage;

        const validation = this.validatePluginPackage(packageJson);

        // 确定插件的当前位置
        let currentLocation: 'user' | 'dev' | undefined;
        if (dir === this.devPluginsDir) {
          currentLocation = 'dev';
        } else if (dir === this.pluginsDir) {
          currentLocation = 'user';
        }

        plugins.push({
          id: packageJson.name,
          name: packageJson.name,
          description: packageJson.description || '',
          version: packageJson.version || '',
          author: packageJson.author || '',
          directories,
          recommendedLocation: currentLocation || 'user',
          currentLocation,
          validation,
        });
      } catch (error) {
        this.handleError(error, `读取插件信息失败: ${pluginPath}`);
      }
    }

    return plugins;
  }

  /**
   * 获取插件商店列表
   */
  async getStorePlugins(): Promise<StorePlugin[]> {
    this.logger.info('获取插件商店列表');

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
      this.handleError(error, '获取插件列表失败');
      return [];
    }
  }

  /**
   * 加载插件模块
   * @param plugin 插件实例
   * @returns 插件模块
   */
  public async loadPluginModule(plugin: Plugin): Promise<any> {
    try {
      // 读取 package.json 以获取入口文件路径
      const packageJsonPath = join(plugin.path, 'package.json');
      const packageJson = JSON.parse(
        await fs.promises.readFile(packageJsonPath, 'utf8')
      ) as PluginPackage;

      // 使用 package.json 中的 main 字段作为入口文件
      const mainFilePath = join(plugin.path, packageJson.main);
      if (!fs.existsSync(mainFilePath)) {
        throw new Error(`插件入口文件不存在: ${mainFilePath}`);
      }

      // 清除缓存以确保重新加载
      delete require.cache[require.resolve(mainFilePath)];

      // 动态导入插件模块
      return require(mainFilePath);
    } catch (error) {
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
