/**
 * 插件实体类
 * 用于管理插件的所有相关信息，包括基本信息、路径、状态等
 */

import { join } from 'path';
import type { PluginPackage } from '@/types/plugin-package';
import type { SuperPlugin } from '@/types/super_plugin';
import type { PluginValidation } from '@/types/plugin-validation';
import { readPackageJson, hasPackageJson } from '../utils/PackageUtils';

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

    const packageJson = await readPackageJson(pluginPath);
    const plugin = new PluginEntity(packageJson, pluginPath, type);

    // 在创建时进行验证
    const validation = plugin.validatePackage(packageJson);
    plugin.setValidation(validation);

    return plugin;
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
