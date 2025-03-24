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
  private _id: string;
  private _name: string;
  private _description: string;
  private _version: string;
  private _author: string;
  private _main: string;

  // 路径信息
  private _path: string;
  private _type: PluginType;

  // 状态信息
  private _status: PluginStatus = 'inactive';
  private _error?: string;
  private _isLoaded: boolean = false;
  private _validation?: PluginValidation;

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
    this._id = pkg.name;
    this._name = pkg.name;
    this._description = pkg.description || '';
    this._version = pkg.version || '0.0.0';
    this._author = pkg.author || '';
    this._main = pkg.main;
    this._path = path;
    this._type = type;
  }

  // Plugin 接口实现
  get id(): string {
    return this._id;
  }
  get name(): string {
    return this._name;
  }
  get description(): string {
    return this._description;
  }
  get version(): string {
    return this._version;
  }
  get author(): string {
    return this._author;
  }
  get main(): string {
    return this._main;
  }
  get path(): string {
    return this._path;
  }
  get type(): PluginType {
    return this._type;
  }
  get validation(): PluginValidation | undefined {
    return this._validation;
  }

  // 额外的状态管理属性
  get status(): PluginStatus {
    return this._status;
  }
  get error(): string | undefined {
    return this._error;
  }
  get isLoaded(): boolean {
    return this._isLoaded;
  }

  /**
   * 获取插件主文件的完整路径
   */
  get mainFilePath(): string {
    return join(this._path, this._main);
  }

  /**
   * 获取插件的 package.json 路径
   */
  get packageJsonPath(): string {
    return join(this._path, 'package.json');
  }

  /**
   * 设置插件状态
   */
  setStatus(status: PluginStatus, error?: string): void {
    this._status = status;
    this._error = error;
  }

  /**
   * 设置插件验证状态
   */
  setValidation(validation: PluginValidation): void {
    this._validation = validation;
  }

  /**
   * 标记插件为已加载
   */
  markAsLoaded(): void {
    this._isLoaded = true;
  }

  /**
   * 禁用插件
   */
  disable(): void {
    this._status = 'disabled';
  }

  /**
   * 启用插件
   */
  enable(): void {
    if (this._status === 'disabled') {
      this._status = 'inactive';
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
      id: this._id,
      name: this._name,
      description: this._description,
      version: this._version,
      author: this._author,
      main: this._main,
      path: this._path,
      type: this._type,
      status: this._status,
      error: this._error,
      isLoaded: this._isLoaded,
      validation: this._validation,
    };
  }
}
