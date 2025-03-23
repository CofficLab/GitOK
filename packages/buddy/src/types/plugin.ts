/**
 * 插件相关类型定义
 */

/**
 * 插件管理器配置
 */
export interface PluginManagerConfig {
  /**
   * 是否启用日志
   */
  enableLogging?: boolean;

  /**
   * 日志级别
   * - debug: 调试信息
   * - info: 普通信息
   * - warn: 警告信息
   * - error: 错误信息
   */
  logLevel?: 'debug' | 'info' | 'warn' | 'error';
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
 * 定义了插件的基本信息，包括名称、版本、描述等
 */
export interface PluginPackage {
  /**
   * 插件名称
   */
  name: string;

  /**
   * 插件版本
   */
  version: string;

  /**
   * 插件描述
   */
  description: string;

  /**
   * 插件作者
   */
  author: string;

  /**
   * 插件入口文件
   */
  main: string;

  /**
   * 插件兼容性要求
   */
  engines?: {
    /**
     * GitOK版本要求
     */
    gitok?: string;
  };
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
   * 下载次数
   */
  downloads: number;

  /**
   * 评分（0-5）
   */
  rating: number;

  /**
   * 是否已安装
   */
  isInstalled: boolean;
}

/**
 * 插件接口
 * 定义了已安装插件的信息和状态
 */
export interface Plugin {
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
   * 插件安装路径
   */
  path: string;

  /**
   * 是否为内置插件
   */
  isBuiltin: boolean;
}
