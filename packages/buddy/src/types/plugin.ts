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
    [key: string]: any;
  };

  /**
   * 插件兼容性要求
   */
  engines?: {
    node?: string;
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
   * 是否为开发中的插件
   */
  isDev: boolean;
}
