import { IpcRendererEvent } from 'electron';

/**
 * Command 键相关模块的类型定义
 * 包含 Command 键双击和窗口激活/隐藏等功能的接口
 */

// Command 双击切换的响应类型
interface CommandToggleResponse {
  success: boolean;
  reason?: string;
  already?: boolean;
}

export interface CommandApi {
  /**
   * 切换 Command 键双击功能的开启/关闭状态
   * @param enabled 是否启用
   */
  toggleCommandDoublePress: (
    enabled: boolean
  ) => Promise<CommandToggleResponse>;

  /**
   * 监听 Command 键双击事件
   * @param callback 回调函数
   * @returns 取消监听的函数
   */
  onCommandDoublePressed: (
    callback: (event: IpcRendererEvent) => void
  ) => () => void;

  /**
   * 监听窗口被 Command 键隐藏的事件
   * @param callback 回调函数
   * @returns 取消监听的函数
   */
  onWindowHiddenByCommand: (
    callback: (event: IpcRendererEvent) => void
  ) => () => void;

  /**
   * 监听窗口被 Command 键激活的事件
   * @param callback 回调函数
   * @returns 取消监听的函数
   */
  onWindowActivatedByCommand: (
    callback: (event: IpcRendererEvent) => void
  ) => () => void;
}
