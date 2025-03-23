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
