/**
 * 简单的日志记录器
 * 支持不同级别的日志输出，包含时间戳和彩色显示
 */

import log from 'electron-log/renderer';

log.info('Log from the renderer process');

// 日志级别枚举
export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
}

// 日志颜色配置
const LOG_COLORS = {
  [LogLevel.DEBUG]: '\x1b[36m', // 青色
  [LogLevel.INFO]: '\x1b[32m', // 绿色
  [LogLevel.WARN]: '\x1b[33m', // 黄色
  [LogLevel.ERROR]: '\x1b[31m', // 红色
  RESET: '\x1b[0m',
};

const electronLogger = window.electron.ui;
const showTimestamp = false;

export class Logger {
  private static instance: Logger;
  private enabled: boolean = true;
  private debugEnabled: boolean = true; // 默认开启debug日志

  private constructor() { }

  /**
   * 获取Logger单例
   */
  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  /**
   * 启用或禁用日志输出
   */
  public setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  /**
   * 启用或禁用debug日志
   */
  public setDebugEnabled(enabled: boolean): void {
    this.debugEnabled = enabled;
  }

  /**
   * 获取当前时间戳
   */
  private getTimestamp(): string {
    return new Date().toISOString();
  }

  /**
   * 格式化日志消息
   */
  private formatMessage(level: LogLevel, ...args: unknown[]): string {
    const message = args
      .map((arg) =>
        typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
      )
      .join(' ');

    if (showTimestamp) {
      return `${LOG_COLORS[level]}[${level}] ${this.getTimestamp()} - ${message}${LOG_COLORS.RESET}`;
    } else {
      return `${LOG_COLORS[level]}[${level}] ${message}${LOG_COLORS.RESET}`;
    }
  }

  /**
   * 将多个参数转换为单个字符串
   */
  private argsToString(...args: unknown[]): string {
    return args
      .map((arg) =>
        typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
      )
      .join(' ');
  }

  /**
   * 输出调试级别日志
   */
  public debug(...args: unknown[]): void {
    if (this.enabled && this.debugEnabled) {
      console.log(this.formatMessage(LogLevel.DEBUG, ...args));
      // 只在控制台显示，不发送到主进程
    }
  }

  /**
   * 输出信息级别日志
   */
  public info(...args: unknown[]): void {
    if (this.enabled) {
      console.log(this.formatMessage(LogLevel.INFO, ...args));
      electronLogger.info(this.argsToString(...args));
    }
  }

  /**
   * 输出警告级别日志
   */
  public warn(...args: unknown[]): void {
    if (this.enabled) {
      console.warn(this.formatMessage(LogLevel.WARN, ...args));
      electronLogger.warn(this.argsToString(...args));
    }
  }

  /**
   * 输出错误级别日志
   */
  public error(...args: unknown[]): void {
    if (this.enabled) {
      console.error(this.formatMessage(LogLevel.ERROR, ...args));
      electronLogger.error(this.argsToString(...args));
    }
  }
}

// 导出默认的logger实例
export const logger = Logger.getInstance();
