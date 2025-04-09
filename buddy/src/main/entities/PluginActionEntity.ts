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
  globalId: string;
  id: string;
  title: string;
  description: string;
  icon: string;
  pluginId: string;
  keywords: string[];
  category?: string;

  // 视图相关
  viewPath?: string;
  viewMode?: ViewMode;
  devTools?: boolean;

  // 状态信息
  status: ActionStatus = 'ready';
  error?: string;
  lastExecuteTime?: Date;
  disabled: boolean = false;

  // 验证结果
  validation?: ValidationResult;

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
    this.id = action.id;
    this.title = action.title;
    this.globalId = action.pluginId + ':' + action.id;
    this.description = action.description || '';
    this.icon = action.icon || '';
    this.pluginId = action.pluginId;
    this.keywords = action.keywords || [];
    this.category = action.category;
    this.viewPath = action.viewPath;
    this.viewMode = action.viewMode;
    this.devTools = action.devTools;

    // 执行验证
    this.validate();
  }

  /**
   * 验证动作
   */
  private validate(): void {
    const errors: string[] = [];

    // 验证必填字段
    if (!this.id) {
      errors.push('动作ID不能为空');
    }
    if (!this.title) {
      errors.push('动作标题不能为空');
    }
    if (!this.pluginId) {
      errors.push('插件ID不能为空');
    }

    // 验证视图模式
    if (this.viewMode && !['embedded', 'window'].includes(this.viewMode)) {
      errors.push('无效的视图模式');
    }

    // 设置验证结果
    this.validation = {
      isValid: errors.length === 0,
      errors,
    };

    // 如果验证失败，设置错误状态
    if (!this.validation.isValid) {
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
    this.status = status;
    this.error = error;

    if (status === 'completed' || status === 'error') {
      this.lastExecuteTime = new Date();
    }
  }

  /**
   * 禁用动作
   */
  disable(): void {
    this.disabled = true;
    this.status = 'disabled';
  }

  /**
   * 启用动作
   */
  enable(): void {
    this.disabled = false;
    this.status = 'ready';
  }

  /**
   * 开始执行
   */
  beginExecute(): void {
    if (this.disabled) {
      throw new Error('动作已禁用');
    }
    this.status = 'executing';
  }

  /**
   * 完成执行
   */
  completeExecute(): void {
    this.status = 'completed';
    this.lastExecuteTime = new Date();
  }

  /**
   * 执行出错
   */
  executeError(error: string): void {
    this.status = 'error';
    this.error = error;
    this.lastExecuteTime = new Date();
  }

  /**
   * 重置状态
   */
  reset(): void {
    this.status = 'ready';
    this.error = undefined;
  }

  /**
   * 检查动作是否可执行
   */
  canExecute(): boolean {
    return !this.disabled && this.status !== 'executing';
  }

  /**
   * 转换为普通对象
   */
  toJSON() {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      icon: this.icon,
      pluginId: this.pluginId,
      keywords: this.keywords,
      category: this.category,
      viewPath: this.viewPath,
      viewMode: this.viewMode,
      devTools: this.devTools,
      status: this.status,
      error: this.error,
      lastExecuteTime: this.lastExecuteTime,
      disabled: this.disabled,
    };
  }
}
