import { IpcRoute } from '../provider/RouterService';
import { pluginActionRoutes } from './plugin_action_routes';
import { pluginViewRoutes } from './plugin_view_routes';
import { pluginStoreRoutes } from './plugin_market_routes';

/**
 * 插件相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  ...pluginActionRoutes,
  ...pluginViewRoutes,
  ...pluginStoreRoutes,
];
