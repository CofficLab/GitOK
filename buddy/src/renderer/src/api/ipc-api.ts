import { createViewArgs } from "@/types/args";
import { IPC_METHODS } from "@/types/ipc-methods";
import { IpcResponse } from "@/types/ipc-response";
import { logger } from "../utils/logger";

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const ipcApi = {
  async openFolder(folder: string): Promise<unknown> {
    return await ipc.invoke(IPC_METHODS.Open_Folder, folder);
  },

  receive: (channel: string, callback: (...args: unknown[]) => void): void => {
    logger.info('+++++ 注册IPC监听器:', channel);
    ipc.receive(channel, (_, ...args) => callback(...args));
  },

  async createView(options: createViewArgs): Promise<unknown> {
    return await ipc.invoke(IPC_METHODS.Create_View, options);
  },

  async updateViewBounds(pagePath: string, bounds: Electron.Rectangle): Promise<unknown> {
    const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Update_View_Bounds, pagePath, bounds);
    if (response.success) {
      return response.data;
    } else {
      throw new Error(response.error);
    }
  },

  async upsertView(pagePath: string, bounds: Electron.Rectangle): Promise<unknown> {
    const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Upsert_View, pagePath, bounds);
    if (response.success) {
      return response.data;
    } else {
      throw new Error(response.error);
    }
  },

  async destroyView(pagePath: string): Promise<unknown> {
    const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Destroy_View, pagePath);

    if (response.success) {
      return response.data;
    } else {
      throw new Error(response.error);
    }
  },

  async destroyPluginViews(): Promise<unknown> {
    const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Destroy_Plugin_Views);
    if (response.success) {
      return response.data;
    } else {
      throw new Error(response.error);
    }
  },

  /**
   * 打开配置文件夹
   * 先获取配置文件夹路径，然后打开它
   */
  async openConfigFolder(): Promise<unknown> {
    const configPath = await window.electron.config.getConfigPath();
    return await this.openFolder(configPath);
  }
};