/**
 * Electron相关的类型定义
 * 包含主进程和渲染进程之间通信的接口定义
 */
import { ElectronAPI as BaseElectronAPI } from '@electron-toolkit/preload';

/**
 * 扩展的Electron API接口
 * 继承自@electron-toolkit/preload的基础接口
 */
export interface ElectronAPI extends BaseElectronAPI {
  /** Node.js进程版本信息 */
  readonly versions: Readonly<NodeJS.ProcessVersions>;

  /** 监听被覆盖应用变化的回调函数 */
  onOverlaidAppChanged: (callback: (app: any) => void) => () => void;
}

declare global {
  interface Window {
    /** Electron API */
    electron: ElectronAPI;
    /** 自定义API */
    api: unknown;
    /** 扩展的Electron API */
    electronAPI: unknown;
  }
}

/**
 * IPC 通信接口定义
 */
interface IpcRenderer {
  /**
   * 发送消息到主进程
   */
  send: (channel: string, ...args: any[]) => void;

  /**
   * 调用主进程方法并等待返回结果
   */
  invoke: (channel: string, ...args: any[]) => Promise<any>;

  /**
   * 监听主进程消息
   */
  on: (channel: string, listener: (...args: any[]) => void) => void;

  /**
   * 移除消息监听
   */
  removeListener: (channel: string, listener: (...args: any[]) => void) => void;
}

/**
 * 扩展 Window 接口，添加 electron 属性
 */
interface Window {
  electron: {
    ipcRenderer: IpcRenderer;
  };
}
