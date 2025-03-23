/**
 * 管理器模块入口文件
 * 统一导出所有管理器类，提供统一的创建方法
 */
import { ConfigManager } from './ConfigManager';
import { WindowManager } from './WindowManager';
import { PluginManager } from './PluginManager';
import { CommandKeyManager } from './CommandKeyManager';
import { IPCManager } from './IPCManager';
import { Logger } from '../utils/Logger';

// 导出管理器类
export { ConfigManager } from './ConfigManager';
export { WindowManager } from './WindowManager';
export { PluginManager } from './PluginManager';
export { CommandKeyManager } from './CommandKeyManager';
export { IPCManager } from './IPCManager';

// 管理器实例集合
interface Managers {
  configManager: ConfigManager;
  windowManager: WindowManager;
  pluginManager: PluginManager;
  commandKeyManager: CommandKeyManager;
  ipcManager: IPCManager;
}

/**
 * 创建并初始化所有管理器
 */
export function createManagers(): Managers {
  const logger = new Logger('ManagersFactory');
  logger.info('开始创建管理器实例');

  // 创建配置管理器
  logger.debug('创建配置管理器');
  const configManager = new ConfigManager();

  // 创建窗口管理器
  logger.debug('创建窗口管理器');
  const windowManager = new WindowManager(configManager);

  // 创建插件管理器
  logger.debug('创建插件管理器');
  const pluginManager = new PluginManager(configManager);

  // 创建Command键双击管理器
  logger.debug('创建Command键双击管理器');
  const commandKeyManager = new CommandKeyManager();

  // 创建IPC管理器
  logger.debug('创建IPC管理器');
  const ipcManager = new IPCManager(
    configManager,
    windowManager,
    commandKeyManager
  );

  logger.info('所有管理器创建完成');
  return {
    configManager,
    windowManager,
    pluginManager,
    commandKeyManager,
    ipcManager,
  };
}
