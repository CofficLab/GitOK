/**
 * 日志管理器
 * 负责创建和导出各个主题的日志记录工具实例
 * 直接导出各个主题的日志记录器实例，便于使用
 */
import { LogUtil } from '../utils/LogUtil';
import { SuperLogger } from '@/types/super-logger';

/**
 * 创建一个日志记录器实例
 * @returns 日志记录器实例
 */
function createLogger(): SuperLogger {
  return LogUtil.createLogger();
}

// 导出预定义主题的日志记录器实例

export const logger = createLogger();
