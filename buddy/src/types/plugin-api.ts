/**
 * 插件系统的API接口定义
 * 包含视图管理、插件管理、动作管理和生命周期管理四个主要模块
 */

import { PluginAction } from './plugin-action';

// 视图相关类型
interface ViewBounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ViewData {
  viewId: string;
  bounds?: ViewBounds;
}

// 插件视图管理接口
interface PluginViews {
  create: (viewId: string, url: string) => Promise<any>;
  show: (viewId: string, bounds?: ViewBounds) => Promise<any>;
  hide: (viewId: string) => Promise<any>;
  destroy: (viewId: string) => Promise<any>;
  toggleDevTools: (viewId: string) => Promise<any>;
  onEmbeddedViewCreated: (
    callback: (data: { viewId: string }) => void
  ) => () => void;
  onShowEmbeddedView: (callback: (data: ViewData) => void) => () => void;
  onHideEmbeddedView: (
    callback: (data: { viewId: string }) => void
  ) => () => void;
  onDestroyEmbeddedView: (
    callback: (data: { viewId: string }) => void
  ) => () => void;
}

// 插件管理接口
interface PluginManagement {
  getStorePlugins: () => Promise<any>;
  getDirectories: () => Promise<any>;
  openDirectory: (directory: string) => Promise<any>;
  createExamplePlugin: () => Promise<any>;
}

// 插件动作接口
interface PluginActions {
  getPluginActions: (keyword?: string) => Promise<PluginAction[]>;
  executeAction: (actionId: string) => Promise<any>;
  getActionView: (actionId: string) => Promise<any>;
}

// 插件生命周期管理接口
interface PluginLifecycle {
  getAllPlugins: () => Promise<any>;
  getLocalPlugins: () => Promise<any>;
  getInstalledPlugins: () => Promise<any>;
  installPlugin: (pluginPath: string) => Promise<any>;
  uninstallPlugin: (pluginId: string) => Promise<any>;
}

export interface PluginAPi {
  views: PluginViews;
  management: PluginManagement;
  actions: PluginActions;
  lifecycle: PluginLifecycle;
}
