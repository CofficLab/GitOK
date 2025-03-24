/**
 * 插件视图相关类型定义
 *
 * 设计思路：
 * 1. 将所有视图相关的类型集中管理
 * 2. 使用类型别名简化视图模式的定义
 * 3. 提供完整的视图配置选项
 *
 * 主要用途：
 * - 定义插件视图的配置结构
 * - 提供视图相关的类型支持
 * - 支持插件UI的实现
 */

/**
 * 视图模式
 * 定义了插件视图的显示方式
 */
export type ViewMode = 'embedded' | 'window';

/**
 * 视图边界
 * 定义了视图窗口的位置和大小
 */
export interface ViewBounds {
  /**
   * 窗口X坐标
   */
  x: number;

  /**
   * 窗口Y坐标
   */
  y: number;

  /**
   * 窗口宽度
   */
  width: number;

  /**
   * 窗口高度
   */
  height: number;
}

/**
 * 插件视图选项
 * 定义了创建插件视图时的配置选项
 */
export interface PluginViewOptions {
  /**
   * 视图ID
   */
  viewId: string;

  /**
   * 视图URL
   */
  url: string;

  /**
   * 视图模式
   */
  viewMode?: ViewMode;

  /**
   * 视图边界
   */
  bounds?: ViewBounds;
}

/**
 * Web内容选项
 * 定义了创建Web内容时的配置选项
 */
export interface WebContentOptions {
  /**
   * 预加载脚本路径
   */
  preload: string;

  /**
   * 是否启用沙箱
   */
  sandbox: boolean;

  /**
   * 是否启用上下文隔离
   */
  contextIsolation: boolean;

  /**
   * 是否启用Node集成
   */
  nodeIntegration: boolean;

  /**
   * 是否启用Web安全
   */
  webSecurity: boolean;

  /**
   * 是否启用开发者工具
   */
  devTools: boolean;
}
