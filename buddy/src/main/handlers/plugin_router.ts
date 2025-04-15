import { IpcRoute } from '../provider/RouterService';
import { pluginActionRoutes } from './action_handler';
import { pluginViewRoutes } from './plugin_view_handler';
import { marketRoutes } from './market_handler';

/**
 * 插件相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  ...pluginActionRoutes,
  ...pluginViewRoutes,
  ...marketRoutes,
];
