/**
 * 插件动作实体类
 * 用于管理插件动作的状态和行为
 */

import type { SuperAction } from '@/types/super_action';

/**
 * 动作状态
 * - ready: 就绪，可以执行
 * - executing: 执行中
 * - completed: 执行完成
 * - error: 执行出错
 * - disabled: 已禁用
 */
export type ActionStatus =
  | 'ready'
  | 'executing'
  | 'completed'
  | 'error'
  | 'disabled';

/**
 * 动作视图模式
 */
export type ViewMode = 'embedded' | 'window';

/**
 * 验证结果
 */
export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * 插件动作实体类
 */
export class PluginActionEntity implements SuperAction {
  // 基本信息
  private _id: string;
  private _title: string;
  private _description: string;
  private _icon: string;
  private _pluginId: string;
  private _keywords: string[];
  private _category?: string;

  // 视图相关
  private _viewPath?: string;
  private _viewMode?: ViewMode;
  private _devTools?: boolean;

  // 状态信息
  private _status: ActionStatus = 'ready';
  private _error?: string;
  private _lastExecuteTime?: Date;
  private _disabled: boolean = false;

  // 验证结果
  private _validation?: ValidationResult;

  /**
   * 构造函数
   */
  constructor(action: {
    id: string;
    title: string;
    description?: string;
    icon?: string;
    pluginId: string;
    keywords?: string[];
    category?: string;
    viewPath?: string;
    viewMode?: ViewMode;
    devTools?: boolean;
  }) {
    this._id = action.id;
    this._title = action.title;
    this._description = action.description || '';
    this._icon = action.icon || '';
    this._pluginId = action.pluginId;
    this._keywords = action.keywords || [];
    this._category = action.category;
    this._viewPath = action.viewPath;
    this._viewMode = action.viewMode;
    this._devTools = action.devTools;

    // 执行验证
    this.validate();
  }

  // SuperAction 接口实现
  get id(): string {
    return this._id;
  }
  get title(): string {
    return this._title;
  }
  get description(): string {
    return this._description;
  }
  get icon(): string {
    return this._icon;
  }
  get pluginId(): string {
    return this._pluginId;
  }
  get keywords(): string[] {
    return this._keywords;
  }
  get category(): string | undefined {
    return this._category;
  }
  get viewPath(): string | undefined {
    return this._viewPath;
  }
  get viewMode(): ViewMode | undefined {
    return this._viewMode;
  }
  get devTools(): boolean | undefined {
    return this._devTools;
  }

  // 状态管理属性
  get status(): ActionStatus {
    return this._status;
  }
  get error(): string | undefined {
    return this._error;
  }
  get lastExecuteTime(): Date | undefined {
    return this._lastExecuteTime;
  }
  get isDisabled(): boolean {
    return this._disabled;
  }

  /**
   * 获取验证结果
   */
  get validation(): ValidationResult | undefined {
    return this._validation;
  }

  /**
   * 验证动作
   */
  private validate(): void {
    const errors: string[] = [];

    // 验证必填字段
    if (!this._id) {
      errors.push('动作ID不能为空');
    }
    if (!this._title) {
      errors.push('动作标题不能为空');
    }
    if (!this._pluginId) {
      errors.push('插件ID不能为空');
    }

    // 验证ID格式
    if (this._id && !this._id.includes(':')) {
      errors.push('动作ID格式无效，应为 "pluginId:actionName"');
    }

    // 验证视图模式
    if (this._viewMode && !['embedded', 'window'].includes(this._viewMode)) {
      errors.push('无效的视图模式');
    }

    // 设置验证结果
    this._validation = {
      isValid: errors.length === 0,
      errors,
    };

    // 如果验证失败，设置错误状态
    if (!this._validation.isValid) {
      this.setStatus('error', errors.join('; '));
    }
  }

  /**
   * 静态工厂方法：从原始数据创建实例
   */
  static fromRawAction(
    action: SuperAction,
    pluginId: string
  ): PluginActionEntity {
    return new PluginActionEntity({
      ...action,
      pluginId,
      keywords: [],
    });
  }

  /**
   * 设置动作状态
   */
  setStatus(status: ActionStatus, error?: string): void {
    this._status = status;
    this._error = error;

    if (status === 'completed' || status === 'error') {
      this._lastExecuteTime = new Date();
    }
  }

  /**
   * 禁用动作
   */
  disable(): void {
    this._disabled = true;
    this._status = 'disabled';
  }

  /**
   * 启用动作
   */
  enable(): void {
    this._disabled = false;
    this._status = 'ready';
  }

  /**
   * 开始执行
   */
  beginExecute(): void {
    if (this._disabled) {
      throw new Error('动作已禁用');
    }
    this._status = 'executing';
  }

  /**
   * 完成执行
   */
  completeExecute(): void {
    this._status = 'completed';
    this._lastExecuteTime = new Date();
  }

  /**
   * 执行出错
   */
  executeError(error: string): void {
    this._status = 'error';
    this._error = error;
    this._lastExecuteTime = new Date();
  }

  /**
   * 重置状态
   */
  reset(): void {
    this._status = 'ready';
    this._error = undefined;
  }

  /**
   * 检查动作是否可执行
   */
  canExecute(): boolean {
    return !this._disabled && this._status !== 'executing';
  }

  /**
   * 匹配关键词
   * @param keyword 搜索关键词
   */
  matchKeyword(keyword: string): boolean {
    if (!keyword) return true;

    const searchText = keyword.toLowerCase();
    return (
      this._title.toLowerCase().includes(searchText) ||
      this._description.toLowerCase().includes(searchText) ||
      this._keywords.some((k) => k.toLowerCase().includes(searchText))
    );
  }

  /**
   * 转换为普通对象
   */
  toJSON() {
    return {
      id: this._id,
      title: this._title,
      description: this._description,
      icon: this._icon,
      pluginId: this._pluginId,
      keywords: this._keywords,
      category: this._category,
      viewPath: this._viewPath,
      viewMode: this._viewMode,
      devTools: this._devTools,
      status: this._status,
      error: this._error,
      lastExecuteTime: this._lastExecuteTime,
      disabled: this._disabled,
    };
  }
}
