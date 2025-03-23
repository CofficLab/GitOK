/**
 * Electron 相关类型定义
 */
import { IpcRenderer } from './ipc';

/**
 * Electron API 接口
 */
export interface ElectronAPI {
  /**
   * IPC 渲染进程
   */
  ipcRenderer: IpcRenderer;
}

// 导出 Window 接口扩展
export {};

declare global {
  interface Window {
    api: {
      send: (channel: string, ...args: unknown[]) => void;
      receive: (
        channel: string,
        callback: (...args: unknown[]) => void
      ) => void;
      removeListener: (
        channel: string,
        callback: (...args: unknown[]) => void
      ) => void;
    };
    electron: ElectronAPI;
  }
}
