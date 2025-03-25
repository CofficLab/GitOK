/**
 * UI 日志相关 IPC 处理函数
 */
import { logger } from '../managers/LogManager';
import { IpcRoute } from '../services/RouterService';

// 定义IPC方法名称常量
const UI_LOG_METHODS = {
  INFO: 'ui:log:info',
  ERROR: 'ui:log:error',
  WARN: 'ui:log:warn',
  DEBUG: 'ui:log:debug',
};

/**
 * UI日志相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  // 处理 info 级别的日志
  {
    channel: UI_LOG_METHODS.INFO,
    handler: (_, message: string) => {
      logger.info(`${message}`);
    },
  },

  // 处理 error 级别的日志
  {
    channel: UI_LOG_METHODS.ERROR,
    handler: (_, message: string) => {
      logger.error(`${message}`);
    },
  },

  // 处理 warn 级别的日志
  {
    channel: UI_LOG_METHODS.WARN,
    handler: (_, message: string) => {
      logger.warn(`${message}`);
    },
  },

  // 处理 debug 级别的日志
  {
    channel: UI_LOG_METHODS.DEBUG,
    handler: (_, message: string) => {
      logger.debug(`${message}`);
    },
  },
];
