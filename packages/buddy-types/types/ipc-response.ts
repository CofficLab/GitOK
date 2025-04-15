/**
 * IPC 响应的基础接口
 */
export interface IpcResponse<T> {
    success: boolean;
    error?: string;
    data?: T;
  }