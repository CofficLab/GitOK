/**
 * 简单的日志工具
 */
export class Logger {
  private prefix: string;

  constructor(name: string) {
    this.prefix = `[${name}]`;
  }

  /**
   * 打印调试信息
   */
  debug(...args: any[]): void {
    console.debug(this.prefix, ...args);
  }

  /**
   * 打印信息
   */
  info(...args: any[]): void {
    console.info(this.prefix, ...args);
  }

  /**
   * 打印警告
   */
  warn(...args: any[]): void {
    console.warn(this.prefix, ...args);
  }

  /**
   * 打印错误
   */
  error(...args: any[]): void {
    console.error(this.prefix, ...args);
  }
}
