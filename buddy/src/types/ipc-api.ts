/**
 * 基础 IPC 通信模块的类型定义
 * 提供基本的进程间通信功能的接口
 */

export interface IpcApi {
  /**
   * 向主进程发送消息
   * @param channel 通信频道名称
   * @param args 要发送的参数
   */
  send: (channel: string, ...args: unknown[]) => void;

  /**
   * 接收来自主进程的消息
   * @param channel 通信频道名称
   * @param callback 接收到消息时的回调函数
   */
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;

  /**
   * 向主进程发送消息并等待响应
   * @param channel 通信频道名称
   * @param args 要发送的参数
   * @returns 主进程返回的响应
   */
  invoke: (channel: string, ...args: unknown[]) => Promise<unknown>;

  /**
   * 移除消息监听器
   * @param channel 通信频道名称
   * @param callback 要移除的回调函数
   */
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;
}
