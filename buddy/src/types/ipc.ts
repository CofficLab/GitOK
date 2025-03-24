/**
 * IPC 通信相关类型定义
 */

/**
 * IPC 渲染进程接口
 */
export interface IpcRenderer {
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
 * IPC 通道名称
 */
export enum IpcChannel {
  // 插件相关
  GET_STORE_PLUGINS = 'get-store-plugins',
  INSTALL_STORE_PLUGIN = 'install-store-plugin',
  UNINSTALL_PLUGIN = 'uninstall-plugin',

  // 窗口相关
  GET_WINDOW_CONFIG = 'get-window-config',
  SET_WINDOW_CONFIG = 'set-window-config',
  WINDOW_CONFIG_CHANGED = 'window-config-changed',
}

/**
 * IPC 响应结果基础接口
 */
export interface IpcResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
}
