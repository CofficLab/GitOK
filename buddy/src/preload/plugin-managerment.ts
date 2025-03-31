/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import {
    SuperPluginManagementAPI,
} from '@/types/api-plugin';
import { ipcRenderer } from 'electron';
import { IpcResponse } from '@/types/ipc-response';
import { SuperPlugin } from '@/types/super_plugin';
import { IPC_METHODS } from '@/types/ipc-methods';

function isValidSuperPluginArray(data: any): data is SuperPlugin[] {
    return (
        Array.isArray(data) &&
        data.every(
            (item) =>
                typeof item === 'object' &&
                item !== null &&
                'id' in item &&
                typeof item.id === 'string'
        )
    ); // 根据SuperPlugin的实际接口添加更多校验
}

// 插件管理相关接口
export const pluginManagement: SuperPluginManagementAPI = {
    // 获取本地已安装的插件列表
    getUserPlugins: async (): Promise<IpcResponse<SuperPlugin[]>> => {
        const response = await ipcRenderer.invoke(IPC_METHODS.GET_USER_PLUGINS);
        if (!isValidSuperPluginArray(response.data)) {
            throw new Error('Invalid SuperPlugin array structure');
        }

        return response;
    },

    // 获取本地开发插件列表
    getDevPlugins: async (): Promise<IpcResponse<SuperPlugin[]>> => {
        const response = await ipcRenderer.invoke(IPC_METHODS.GET_DEV_PLUGINS);
        if (!isValidSuperPluginArray(response.data)) {
            throw new Error('Invalid SuperPlugin array structure');
        }
        return response;
    },

    // 获取远程插件列表
    getRemotePlugins: async (): Promise<IpcResponse<SuperPlugin[]>> => {
        const response = await ipcRenderer.invoke(IPC_METHODS.GET_REMOTE_PLUGINS)
        if (!isValidSuperPluginArray(response.data)) {
            throw new Error('Invalid SuperPlugin array structure');
        }

        return response;
    },

    downloadPlugin: (plugin: any) =>
        ipcRenderer.invoke(IPC_METHODS.DOWNLOAD_PLUGIN, plugin),
    uninstallPlugin: (pluginId: string) =>
        ipcRenderer.invoke(IPC_METHODS.UNINSTALL_PLUGIN, pluginId),
    getUserPluginDirectory: () =>
        ipcRenderer.invoke(IPC_METHODS.GET_PLUGIN_DIRECTORIES)
};
