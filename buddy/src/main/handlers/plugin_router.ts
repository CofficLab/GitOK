import { IpcRoute } from '../services/RouterService';
import { pluginActionRoutes } from './plugin_action_routes';
import { pluginViewRoutes } from './plugin_view_routes';
import { pluginStoreRoutes } from './plugin_store_routes';

/**
 * 插件相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  ...pluginActionRoutes,
  ...pluginViewRoutes,
  ...pluginStoreRoutes,
];
