/**
 * 日志系统初始化
 * 在应用启动早期初始化日志系统
 */
import { app } from 'electron';
import { Logger, LogLevel } from './Logger';

/**
 * 初始化日志系统
 * @param isDevelopment 是否为开发环境
 */
export function initLogger(isDevelopment: boolean): void {
  // 设置日志级别
  Logger.setLogLevel(isDevelopment ? LogLevel.DEBUG : LogLevel.INFO);

  // 创建用于应用启动的日志记录器
  const appLogger = new Logger('App');
  appLogger.info('应用启动', {
    version: app.getVersion(),
    platform: process.platform,
    arch: process.arch,
    nodeVersion: process.versions.node,
    electronVersion: process.versions.electron,
    isDevelopment,
    userDataPath: app.getPath('userData'),
  });

  // 设置未捕获异常的处理
  process.on('uncaughtException', (error) => {
    const logger = new Logger('UncaughtException');
    logger.error('未捕获的异常', {
      message: error.message,
      stack: error.stack,
    });
  });

  // 设置未处理的Promise拒绝的处理
  process.on('unhandledRejection', (reason, promise) => {
    const logger = new Logger('UnhandledRejection');
    logger.error('未处理的Promise拒绝', {
      reason: reason instanceof Error ? reason.message : String(reason),
    });
  });
}
