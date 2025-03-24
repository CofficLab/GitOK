/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { initLogger } from './utils/initLogger';
import { appManager } from './managers/AppManager';

// 初始化日志系统
initLogger(!process.env.PROD);

// 启动应用
appManager.start().catch((error) => {
  console.error('应用启动失败:', error);
  process.exit(1);
});
