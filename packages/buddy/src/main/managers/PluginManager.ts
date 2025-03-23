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
 * ├── builtin/               # 内置插件
 * │   ├── plugin-3/
 * │   │   └── ...
 * │   └── plugin-4/
 * │       └── ...
 * └── dev/                   # 开发中的插件
 *     ├── plugin-5/
 *     │   └── ...
 *     └── plugin-6/
 *         └── ...
 */
import { app } from 'electron';
import { join } from 'path';
import { EventEmitter } from 'events';
import fs from 'fs';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import type { Plugin, PluginPackage, StorePlugin } from '../../types';

class PluginManager extends EventEmitter {
  private static instance: PluginManager;
  private plugins: Map<string, Plugin> = new Map();
  private logger: Logger;
  private config: any;

  // 插件目录
  private pluginsDir: string;
  private builtinPluginsDir: string;
  private devPluginsDir: string;

  private constructor() {
    super();
    // 从配置文件中读取配置
    this.config = configManager.getPluginConfig();
    this.logger = new Logger('PluginManager', {
      enabled: this.config.enableLogging,
      level: this.config.logLevel,
    });

    // 初始化插件目录
    const userDataPath = app.getPath('userData');
    const appPath = app.getAppPath();
    const pluginsRootDir = join(userDataPath, 'plugins');

    this.pluginsDir = join(pluginsRootDir, 'user');
    this.builtinPluginsDir = join(pluginsRootDir, 'builtin');
    this.devPluginsDir = join(pluginsRootDir, 'dev');

    this.logger.info('PluginManager 初始化', {
      pluginsRootDir,
      pluginsDir: this.pluginsDir,
      builtinPluginsDir: this.builtinPluginsDir,
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
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('插件系统初始化失败', { error: errorMessage });
    }
  }

  /**
   * 获取插件目录信息
   */
  getPluginDirectories() {
    return {
      user: this.pluginsDir,
      builtin: this.builtinPluginsDir,
      dev: this.devPluginsDir,
    };
  }

  /**
   * 确保插件目录存在
   */
  private async ensurePluginDirs(): Promise<void> {
    try {
      const dirs = [
        this.pluginsDir, // 用户插件目录
        this.builtinPluginsDir, // 内置插件目录
        this.devPluginsDir, // 开发插件目录
      ];

      for (const dir of dirs) {
        if (!fs.existsSync(dir)) {
          this.logger.info(`创建插件目录: ${dir}`);
          await fs.promises.mkdir(dir, { recursive: true });
        }
      }

      // 如果内置插件目录为空，复制资源目录中的内置插件
      const entries = await fs.promises.readdir(this.builtinPluginsDir);
      if (entries.length === 0) {
        const resourceBuiltinDir = join(app.getAppPath(), 'resources/plugins');
        if (fs.existsSync(resourceBuiltinDir)) {
          this.logger.info('复制内置插件到插件目录');
          await this.copyDirRecursive(
            resourceBuiltinDir,
            this.builtinPluginsDir
          );
        }
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('创建插件目录失败', { error: errorMessage });
      throw error;
    }
  }

  /**
   * 加载所有插件
   */
  private async loadPlugins(): Promise<void> {
    this.logger.info('开始加载插件');

    try {
      // 加载内置插件
      await this.loadBuiltinPlugins();

      // 加载用户安装的插件
      await this.loadUserPlugins();

      // 加载开发中的插件
      await this.loadDevPlugins();

      this.logger.info(`已加载 ${this.plugins.size} 个插件`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('加载插件失败', { error: errorMessage });
      throw error;
    }
  }

  /**
   * 加载内置插件
   */
  private async loadBuiltinPlugins(): Promise<void> {
    if (!fs.existsSync(this.builtinPluginsDir)) {
      this.logger.info('内置插件目录不存在，跳过加载');
      return;
    }

    try {
      const entries = await fs.promises.readdir(this.builtinPluginsDir, {
        withFileTypes: true,
      });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(join(this.builtinPluginsDir, entry.name), true);
        }
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('加载内置插件失败', { error: errorMessage });
    }
  }

  /**
   * 加载用户安装的插件
   */
  private async loadUserPlugins(): Promise<void> {
    try {
      const entries = await fs.promises.readdir(this.pluginsDir, {
        withFileTypes: true,
      });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(join(this.pluginsDir, entry.name), false);
        }
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('加载用户插件失败', { error: errorMessage });
    }
  }

  /**
   * 加载开发中的插件
   */
  private async loadDevPlugins(): Promise<void> {
    if (!fs.existsSync(this.devPluginsDir)) {
      this.logger.info('开发插件目录不存在，跳过加载');
      return;
    }

    try {
      const entries = await fs.promises.readdir(this.devPluginsDir, {
        withFileTypes: true,
      });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(
            join(this.devPluginsDir, entry.name),
            false,
            true
          );
        }
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('加载开发插件失败', { error: errorMessage });
    }
  }

  /**
   * 加载单个插件
   */
  private async loadPlugin(
    pluginPath: string,
    isBuiltin: boolean,
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
      if (!this.validatePluginPackage(packageJson)) {
        this.logger.warn(
          `插件 ${pluginPath} 的 package.json 格式无效，跳过加载`
        );
        return;
      }

      const plugin: Plugin = {
        id: packageJson.name,
        name: packageJson.name,
        description: packageJson.description,
        version: packageJson.version,
        author: packageJson.author,
        path: pluginPath,
        isBuiltin,
        isDev,
      };

      this.plugins.set(plugin.id, plugin);
      this.logger.info(`已加载插件: ${plugin.name} v${plugin.version}`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`加载插件失败: ${pluginPath}`, { error: errorMessage });
    }
  }

  /**
   * 验证插件包信息
   */
  private validatePluginPackage(pkg: PluginPackage): boolean {
    return !!(
      pkg.name &&
      pkg.version &&
      pkg.description &&
      pkg.author &&
      pkg.main
    );
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
   * 安装插件
   * @param sourcePath 插件源路径（可以是目录或压缩包）
   */
  async installPlugin(sourcePath: string): Promise<boolean> {
    try {
      this.logger.info(`开始安装插件: ${sourcePath}`);

      // 检查插件路径是否存在
      if (!fs.existsSync(sourcePath)) {
        throw new Error(`插件路径不存在: ${sourcePath}`);
      }

      // 读取插件的package.json
      const packageJsonPath = join(sourcePath, 'package.json');
      if (!fs.existsSync(packageJsonPath)) {
        throw new Error('找不到package.json');
      }

      const packageJson = JSON.parse(
        await fs.promises.readFile(packageJsonPath, 'utf8')
      ) as PluginPackage;

      // 验证插件包信息
      if (!this.validatePluginPackage(packageJson)) {
        throw new Error('无效的插件包');
      }

      // 创建目标目录
      const targetDir = join(this.pluginsDir, packageJson.name);
      if (fs.existsSync(targetDir)) {
        throw new Error('插件已安装');
      }

      // 复制插件文件
      await this.copyDirRecursive(sourcePath, targetDir);

      // 加载插件
      await this.loadPlugin(targetDir, false);

      this.logger.info(`插件安装成功: ${packageJson.name}`);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('安装插件失败', { error: errorMessage });
      return false;
    }
  }

  /**
   * 卸载插件
   */
  async uninstallPlugin(pluginId: string): Promise<boolean> {
    try {
      this.logger.info(`开始卸载插件: ${pluginId}`);

      const plugin = this.plugins.get(pluginId);
      if (!plugin) {
        this.logger.warn(`插件不存在: ${pluginId}`);
        return false;
      }

      if (plugin.isBuiltin) {
        this.logger.warn(`内置插件不能卸载: ${pluginId}`);
        return false;
      }

      // 从插件目录删除
      await fs.promises.rm(plugin.path, { recursive: true, force: true });

      // 从内存中移除
      this.plugins.delete(pluginId);

      this.logger.info(`插件已卸载: ${pluginId}`);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`卸载插件失败: ${pluginId}`, { error: errorMessage });
      return false;
    }
  }

  /**
   * 递归复制目录
   */
  private async copyDirRecursive(src: string, dest: string): Promise<void> {
    await fs.promises.mkdir(dest, { recursive: true });
    const entries = await fs.promises.readdir(src, { withFileTypes: true });

    for (const entry of entries) {
      const srcPath = join(src, entry.name);
      const destPath = join(dest, entry.name);

      if (entry.isDirectory()) {
        await this.copyDirRecursive(srcPath, destPath);
      } else {
        await fs.promises.copyFile(srcPath, destPath);
      }
    }
  }

  /**
   * 获取插件商店列表
   */
  async getStorePlugins(): Promise<StorePlugin[]> {
    this.logger.info('获取插件商店列表');

    // 获取已安装的插件列表
    const installedPlugins = this.getPlugins();
    const installedPluginMap = new Map(installedPlugins.map((p) => [p.id, p]));

    // 获取插件目录信息
    const directories = this.getPluginDirectories();

    // 模拟的商店插件列表
    const storePlugins: StorePlugin[] = [
      {
        id: 'git-flow',
        name: 'Git Flow',
        description: '提供完整的 Git Flow 工作流支持',
        version: '1.0.0',
        author: 'GitOK Team',
        downloads: 1200,
        rating: 4.5,
        isInstalled: installedPluginMap.has('git-flow'),
        directories,
        recommendedLocation: 'user',
        currentLocation: installedPluginMap.get('git-flow')?.isDev
          ? 'dev'
          : installedPluginMap.get('git-flow')?.isBuiltin
            ? 'builtin'
            : installedPluginMap.has('git-flow')
              ? 'user'
              : undefined,
      },
      {
        id: 'commit-lint',
        name: 'Commit Lint',
        description: '检查提交信息是否符合规范',
        version: '1.0.0',
        author: 'GitOK Team',
        downloads: 800,
        rating: 4.8,
        isInstalled: installedPluginMap.has('commit-lint'),
        directories,
        recommendedLocation: 'builtin',
        currentLocation: installedPluginMap.get('commit-lint')?.isDev
          ? 'dev'
          : installedPluginMap.get('commit-lint')?.isBuiltin
            ? 'builtin'
            : installedPluginMap.has('commit-lint')
              ? 'user'
              : undefined,
      },
      {
        id: 'branch-manager',
        name: 'Branch Manager',
        description: '分支管理工具，支持批量操作',
        version: '1.0.0',
        author: 'GitOK Team',
        downloads: 600,
        rating: 4.2,
        isInstalled: installedPluginMap.has('branch-manager'),
        directories,
        recommendedLocation: 'dev',
        currentLocation: installedPluginMap.get('branch-manager')?.isDev
          ? 'dev'
          : installedPluginMap.get('branch-manager')?.isBuiltin
            ? 'builtin'
            : installedPluginMap.has('branch-manager')
              ? 'user'
              : undefined,
      },
    ];

    return storePlugins;
  }

  /**
   * 从商店安装插件
   */
  async installStorePlugin(pluginId: string): Promise<boolean> {
    this.logger.info(`开始从商店安装插件: ${pluginId}`);

    try {
      // TODO: 这里应该是从服务器下载插件包
      // 现在先模拟安装过程
      await new Promise((resolve) => setTimeout(resolve, 1000));

      // 触发插件安装事件
      this.emit('plugin-installed', pluginId);

      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`从商店安装插件失败: ${pluginId}`, {
        error: errorMessage,
      });
      return false;
    }
  }
}

// 导出单例
export const pluginManager = PluginManager.getInstance();
