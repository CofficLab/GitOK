import { IPC_METHODS } from '@/types/ipc-methods';
import { pluginActionController } from '../controllers/PluginActionController';
import { IpcRoute } from '../services/RouterService';

/**
 * 插件动作相关的IPC路由配置
 */
export const pluginActionRoutes: IpcRoute[] = [
  {
    channel: IPC_METHODS.GET_PLUGIN_ACTIONS,
    handler: (_, keyword = '') => pluginActionController.getActions(keyword),
  },
  {
    channel: IPC_METHODS.EXECUTE_PLUGIN_ACTION,
    handler: (_, actionId: string) =>
      pluginActionController.executeAction(actionId),
  },
  {
    channel: IPC_METHODS.GET_ACTION_VIEW,
    handler: (_, actionId: string) =>
      pluginActionController.getActionView(actionId),
  },
];