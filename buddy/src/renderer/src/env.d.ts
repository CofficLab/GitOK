/// <reference types="vite/client" />

/**
 * 声明 .vue 文件模块
 */
declare module '*.vue' {
  import type { DefineComponent } from 'vue';
  const component: DefineComponent<{}, {}, any>;
  export default component;
}

/**
 * 导入全局类型定义
 */
import type { ElectronAPI } from '@/types';

declare global {
  interface Window {
    electron: ElectronAPI;
  }
}

interface WindowConfig {
  showTrafficLights: boolean;
}

interface IpcRenderer {
  send: (channel: string, ...args: any[]) => void;
  invoke: (channel: string, ...args: any[]) => Promise<any>;
  on: (channel: string, listener: (...args: any[]) => void) => void;
  removeListener: (channel: string, listener: (...args: any[]) => void) => void;
}

interface ElectronAPI {
  getWindowConfig: () => Promise<WindowConfig>;
  setWindowConfig: (config: Partial<WindowConfig>) => Promise<void>;
  onWindowConfigChanged: (
    callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
  ) => () => void;
  ipcRenderer: IpcRenderer;
  process: {
    versions: {
      electron: string;
      chrome: string;
      node: string;
    };
  };
  send: (channel: string, ...args: unknown[]) => void;
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;
  plugins: {
    getPluginActions: (keyword?: string) => Promise<
      Array<{
        id: string;
        title: string;
        description: string;
        icon: string;
        plugin: string;
        viewPath?: string;
      }>
    >;
    executeAction: (actionId: string) => Promise<any>;
    getActionView: (actionId: string) => Promise<{
      success: boolean;
      content?: string;
      html?: string; // 兼容旧版响应
      error?: string;
    }>;
    getAllPlugins: () => Promise<any>;
    getLocalPlugins: () => Promise<any>;
    getInstalledPlugins: () => Promise<any>;
    views: {
      create: (
        viewId: string,
        url: string
      ) => Promise<{
        x: number;
        y: number;
        width: number;
        height: number;
      } | null>;
      show: (
        viewId: string,
        bounds?: { x: number; y: number; width: number; height: number }
      ) => Promise<boolean>;
      hide: (viewId: string) => Promise<boolean>;
      destroy: (viewId: string) => Promise<boolean>;
      toggleDevTools: (viewId: string) => Promise<boolean>;
    };
  };
}

interface Window {
  electron: ElectronAPI;
  api: {
    send: (channel: string, ...args: unknown[]) => void;
    receive: (channel: string, callback: (...args: unknown[]) => void) => void;
    removeListener: (
      channel: string,
      callback: (...args: unknown[]) => void
    ) => void;
    plugin: {
      getStorePlugins: () => Promise<{
        success: boolean;
        plugins: import('@/types/plugin').StorePlugin[];
      }>;
      getDirectories: () => Promise<{
        success: boolean;
        directories: {
          user: string;
          dev: string;
        };
      }>;
      openDirectory: (directory: string) => Promise<{
        success: boolean;
        error?: string;
      }>;
    };
  };
}

declare global {
  interface Window {
    api: Window['api'];
  }
}
