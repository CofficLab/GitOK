/**
 * 插件核心类型定义
 *
 * 设计思路：
 * 1. 继承基础插件信息接口，扩展插件特定的属性
 * 2. 区分已安装插件和插件包的类型定义
 * 3. 使用严格的类型定义，确保类型安全
 *
 * 主要用途：
 * - 定义已安装插件的结构
 * - 定义插件包的结构
 * - 提供插件系统核心类型支持
 */

import { BasePluginInfo } from './base';

/**
 * 插件管理器配置
 */
export interface PluginManagerConfig {
  /**
   * 是否启用日志
   */
  enableLogging: boolean;

  /**
   * 日志级别
   * - debug: 调试信息
   * - info: 普通信息
   * - warn: 警告信息
   * - error: 错误信息
   */
  logLevel: string;

  /**
   * 插件目录信息
   */
  directories?: {
    user: string;
    dev: string;
  };
}

/**
 * 插件动作接口
 */
export interface PluginAction {
  /**
   * 动作ID
   */
  id: string;

  /**
   * 动作标题
   */
  title: string;

  /**
   * 动作描述
   */
  description?: string;

  /**
   * 动作图标
   */
  icon?: string;

  /**
   * 视图路径
   */
  viewPath?: string;

  /**
   * 视图模式
   */
  viewMode?: 'embedded' | 'window';

  /**
   * 是否启用开发者工具
   */
  devTools?: boolean;
}

/**
 * 插件信息接口
 */
export interface PluginInfo {
  /**
   * 插件ID
   */
  id: string;

  /**
   * 插件名称
   */
  name: string;

  /**
   * 插件描述
   */
  description: string;

  /**
   * 插件版本
   */
  version: string;

  /**
   * 插件作者
   */
  author: string;

  /**
   * 插件主入口
   */
  main: string;

  /**
   * 插件视图目录
   */
  viewsDir?: string;
}

/**
 * 插件包信息接口
 * 定义了插件包（package.json）中的结构
 */
export interface PluginPackage extends BasePluginInfo {
  /**
   * 插件入口文件路径
   */
  main: string;

  /**
   * GitOK 插件特定配置
   */
  gitokPlugin?: {
    /**
     * 插件ID，如果提供，将替代 name 字段作为插件标识
     */
    id?: string;

    /**
     * 其他 GitOK 插件特定配置
     */
    [key: string]: unknown;
  };

  /**
   * 插件兼容性要求
   */
  engines?: {
    /**
     * Node.js 版本要求
     */
    node?: string;

    /**
     * Electron 版本要求
     */
    electron?: string;
  };
}

/**
 * 插件目录信息
 */
export interface PluginDirectories {
  user: string; // 用户插件目录
  dev: string; // 开发插件目录
}

/**
 * 插件位置类型
 */
export type PluginLocation = 'user' | 'dev';

/**
 * 插件验证状态
 */
export interface PluginValidation {
  isValid: boolean;
  errors: string[];
}

/**
 * 插件商店中的插件信息
 * 包含了插件在商店中的额外信息，如下载量、评分等
 */
export interface StorePlugin {
  /**
   * 插件唯一标识
   */
  id: string;

  /**
   * 插件名称
   */
  name: string;

  /**
   * 插件描述
   */
  description: string;

  /**
   * 插件版本
   */
  version: string;

  /**
   * 插件作者
   */
  author: string;

  /**
   * 插件目录信息
   */
  directories: {
    user: string;
    dev: string;
  };

  /**
   * 推荐安装位置
   */
  recommendedLocation: 'user' | 'dev';

  /**
   * 当前安装位置（如果已安装）
   */
  currentLocation?: 'user' | 'dev';

  /**
   * 插件验证状态
   */
  validation?: PluginValidation;
}

/**
 * 已安装的插件接口
 * 继承基础插件信息，添加运行时相关的属性
 */
export interface Plugin extends BasePluginInfo {
  /**
   * 插件安装路径
   */
  path: string;

  /**
   * 是否为开发中的插件
   */
  isDev: boolean;
}
