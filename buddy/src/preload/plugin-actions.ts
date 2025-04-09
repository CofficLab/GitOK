/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import {
  SuperPluginActionsAPI,
} from '@/types/api-plugin';
import { ipcRenderer } from 'electron';
import { IPC_METHODS } from '../types/ipc-methods';
import { SuperAction } from '@/types/super_action';

// 插件动作相关接口
export const pluginActions: SuperPluginActionsAPI = {
  async getPluginActions(keyword = ''): Promise<SuperAction[]> {
    const response = await ipcRenderer.invoke(
      IPC_METHODS.GET_PLUGIN_ACTIONS,
      keyword
    );

    if (!response.success) {
      throw new Error(response.error);
    }

    return response.data ?? [];
  },

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
