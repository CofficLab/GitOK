/**
 * Command键相关IPC处理函数
 */
import { commandKeyManager } from '../managers/CommandKeyManager';
import { logger } from '../managers/LogManager';
import { IpcRoute } from '../provider/RouterService';

// 定义IPC方法名称常量
const COMMAND_KEY_METHODS = {
  CHECK_COMMAND_KEY: 'checkCommandKey',
  IS_COMMAND_KEY_ENABLED: 'isCommandKeyEnabled',
  ENABLE_COMMAND_KEY: 'enableCommandKey',
  DISABLE_COMMAND_KEY: 'disableCommandKey',
};

/**
 * Command键相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  // 检查Command键功能是否可用
  {
    channel: COMMAND_KEY_METHODS.CHECK_COMMAND_KEY,
    handler: () => {
      logger.debug('处理IPC请求: checkCommandKey');
      return process.platform === 'darwin';
    },
  },

  // 检查Command键监听器状态
  {
    channel: COMMAND_KEY_METHODS.IS_COMMAND_KEY_ENABLED,
    handler: () => {
      logger.debug('处理IPC请求: isCommandKeyEnabled');
      return commandKeyManager.isListening();
    },
  },

  // 启用Command键监听
  {
    channel: COMMAND_KEY_METHODS.ENABLE_COMMAND_KEY,
    handler: async () => {
      logger.debug('处理IPC请求: enableCommandKey');
      const result = await commandKeyManager.enableCommandKeyListener();
      return result;
    },
  },

  // 禁用Command键监听
  {
    channel: COMMAND_KEY_METHODS.DISABLE_COMMAND_KEY,
    handler: () => {
      logger.debug('处理IPC请求: disableCommandKey');
      const result = commandKeyManager.disableCommandKeyListener();
      return result;
    },
  },
];
