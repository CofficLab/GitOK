/**
 * 日志工具
 */
export class Logger {
  private tag: string;

  constructor(tag: string) {
    this.tag = tag;
  }

  info(message: string, ...args: any[]) {
    console.log(`[${this.tag}] ${message}`, ...args);
  }

  error(message: string, ...args: any[]) {
    console.error(`[${this.tag}] ${message}`, ...args);
  }

  debug(message: string, ...args: any[]) {
    console.log(`[${this.tag}:调试] ${message}`, ...args);
  }
}
