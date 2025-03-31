import { IPC_METHODS } from '@/types/ipc';
import { pluginActionController } from '../controllers/PluginActionController';
import { pluginViewController } from '../controllers/PluginViewController';
import { pluginStoreController } from '../controllers/PluginMarketController';
import { IpcRoute } from '../services/RouterService';

/**
 * 插件相关的IPC路由配置
 */
export const routes: IpcRoute[] = [
  // 插件动作相关
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

  // 插件视图相关
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

  // 插件商店相关
  {
    channel: IPC_METHODS.GET_STORE_PLUGINS,
    handler: () => pluginStoreController.getStorePlugins(),
  },
  {
    channel: IPC_METHODS.GET_REMOTE_PLUGINS,
    handler: () => pluginStoreController.getRemotePlugins(),
  },
  {
    channel: IPC_METHODS.DOWNLOAD_PLUGIN,
    handler: (_, plugin) => pluginStoreController.downloadPlugin(plugin),
  },
  {
    channel: IPC_METHODS.GET_PLUGIN_DIRECTORIES,
    handler: () => pluginStoreController.getUserPluginDirectory(),
  },
  {
    channel: IPC_METHODS.GET_PLUGINS,
    handler: async () => await pluginStoreController.getPlugins(),
  },
  {
    channel: IPC_METHODS.UNINSTALL_PLUGIN,
    handler: async (_, pluginId: string) =>
      await pluginStoreController.uninstallPlugin(pluginId),
  },
  {
    channel: IPC_METHODS.OPEN_PLUGIN_DIRECTORY,
    handler: (_, directory: string) =>
      pluginStoreController.openDirectory(directory),
  },
];
