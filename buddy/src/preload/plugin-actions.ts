/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import {
  SuperPluginActionsAPI,
} from '@/types/api-plugin';
import { ipcRenderer } from 'electron';
import { IPC_METHODS } from '../types/ipc-methods';

// 插件动作相关接口
export const pluginActions: SuperPluginActionsAPI = {
  executeAction: async (actionId: string, keyword: string) => {
    const response = await ipcRenderer.invoke(
      IPC_METHODS.EXECUTE_PLUGIN_ACTION,
      actionId,
      keyword
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
