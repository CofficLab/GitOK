/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import { PluginAPi } from '@/types/plugin-api';
import { ipcRenderer } from 'electron';
import { IPC_METHODS } from '../types/ipc';
import { SuperAction } from '@/types/super_action';

// 插件视图相关接口
const pluginViews = {
  create: (viewId: string, url: string) =>
    ipcRenderer.invoke('create-plugin-view', { viewId, url }),

  show: (
    viewId: string,
    bounds?: { x: number; y: number; width: number; height: number }
  ) => ipcRenderer.invoke('show-plugin-view', { viewId, bounds }),

  hide: (viewId: string) => ipcRenderer.invoke('hide-plugin-view', { viewId }),

  destroy: (viewId: string) =>
    ipcRenderer.invoke('destroy-plugin-view', { viewId }),

  toggleDevTools: (viewId: string) =>
    ipcRenderer.invoke('toggle-plugin-devtools', { viewId }),

  onEmbeddedViewCreated: (callback: (data: { viewId: string }) => void) => {
    const listener = (
      _: Electron.IpcRendererEvent,
      data: { viewId: string }
    ) => {
      callback(data);
    };
    ipcRenderer.on('embedded-view-created', listener);
    return () => ipcRenderer.removeListener('embedded-view-created', listener);
  },

  onShowEmbeddedView: (
    callback: (data: {
      viewId: string;
      bounds?: { x: number; y: number; width: number; height: number };
    }) => void
  ) => {
    const listener = (_: Electron.IpcRendererEvent, data: any) => {
      callback(data);
    };
    ipcRenderer.on('show-embedded-view', listener);
    return () => ipcRenderer.removeListener('show-embedded-view', listener);
  },

  onHideEmbeddedView: (callback: (data: { viewId: string }) => void) => {
    const listener = (
      _: Electron.IpcRendererEvent,
      data: { viewId: string }
    ) => {
      callback(data);
    };
    ipcRenderer.on('hide-embedded-view', listener);
    return () => ipcRenderer.removeListener('hide-embedded-view', listener);
  },

  onDestroyEmbeddedView: (callback: (data: { viewId: string }) => void) => {
    const listener = (
      _: Electron.IpcRendererEvent,
      data: { viewId: string }
    ) => {
      callback(data);
    };
    ipcRenderer.on('destroy-embedded-view', listener);
    return () => ipcRenderer.removeListener('destroy-embedded-view', listener);
  },
};

// 插件管理相关接口
const pluginManagement = {
  getStorePlugins: () => ipcRenderer.invoke('plugin:getStorePlugins'),
  getDirectories: () => ipcRenderer.invoke('plugin:getDirectories'),
  openDirectory: (directory: string) =>
    ipcRenderer.invoke('plugin:openDirectory', directory),
  createExamplePlugin: () => ipcRenderer.invoke('plugin:createExamplePlugin'),
};

// 插件动作相关接口
const pluginActions = {
  async getPluginActions(keyword = ''): Promise<SuperAction[]> {
    const response = await ipcRenderer.invoke(
      IPC_METHODS.GET_PLUGIN_ACTIONS,
      keyword
    );
    console.log('preload: get-plugin-actions 响应:', response);

    if (!response.success) {
      throw new Error(response.error);
    }

    return response.data ?? [];
  },

  executeAction: async (actionId: string) => {
    const response = await ipcRenderer.invoke(
      IPC_METHODS.EXECUTE_PLUGIN_ACTION,
      actionId
    );

    if (!response.success) {
      throw new Error(response.error);
    }

    return response.data;
  },

  getActionView: async (actionId: string) => {
    const response = await ipcRenderer.invoke(
      IPC_METHODS.GET_ACTION_VIEW,
      actionId
    );

    if (!response.success) {
      throw new Error(response.error);
    }

    return response.data ?? '';
  },
};

// 插件生命周期管理接口
const pluginLifecycle = {
  getAllPlugins: () => ipcRenderer.invoke('get-all-plugins'),
  getLocalPlugins: () => ipcRenderer.invoke('get-local-plugins'),
  getInstalledPlugins: () => ipcRenderer.invoke('get-installed-plugins'),
  installPlugin: (pluginPath: string) =>
    ipcRenderer.invoke('install-plugin', pluginPath),
  uninstallPlugin: (pluginId: string) =>
    ipcRenderer.invoke('uninstall-plugin', pluginId),
};

export const pluginApi: PluginAPi = {
  views: pluginViews,
  management: pluginManagement,
  actions: pluginActions,
  lifecycle: pluginLifecycle,
};
