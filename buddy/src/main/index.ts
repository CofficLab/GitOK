/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { appManager } from './managers/AppManager.js';
import { routerService } from './provider/RouterService.js';
import { routes as pluginRoutes } from './handlers/plugin_router.js';
import { routes as overlaidAppRoutes } from './handlers/overlaid_router.js';
import { routes as updateRoutes } from './handlers/update_router.js';
import { baseRoutes } from './handlers/common_handler.js';
import { aiRoutes } from './handlers/ai_handler.js';
import { routes as configRoutes } from './handlers/config_router.js';

// 初始化IPC处理器
routerService.registerRoutes(baseRoutes);
routerService.registerRoutes(aiRoutes);
routerService.registerRoutes(pluginRoutes);
routerService.registerRoutes(overlaidAppRoutes);
routerService.registerRoutes(updateRoutes);
routerService.registerRoutes(configRoutes);

// 启动应用
appManager
  .start()
  .then(() => {
    routerService.initialize();
  })
  .catch((error) => {
    console.error('应用启动失败:', error);
    process.exit(1);
  });
