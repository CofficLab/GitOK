import { IPC_METHODS } from '@/types/ipc-methods';
import { pluginViewController } from '../controllers/PluginViewController';
import { IpcRoute } from '../services/RouterService';

/**
 * 插件视图相关的IPC路由配置
 */
export const pluginViewRoutes: IpcRoute[] = [
  {
    channel: IPC_METHODS.CREATE_PLUGIN_VIEW,
    handler: (_, { viewId, url }) =>
      pluginViewController.createView(viewId, url),
  },
  {
    channel: IPC_METHODS.SHOW_PLUGIN_VIEW,
    handler: (_, { viewId, bounds }) =>
      pluginViewController.showView(viewId, bounds),
  },
  {
    channel: IPC_METHODS.HIDE_PLUGIN_VIEW,
    handler: (_, { viewId }) => pluginViewController.hideView(viewId),
  },
  {
    channel: IPC_METHODS.DESTROY_PLUGIN_VIEW,
    handler: (_, { viewId }) => pluginViewController.destroyView(viewId),
  },
  {
    channel: IPC_METHODS.TOGGLE_PLUGIN_DEVTOOLS,
    handler: (_, { viewId }) => pluginViewController.toggleDevTools(viewId),
  },
];