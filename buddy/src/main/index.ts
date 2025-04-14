/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { appManager } from './managers/AppManager';
import { routerService } from './provider/RouterService';
import { routes as pluginRoutes } from './handlers/plugin_router';
import { routes as overlaidAppRoutes } from './handlers/overlaid_router';
import { routes as updateRoutes } from './handlers/update_router';
import { baseRoutes } from './handlers/common_handler';
import { aiRoutes } from './handlers/ai_handler';
import { devRoutes } from './handlers/dev_handler';
import { routes as configRoutes } from './handlers/config_router';

// 初始化IPC处理器
routerService.registerRoutes(baseRoutes);
routerService.registerRoutes(aiRoutes);
routerService.registerRoutes(pluginRoutes);
routerService.registerRoutes(overlaidAppRoutes);
routerService.registerRoutes(updateRoutes);
routerService.registerRoutes(devRoutes);
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
