import { IpcRoute } from '../provider/RouterService.js';
import { pluginActionRoutes } from './action_handler.js';
import { pluginViewRoutes } from './plugin_view_handler.js';
import { marketRoutes } from './market_handler.js';

/**
 * 插件相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  ...pluginActionRoutes,
  ...pluginViewRoutes,
  ...marketRoutes,
];
