/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import {
  PluginViewsAPI,
} from '@/types/api-plugin';
import { IPC_METHODS } from '@/types/ipc-methods';
import { ipcRenderer } from 'electron';

// 插件视图相关接口
export const pluginViews: PluginViewsAPI = {
  create: (viewId: string, url: string) =>
    ipcRenderer.invoke(IPC_METHODS.CREATE_PLUGIN_VIEW, { viewId, url }),

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
