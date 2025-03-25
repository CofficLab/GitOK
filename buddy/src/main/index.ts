/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { appManager } from './managers/AppManager';
import { routerService } from './services/RouterService';
import { routes as pluginRoutes } from './router/plugin';

// 初始化路由
routerService.registerRoutes(pluginRoutes);

// 启动应用
appManager
  .start()
  .then(() => {
    // 初始化IPC路由
    routerService.initialize();
  })
  .catch((error) => {
    console.error('应用启动失败:', error);
    process.exit(1);
  });
