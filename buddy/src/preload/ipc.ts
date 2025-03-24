/**
 * 基础 IPC 通信模块
 * 提供基本的进程间通信功能
 */
import { ipcRenderer } from 'electron';
import { IpcApi } from '@/types/ipc-api';

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
};
