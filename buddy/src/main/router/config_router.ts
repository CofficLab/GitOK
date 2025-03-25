/**
 * 配置相关IPC路由
 */
import { configManager } from '../managers/ConfigManager';
import { logger } from '../managers/LogManager';
import { IpcRoute } from '../services/RouterService';

/**
 * 配置相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  // 窗口配置相关
  {
    channel: 'getWindowConfig',
    handler: () => {
      logger.debug('处理IPC请求: getWindowConfig');
      return configManager.getWindowConfig();
    },
  },
];
