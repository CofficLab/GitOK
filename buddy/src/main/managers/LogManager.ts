/**
 * 日志管理器
 * 负责创建和导出各个主题的日志记录工具实例
 * 直接导出各个主题的日志记录器实例，便于使用
 */
import { LogUtil } from '../utils/LogUtil';

/**
 * 创建日志记录器
 * @param topic 日志主题
 * @param options 日志配置选项
 * @returns 日志记录器实例
 */
export function createLogger(topic: string, options = {}) {
  return LogUtil.createLogger(topic, options);
}

/**
 * 获取日志文件的存储路径
 */
export function getLogPath(): string {
  return LogUtil.getLogPath();
}

// 导出预定义主题的日志记录器实例

export const appLogger = createLogger('app');
export const mainLogger = createLogger('main');
export const rendererLogger = createLogger('renderer');
export const ipcLogger = createLogger('ipc');
export const databaseLogger = createLogger('database');
export const networkLogger = createLogger('network');
export const fileLogger = createLogger('file');
export const errorLogger = createLogger('error');
export const configLogger = createLogger('config');
export const commandLogger = createLogger('command');
export const uiLogger = createLogger('ui');
export const pluginLogger = createLogger('plugin');
export const actionLogger = createLogger('action');
export const pluginViewLogger = createLogger('plugin-view');
export const windowLogger = createLogger('window');
export const pluginStoreLogger = createLogger('plugin-store');
