
/**
 * 通用日志接口
 * 定义了基本的日志记录方法，方便未来替换具体的日志实现
 */
export interface SuperLogger {
  /**
   * 记录错误级别的日志
   */
  error(...params: any[]): void;

  /**
   * 记录警告级别的日志
   */
  warn(...params: any[]): void;

  /**
   * 记录信息级别的日志
   */
  info(...params: any[]): void;

  /**
   * 记录调试级别的日志
   */
  debug(...params: any[]): void;
}
