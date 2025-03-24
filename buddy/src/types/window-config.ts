/**
 * 窗口相关类型定义
 */

/**
 * 窗口配置接口
 */
export interface WindowConfig {
  /**
   * 是否显示窗口标题栏的红绿灯按钮
   */
  showTrafficLights: boolean;

  /**
   * 是否显示调试工具栏
   */
  showDebugToolbar: boolean;

  /**
   * 调试工具栏位置
   */
  debugToolbarPosition: 'right' | 'bottom' | 'left' | 'undocked';

  /**
   * 是否启用类似Spotlight的模式
   */
  spotlightMode: boolean;

  /**
   * Spotlight模式的全局快捷键
   */
  spotlightHotkey: string;

  /**
   * Spotlight模式的窗口尺寸
   */
  spotlightSize: {
    width: number;
    height: number;
  };

  /**
   * 窗口是否始终置顶
   */
  alwaysOnTop: boolean;

  /**
   * 是否跟随当前桌面/工作区
   */
  followDesktop: boolean;

  /**
   * 是否启用窗口管理器的日志输出
   */
  enableLogging?: boolean;

  /**
   * 日志级别
   */
  logLevel?: 'debug' | 'info' | 'warn' | 'error';

  // TODO: 根据实际使用情况补充具体的窗口配置项
  width?: number;
  height?: number;
  x?: number;
  y?: number;
}
