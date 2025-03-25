/**
 * 日志工具类
 * 提供日志相关的通用工具函数和日志记录功能
 */
import { SuperLogger } from '@/types/super-logger';
import log from 'electron-log';
import type { LogMessage } from 'electron-log';
import 'source-map-support/register';

// 配置日志
if (process.env.NODE_ENV === 'development') {
  // 开发环境：显示源码位置（绝对路径）
  log.transports.file.format = '[{h}:{i}:{s}] {text}';
  log.transports.console.format = '{text}';

  // 配置日志作用域格式
  log.hooks.push((message) => {
    if (message.data[0]?.['__filename']) {
      const file = message.data[0]['__filename'];
      const line = message.data[0]['__line'];
      message.scope = `[${file}:${line}]`;
      message.data = message.data.slice(1);
    }

    // 根据日志级别添加表情
    const emoji =
      message.level === 'error'
        ? '❌'
        : message.level === 'warn'
          ? '⚠️'
          : message.level === 'info'
            ? 'ℹ️ '
            : message.level === 'debug'
              ? '🔍'
              : '📝';

    // 组装最终的消息
    message.data = [
      `${emoji} ${message.scope ? `${message.scope} ` : ''}${message.data.join(' ')}`,
    ];
    return message;
  });
} else {
  // 生产环境：不显示源码位置
  log.transports.file.format = '[{h}:{i}:{s}] {text}';
  log.transports.console.format = '{text}';

  // 配置日志作用域格式
  log.hooks.push((message) => {
    // 根据日志级别添加表情
    const emoji =
      message.level === 'error'
        ? '❌'
        : message.level === 'warn'
          ? '⚠️'
          : message.level === 'info'
            ? 'ℹ️'
            : message.level === 'debug'
              ? '🔍'
              : '📝';

    // 组装最终的消息
    message.data = [`${emoji} ${message.data.join(' ')}`];
    return message;
  });
}

// 设置日志级别
log.transports.file.level = 'info';
log.transports.console.level =
  process.env.NODE_ENV === 'development' ? 'debug' : 'info';

export class LogUtil {
  /**
   * 创建一个日志记录器
   * @returns SuperLogger实例
   */
  static createLogger(): SuperLogger {
    const logWithLocation = (level: string, ...params: any[]) => {
      // 获取调用位置信息
      const error = new Error();
      const stack = error.stack?.split('\n')[3] || '';
      const match =
        stack.match(/at\s+.*\s+\((.+):(\d+):(\d+)\)/) ||
        stack.match(/at\s+(.+):(\d+):(\d+)/);

      if (process.env.NODE_ENV === 'development' && match) {
        const [, file, line] = match;
        // 将位置信息作为第一个参数传递
        log[level]({ __filename: file, __line: line }, ...params);
      } else {
        log[level](...params);
      }
    };

    return {
      error: (...params: any[]) => {
        logWithLocation('error', ...params);
      },
      warn: (...params: any[]) => {
        logWithLocation('warn', ...params);
      },
      info: (...params: any[]) => {
        logWithLocation('info', ...params);
      },
      debug: (...params: any[]) => {
        logWithLocation('debug', ...params);
      },
    };
  }
}
