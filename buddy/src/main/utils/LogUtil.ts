/**
 * 日志工具类
 * 提供日志相关的通用工具函数和日志记录功能
 */
import electronLog from 'electron-log';
import path from 'path';
import { app } from 'electron';

const showTimestamp = false;

/**
 * 日志级别类型
 */
export type LogLevel =
  | 'error'
  | 'warn'
  | 'info'
  | 'verbose'
  | 'debug'
  | 'silly';

/**
 * 日志工具类
 * 用于创建和配置特定主题的日志记录器
 */
export class LogUtil {
  /**
   * 日志文件存储路径
   */
  private static logPath = app.getPath('logs');

  /**
   * 创建特定主题的日志记录器
   * @param topic 日志主题，用于区分不同模块的日志
   * @param options 日志配置选项
   * @returns 配置好的日志记录器实例
   */
  public static createLogger(
    topic: string,
    options: {
      /**
       * 日志文件名，默认为主题名称
       */
      fileName?: string;
      /**
       * 日志级别，默认为 'info'
       */
      level?: LogLevel;
      /**
       * 是否在控制台输出，默认为 true
       */
      console?: boolean;
      /**
       * 是否写入文件，默认为 true
       */
      file?: boolean;
    } = {}
  ) {
    const {
      fileName = `${topic}.log`,
      level = 'info',
      console = true,
      file = true,
    } = options;

    // 克隆一个新的日志实例，避免影响默认实例
    const logger = electronLog.create({ logId: topic });

    // 设置日志级别
    logger.transports.console.level = console ? level : false;
    logger.transports.file.level = file ? level : false;

    // 设置日志文件路径
    if (file) {
      logger.transports.file.resolvePath = () =>
        path.join(this.logPath, fileName);
    }

    // 设置日志格式
    if (showTimestamp) {
      const logFormat =
        '[{y}-{m}-{d} {h}:{i}:{s}.{ms}] [{level}] [' + topic + '] {text}';
      logger.transports.console.format = logFormat;
      logger.transports.file.format = logFormat;
    } else {
      const logFormat = '[{level}] [' + topic + '] {text}';
      logger.transports.console.format = logFormat;
      logger.transports.file.format = logFormat;
    }

    return logger;
  }

  /**
   * 获取日志文件的存储路径
   */
  public static getLogPath(): string {
    return this.logPath;
  }

  /**
   * 设置全局日志级别
   * @param level 日志级别
   */
  public static setGlobalLevel(level: LogLevel): void {
    electronLog.transports.console.level = level;
    electronLog.transports.file.level = level;
  }
}
