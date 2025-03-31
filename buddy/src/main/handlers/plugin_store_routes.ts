import { IPC_METHODS } from '@/types/ipc-methods';
import { pluginStoreController } from '../controllers/PluginMarketController';
import { IpcRoute } from '../services/RouterService';

/**
 * 插件商店相关的IPC路由配置
 */
export const pluginStoreRoutes: IpcRoute[] = [
  {
    channel: IPC_METHODS.GET_USER_PLUGINS,
    handler: () => pluginStoreController.getUserPlugins(),
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