/**
 * UI 日志模块的类型定义
 * 处理前端日志的接口
 */

export interface UILogApi {
  /**
   * 记录 info 级别的日志
   * @param message 日志消息
   */
  info: (message: string) => Promise<void>;

  /**
   * 记录 error 级别的日志
   * @param message 日志消息
   */
  error: (message: string) => Promise<void>;

  /**
   * 记录 warn 级别的日志
   * @param message 日志消息
   */
  warn: (message: string) => Promise<void>;

  /**
   * 记录 debug 级别的日志
   * @param message 日志消息
   */
  debug: (message: string) => Promise<void>;
}
