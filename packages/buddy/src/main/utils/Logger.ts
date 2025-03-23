/**
 * 日志工具类
 * 基于electron-log的统一日志记录适配层
 */
import electronLog, { LevelOption } from 'electron-log';
import { app } from 'electron';
import path from 'path';
import fs from 'fs';

// 日志级别定义
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

/**
 * 日志配置接口
 */
export interface LoggerConfig {
  enabled?: boolean;
  level?: string;
}

/**
 * 日志记录器
 * 基于electron-log封装，保持API兼容性
 */
export class Logger {
  private module: string;
  private static initialized: boolean = false;
  private enabled: boolean = true;

  /**
   * 构造函数
   * @param module 模块名称
   * @param config 日志配置
   */
  constructor(module: string, config?: LoggerConfig) {
    this.module = module;
    this.enabled = config?.enabled ?? true;

    // 初始化配置（只在第一次创建Logger实例时执行）
    if (!Logger.initialized) {
      Logger.setupElectronLog();
    }

    // 设置日志级别
    if (config?.level) {
      Logger.setLogLevelInternal(config.level);
    }
  }

  /**
   * 设置日志配置
   */
  setConfig(config: LoggerConfig): void {
    this.enabled = config.enabled ?? true;
    if (config.level) {
      Logger.setLogLevelInternal(config.level);
    }
  }

  /**
   * 内部方法：设置日志级别
   */
  private static setLogLevelInternal(level: string): void {
    let logLevel: LevelOption;
    switch (level.toLowerCase()) {
      case 'debug':
        logLevel = 'debug';
        break;
      case 'info':
        logLevel = 'info';
        break;
      case 'warn':
        logLevel = 'warn';
        break;
      case 'error':
        logLevel = 'error';
        break;
      default:
        logLevel = 'info';
    }

    electronLog.transports.file.level = logLevel;
    electronLog.transports.console.level = logLevel;
  }

  /**
   * 设置全局日志级别
   */
  static setLogLevel(level: LogLevel | string): void {
    // 确保已初始化
    if (!Logger.initialized) {
      Logger.setupElectronLog();
    }

    // 如果传入的是 LogLevel 枚举，转换为对应的字符串
    let levelStr: string;
    if (typeof level === 'number') {
      switch (level) {
        case LogLevel.DEBUG:
          levelStr = 'debug';
          break;
        case LogLevel.INFO:
          levelStr = 'info';
          break;
        case LogLevel.WARN:
          levelStr = 'warn';
          break;
        case LogLevel.ERROR:
          levelStr = 'error';
          break;
        default:
          levelStr = 'info';
      }
    } else {
      levelStr = level;
    }

    Logger.setLogLevelInternal(levelStr);
  }

  /**
   * 设置electron-log配置
   */
  private static setupElectronLog(): void {
    if (Logger.initialized) return;

    // 配置日志文件路径
    electronLog.transports.file.resolvePathFn = () => {
      const userDataPath = app.getPath('userData');
      const logsDir = path.join(userDataPath, 'logs');

      // 确保日志目录存在
      if (!fs.existsSync(logsDir)) {
        fs.mkdirSync(logsDir, { recursive: true });
      }

      // 清理旧日志文件（保留最新的5个）
      Logger.cleanupOldLogs(logsDir, 5);

      const now = new Date();
      const dateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      return path.join(logsDir, `app-${dateStr}.log`);
    };

    // 配置日志格式
    electronLog.transports.file.format =
      '[{y}-{m}-{d} {h}:{i}:{s}.{ms}] [{level}] [{processType}] [{scope}] {text}';

    // 配置最大文件大小
    electronLog.transports.file.maxSize = 10 * 1024 * 1024; // 10MB

    // 配置控制台格式
    electronLog.transports.console.format = '[{level}] [{scope}] {text}';

    // 默认日志级别
    electronLog.transports.file.level = 'info';
    electronLog.transports.console.level = 'debug';

    Logger.initialized = true;
  }

  /**
   * 清理旧日志文件
   * @param logsDir 日志目录
   * @param maxFiles 保留的最大文件数
   */
  private static cleanupOldLogs(logsDir: string, maxFiles: number): void {
    try {
      // 获取所有日志文件
      const files = fs
        .readdirSync(logsDir)
        .filter((file) => file.startsWith('app-') && file.endsWith('.log'))
        .map((file) => ({
          name: file,
          path: path.join(logsDir, file),
          time: fs.statSync(path.join(logsDir, file)).mtime.getTime(),
        }))
        .sort((a, b) => b.time - a.time); // 按修改时间降序排序

      // 删除超过maxFiles数量的旧文件
      if (files.length > maxFiles) {
        for (let i = maxFiles; i < files.length; i++) {
          fs.unlinkSync(files[i].path);
        }
      }
    } catch (error) {
      console.error('清理旧日志文件失败:', error);
    }
  }

  /**
   * 记录调试级别日志
   */
  debug(message: string, details?: Record<string, any>): void {
    if (!this.enabled) return;
    if (details) {
      electronLog.scope(this.module).debug(message, details);
    } else {
      electronLog.scope(this.module).debug(message);
    }
  }

  /**
   * 记录信息级别日志
   */
  info(message: string, details?: Record<string, any>): void {
    if (!this.enabled) return;
    if (details) {
      electronLog.scope(this.module).info(message, details);
    } else {
      electronLog.scope(this.module).info(message);
    }
  }

  /**
   * 记录警告级别日志
   */
  warn(message: string, details?: Record<string, any>): void {
    if (!this.enabled) return;
    if (details) {
      electronLog.scope(this.module).warn(message, details);
    } else {
      electronLog.scope(this.module).warn(message);
    }
  }

  /**
   * 记录错误级别日志
   */
  error(message: string, details?: Record<string, any>): void {
    if (!this.enabled) return;
    if (details) {
      electronLog.scope(this.module).error(message, details);
    } else {
      electronLog.scope(this.module).error(message);
    }
  }

  /**
   * 启用或禁用控制台输出
   */
  static enableConsoleOutput(enable: boolean): void {
    electronLog.transports.console.level = enable
      ? electronLog.transports.file.level
      : false;
  }

  /**
   * 启用或禁用文件输出
   */
  static enableFileOutput(enable: boolean): void {
    electronLog.transports.file.level = enable
      ? electronLog.transports.console.level
      : false;
  }
}
