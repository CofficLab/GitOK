/**
 * 插件视图相关的类型定义
 */

import { ViewMode } from "./super-action.js";

// 视图边界
export interface ViewBounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

// 视图选项
export interface PluginViewOptions {
  viewId: string;
  url: string;
  viewMode?: ViewMode;
  bounds?: ViewBounds;
}

// Web 内容选项
export interface WebContentOptions {
  preload: string;
  sandbox: boolean;
  contextIsolation: boolean;
  nodeIntegration: boolean;
  webSecurity: boolean;
  devTools: boolean;
}

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
