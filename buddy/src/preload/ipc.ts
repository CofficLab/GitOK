/**
 * 基础 IPC 通信模块
 * 提供基本的进程间通信功能
 */
import { ipcRenderer } from 'electron';
import { IpcApi } from '@/types/api-message';
import { IPC_METHODS } from '@/types/ipc-methods';

export const ipcApi: IpcApi = {
  send: (channel: string, ...args: unknown[]): void => {
    ipcRenderer.send(channel, ...args);
  },
  receive: (channel: string, callback: (...args: unknown[]) => void): void => {
    ipcRenderer.on(channel, (_, ...args) => callback(...args));
  },
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ): void => {
    ipcRenderer.removeListener(channel, callback);
  },

  openFolder: async (directory: string): Promise<void> => {
    let response = ipcApi.send(IPC_METHODS.OPEN_FOLDER, directory);

    return response;
  },
};
