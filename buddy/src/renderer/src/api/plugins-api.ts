import { IpcResponse } from "@/types/ipc-response";
import { SuperPlugin } from "@/types/super_plugin";

const electronApi = window.electron;
const pluginApi = electronApi.plugins;
const { management } = pluginApi;

export const pluginsAPI = {
  // 获取用户插件列表
  async getUserPlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    return await management.getUserPlugins();
  },

  // 获取开发插件列表
  async getDevPlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    return await management.getDevPlugins();
  },
  
  // 获取用户插件目录
  async getUserPluginDirectory(): Promise<IpcResponse<string>> {
    return await management.getUserPluginDirectory();
  },

  // 下载插件
  async downloadPlugin(plugin): Promise<IpcResponse<boolean>> {
    return await management.downloadPlugin(plugin);
  },

  // 卸载插件
  async uninstallPlugin(pluginId): Promise<IpcResponse<boolean>> {
    return await management.uninstallPlugin(pluginId);
  },

  // 获取远程插件列表
  async getRemotePlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    return await management.getRemotePlugins();
  },
};