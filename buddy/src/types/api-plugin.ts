/**
 * 插件系统的API接口定义
 * 包含视图管理、插件管理、动作管理和生命周期管理四个主要模块
 */

import { SuperAction } from './super_action';
import { SuperPlugin } from './super_plugin';
import { IpcResponse } from './ipc-response';

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
export interface PluginViewsAPI {
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
export interface SuperPluginManagementAPI {
  getUserPlugins: () => Promise<IpcResponse<SuperPlugin[]>>;
  getDevPlugins: () => Promise<IpcResponse<SuperPlugin[]>>;
  getRemotePlugins: () => Promise<IpcResponse<SuperPlugin[]>>;
  downloadPlugin: (plugin: SuperPlugin) => Promise<IpcResponse<boolean>>;
  uninstallPlugin: (pluginId: string) => Promise<IpcResponse<boolean>>;
  getUserPluginDirectory: () => Promise<IpcResponse<string>>;
}

// 插件动作接口
export interface SuperPluginActionsAPI {
  getPluginActions: (keyword?: string) => Promise<SuperAction[]>;
  executeAction: (actionId: string) => Promise<any>;
  getActionView: (actionId: string) => Promise<any>;
}

// 插件生命周期管理接口
export interface SuperPluginLifecycleAPI {
  getAllPlugins: () => Promise<any>;
  getLocalPlugins: () => Promise<any>;
  getInstalledPlugins: () => Promise<any>;
  installPlugin: (pluginPath: string) => Promise<any>;
  uninstallPlugin: (pluginId: string) => Promise<any>;
}

export interface PluginAPi {
  views: PluginViewsAPI;
  management: SuperPluginManagementAPI;
  actions: SuperPluginActionsAPI;
  lifecycle: SuperPluginLifecycleAPI;
}
