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
