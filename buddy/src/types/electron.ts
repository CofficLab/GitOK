/**
 * Electron 相关类型定义
 */
import { IpcRenderer } from './ipc';

/**
 * 插件API接口
 */
export interface PluginsAPI {
  getPluginActions: (keyword?: string) => Promise<any>;
  // 根据需要添加其他插件相关方法
}

/**
 * Electron API 接口
 */
export interface ElectronAPI {
  /**
   * IPC 渲染进程
   */
  ipcRenderer: IpcRenderer;

  /**
   * 插件API
   */
  plugins: PluginsAPI;

  /**
   * 监听主进程消息
   */
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;

  /**
   * 移除消息监听
   */
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;
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
