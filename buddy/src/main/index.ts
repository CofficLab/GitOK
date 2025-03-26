/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { appManager } from './managers/AppManager';
import { routerService } from './services/RouterService';
import { routes as pluginRoutes } from './router/plugin_router';
import {
  routes as overlaidAppRoutes,
  initOverlaidAppEvents,
} from './router/overlaid_router';
import { routes as commandKeyRoutes } from './router/command_router';
import { routes as uiLogRoutes } from './router/log_router';
import { routes as updateRoutes } from './router/update_router';

// 初始化路由
routerService.registerRoutes(pluginRoutes);
routerService.registerRoutes(overlaidAppRoutes);
routerService.registerRoutes(commandKeyRoutes);
routerService.registerRoutes(uiLogRoutes);
routerService.registerRoutes(updateRoutes);

// 启动应用
appManager
  .start()
  .then(() => {
    // 初始化IPC路由
    routerService.initialize();
    // 初始化被覆盖应用相关事件
    initOverlaidAppEvents();
  })
  .catch((error) => {
    console.error('应用启动失败:', error);
    process.exit(1);
  });
