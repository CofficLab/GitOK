/**
 * 插件视图相关的类型定义
 */

// 视图模式
export type ViewMode = 'embedded' | 'window';

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
