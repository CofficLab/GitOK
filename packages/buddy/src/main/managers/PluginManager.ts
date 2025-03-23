/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 *
 * 插件目录结构：
 * {app.getPath('userData')}/plugins/
 * ├── plugin-1/                 # 插件目录
 * │   ├── package.json         # 插件信息
 * │   ├── main.js             # 插件主文件
 * │   └── ...                 # 其他资源
 * └── plugin-2/
 *     └── ...
 */
import { app } from 'electron';
import { join } from 'path';
import { EventEmitter } from 'events';
import fs from 'fs';
import { Logger } from '../utils/Logger';

/**
 * 插件包信息接口
 */
export interface PluginPackage {
  name: string;
  version: string;
  description: string;
  author: string;
  main: string;
  engines?: {
    gitok?: string;
  };
}

/**
 * 插件接口
 */
export interface Plugin {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  path: string;
  isBuiltin: boolean;
}

class PluginManager extends EventEmitter {
  private static instance: PluginManager;
  private plugins = new Map<string, Plugin>();
  private logger: Logger;

  // 插件目录
  private readonly PLUGINS_DIR = join(app.getPath('userData'), 'plugins');
  private readonly BUILTIN_PLUGINS_DIR = join(__dirname, '../../../plugins');

  private constructor() {
    super();
    this.logger = new Logger('PluginManager');
    this.logger.info('PluginManager 初始化');
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
   * 确保插件目录存在
   */
  private async ensurePluginDirs(): Promise<void> {
    try {
      // 确保用户插件目录存在
      if (!fs.existsSync(this.PLUGINS_DIR)) {
        this.logger.info(`创建插件目录: ${this.PLUGINS_DIR}`);
        await fs.promises.mkdir(this.PLUGINS_DIR, { recursive: true });
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
    if (!fs.existsSync(this.BUILTIN_PLUGINS_DIR)) {
      this.logger.info('内置插件目录不存在，跳过加载');
      return;
    }

    try {
      const entries = await fs.promises.readdir(this.BUILTIN_PLUGINS_DIR, {
        withFileTypes: true,
      });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(
            join(this.BUILTIN_PLUGINS_DIR, entry.name),
            true
          );
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
      const entries = await fs.promises.readdir(this.PLUGINS_DIR, {
        withFileTypes: true,
      });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await this.loadPlugin(join(this.PLUGINS_DIR, entry.name), false);
        }
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('加载用户插件失败', { error: errorMessage });
    }
  }

  /**
   * 加载单个插件
   */
  private async loadPlugin(
    pluginPath: string,
    isBuiltin: boolean
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
      const targetDir = join(this.PLUGINS_DIR, packageJson.name);
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
}

// 导出单例
export const pluginManager = PluginManager.getInstance();
