/**
 * 类型定义导出文件
 *
 * 设计思路：
 * 1. 集中导出所有类型定义
 * 2. 按照功能模块组织导出
 * 3. 提供清晰的导入路径
 *
 * 主要用途：
 * - 统一导出所有类型定义
 * - 简化类型导入
 * - 提供类型使用的入口点
 */

// 基础类型
export type { BasePluginInfo, PluginValidation } from './base';

// 配置相关
export type { PluginDirectories, PluginManagerConfig } from './config';

// 插件核心
export type { Plugin, PluginPackage } from './plugin';

// 商店相关
export type { PluginLocation, StorePlugin } from './store';

// 视图相关
export type {
  ViewMode,
  ViewBounds,
  PluginAction,
  PluginViewOptions,
  WebContentOptions,
} from './view';

// 导出 Electron 相关类型
export * from './electron';
export * from './ipc';
export * from './window';
export * from './store';

// 导出插件相关类型,解决命名冲突
export * from './plugin';

// 导出插件视图相关类型
export * from './plugin-view';
