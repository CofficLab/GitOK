/**
 * 插件实体类
 * 用于管理插件的所有相关信息，包括基本信息、路径、状态等
 */

import { join } from 'path';
import type { PluginPackage } from '@/types/plugin-package';
import type { SuperPlugin } from '@/types/super_plugin';
import type { PluginValidation } from '@/types/plugin-validation';
import { readPackageJson, hasPackageJson } from '../utils/PackageUtils';
import { NpmPackage } from '../service/NpmRegistryService';
import { logger } from '../managers/LogManager';

/**
 * 插件类型
 * - user: 用户安装的插件
 * - dev: 开发中的插件
 */
export type PluginType = 'user' | 'dev';

/**
 * 插件状态
 * - inactive: 未激活（默认状态）
 * - active: 已激活
 * - error: 出错
 * - disabled: 已禁用
 */
export type PluginStatus = 'inactive' | 'active' | 'error' | 'disabled';

/**
 * 插件实体类
 * 实现了 Plugin 接口，提供了额外的状态管理功能
 */
export class PluginEntity implements SuperPlugin {
  // 基本信息
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  main: string;

  // 路径信息
  path: string;
  type: PluginType;

  // 状态信息
  status: PluginStatus = 'inactive';
  error?: string;
  isLoaded: boolean = false;
  validation?: PluginValidation;
  isBuddyPlugin: boolean = true; // 是否是Buddy插件

  /**
   * 从目录创建插件实体
   * @param pluginPath 插件目录路径
   * @param type 插件类型
   */
  public static async fromDirectory(
    pluginPath: string,
    type: PluginType
  ): Promise<PluginEntity> {
    if (!(await hasPackageJson(pluginPath))) {
      throw new Error(`插件目录 ${pluginPath} 缺少 package.json`);
    }

    logger.info('读取插件目录', { pluginPath, type });

    const packageJson = await readPackageJson(pluginPath);
    const plugin = new PluginEntity(packageJson, pluginPath, type);

    // 在创建时进行验证
    const validation = plugin.validatePackage(packageJson);
    plugin.setValidation(validation);

    return plugin;
  }

  /**
   * 从NPM包信息创建插件实体
   * @param npmPackage NPM包信息
   * @returns 插件实体
   */
  public static fromNpmPackage(npmPackage: NpmPackage): PluginEntity {
    // 创建一个基本的PluginPackage对象
    const pkg: PluginPackage = {
      name: npmPackage.name,
      version: npmPackage.version,
      description: npmPackage.description || '',
      author: npmPackage.publisher?.username ||
        npmPackage.maintainers?.[0]?.name ||
        'unknown',
      main: 'index.js', // 默认主文件
      license: 'MIT', // 默认许可证
      dependencies: {}, // 空依赖
      devDependencies: {}, // 空开发依赖
      scripts: {}, // 空脚本
      keywords: npmPackage.keywords || [], // 关键词
      repository: npmPackage.links?.repository || '', // 仓库链接，确保是字符串类型
    };

    // 创建插件实体
    const plugin = new PluginEntity(pkg, '', 'user');

    // 使用NPM包中的名称作为显示名称（如果有的话）
    if (npmPackage.name) {
      // 格式化名称，移除作用域前缀和常见插件前缀
      plugin.name = PluginEntity.formatPluginName(npmPackage.name);
    }

    // 检查是否包含buddy-plugin关键词或是@coffic作用域下的包
    plugin.isBuddyPlugin = (
      (pkg.name.includes('buddy-plugin') ||
        pkg.name.includes('plugin-') ||
        pkg.name.startsWith('@coffic/')) &&
      // 检查关键词
      pkg.keywords &&
      Array.isArray(pkg.keywords) &&
      (pkg.keywords.includes('buddy-plugin') ||
        pkg.keywords.includes('buddy') ||
        pkg.keywords.includes('gitok') ||
        pkg.keywords.includes('plugin'))
    );

    return plugin;
  }

  /**
   * 格式化插件名称为更友好的显示名称
   * @param packageName 包名
   */
  private static formatPluginName(packageName: string): string {
    // 移除作用域前缀 (如 @coffic/)
    let name = packageName.replace(/@[^/]+\//, '');

    // 移除常见插件前缀
    const prefixes = ['plugin-', 'buddy-', 'gitok-'];
    for (const prefix of prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
        break;
      }
    }

    // 转换为标题格式 (每个单词首字母大写)
    return name
      .split('-')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  /**
   * 构造函数
   * @param pkg package.json 内容
   * @param path 插件路径
   * @param type 插件类型
   */
  constructor(pkg: PluginPackage, path: string, type: PluginType) {
    this.id = pkg.name;
    this.name = pkg.name;
    this.description = pkg.description || '';
    this.version = pkg.version || '0.0.0';
    this.author = pkg.author || '';
    this.main = pkg.main;
    this.path = path;
    this.type = type;
  }

  /**
   * 获取插件主文件的完整路径
   */
  get mainFilePath(): string {
    return join(this.path, this.main);
  }

  /**
   * 获取插件的 package.json 路径
   */
  get packageJsonPath(): string {
    return join(this.path, 'package.json');
  }

  /**
   * 设置插件状态
   */
  setStatus(status: PluginStatus, error?: string): void {
    this.status = status;
    this.error = error;
  }

  /**
   * 设置插件验证状态
   */
  setValidation(validation: PluginValidation): void {
    this.validation = validation;
  }

  /**
   * 标记插件为已加载
   */
  markAsLoaded(): void {
    this.isLoaded = true;
  }

  /**
   * 禁用插件
   */
  disable(): void {
    this.status = 'disabled';
  }

  /**
   * 启用插件
   */
  enable(): void {
    if (this.status === 'disabled') {
      this.status = 'inactive';
    }
  }

  /**
   * 验证插件包信息
   * @param pkg package.json 内容
   * @returns 验证结果
   */
  private validatePackage(pkg: PluginPackage): PluginValidation {
    const errors: string[] = [];

    // 检查基本字段
    if (!pkg.name) errors.push('缺少插件名称');
    if (!pkg.version) errors.push('缺少插件版本');
    if (!pkg.description) errors.push('缺少插件描述');
    if (!pkg.author) errors.push('缺少作者信息');
    if (!pkg.main) errors.push('缺少入口文件');

    const validation = {
      isValid: errors.length === 0,
      errors,
    };

    // 如果验证失败，设置错误状态
    if (!validation.isValid) {
      this.setStatus('error', `插件验证失败: ${errors.join(', ')}`);
    }

    return validation;
  }

  /**
   * 转换为普通对象
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      version: this.version,
      author: this.author,
      main: this.main,
      path: this.path,
      type: this.type,
      status: this.status,
      error: this.error,
      isLoaded: this.isLoaded,
      validation: this.validation,
    };
  }
}
