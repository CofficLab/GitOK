/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import { SuperPluginLifecycleAPI } from '@/types/api-plugin';
import { IPC_METHODS } from '@/types/ipc-methods';
import { ipcRenderer } from 'electron';

// 插件生命周期管理接口
export const pluginLifecycle: SuperPluginLifecycleAPI = {
  getPluginPageSourceCode: (pluginId: string) =>
    ipcRenderer.invoke(IPC_METHODS.Get_PLUGIN_PAGE_SOURCE_CODE, pluginId),
  getAllPlugins: () => ipcRenderer.invoke('get-all-plugins'),
  getLocalPlugins: () => ipcRenderer.invoke('get-local-plugins'),
  getInstalledPlugins: () => ipcRenderer.invoke('get-installed-plugins'),
  installPlugin: (pluginPath: string) =>
    ipcRenderer.invoke('install-plugin', pluginPath),
  uninstallPlugin: (pluginId: string) =>
    ipcRenderer.invoke('uninstall-plugin', pluginId),
};