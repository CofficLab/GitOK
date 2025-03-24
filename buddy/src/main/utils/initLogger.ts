/**
 * 日志系统初始化
 * 在应用启动早期初始化日志系统
 */
import { Logger, LogLevel } from './Logger';

/**
 * 初始化日志系统
 * @param isDevelopment 是否为开发环境
 */
export function initLogger(isDevelopment: boolean): void {
  // 设置日志级别
  Logger.setLogLevel(isDevelopment ? LogLevel.DEBUG : LogLevel.INFO);

  // 设置未捕获异常的处理
  process.on('uncaughtException', (error) => {
    const logger = new Logger('UncaughtException');
    logger.error('未捕获的异常', {
      message: error.message,
      stack: error.stack,
    });
  });

  // 设置未处理的Promise拒绝的处理
  process.on('unhandledRejection', (reason) => {
    const logger = new Logger('UnhandledRejection');
    logger.error('未处理的Promise拒绝', {
      reason: reason instanceof Error ? reason.message : String(reason),
    });
  });
}
