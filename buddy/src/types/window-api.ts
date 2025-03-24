/**
 * 窗口配置模块的类型定义
 * 处理窗口相关的配置和状态管理的接口
 */

import { WindowConfig } from './window-config';

export interface WindowApi {
  /**
   * 获取当前窗口配置
   * @returns Promise<WindowConfig> 窗口配置对象
   */
  getWindowConfig: () => Promise<WindowConfig>;

  /**
   * 设置窗口配置
   * @param config 要更新的窗口配置（部分配置）
   * @returns Promise<void>
   */
  setWindowConfig: (config: Partial<WindowConfig>) => Promise<void>;

  /**
   * 监听窗口配置变化事件
   * @param callback 当窗口配置发生变化时的回调函数
   * @returns 取消监听的函数
   */
  onWindowConfigChanged: (
    callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
  ) => () => void;
}
