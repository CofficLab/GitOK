/**
 * 基础 IPC 通信模块
 * 提供基本的进程间通信功能
 */
import { ipcRenderer } from 'electron';
import { IpcApi } from '@/types/api-message';
import { IpcResponse } from '@/types/ipc-response';
import { logger } from '@/main/managers/LogManager';

const verbose = true;

export const ipcApi: IpcApi = {
  send: (channel: string, ...args: unknown[]): void => {
    ipcRenderer.send(channel, ...args);
  },

  receive: (channel: string, callback: (...args: unknown[]) => void): void => {
    if (verbose) {
      logger.info('====== 注册IPC监听器:', channel);
    }

    ipcRenderer.on(channel, (_, ...args) => callback(...args));
  },

  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ): void => {
    ipcRenderer.removeListener(channel, callback);
  },

  invoke: async (channel: string, ...args: unknown[]): Promise<IpcResponse<any>> => {
    //logger.info('调用IPC方法:', channel, '参数是: ', args);

    return await ipcRenderer.invoke(channel, ...args);
  },
};
