import { IPC_METHODS } from "@/types/ipc-methods";
import { logger } from "../utils/logger";

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const fileIpc = {
  async openFolder(folder: string): Promise<unknown> {
    return await ipc.invoke(IPC_METHODS.Open_Folder, folder);
  },

  receive: (channel: string, callback: (...args: unknown[]) => void): void => {
    logger.info('+++++ 注册IPC监听器:', channel);
    ipc.receive(channel, (_, ...args) => callback(...args));
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