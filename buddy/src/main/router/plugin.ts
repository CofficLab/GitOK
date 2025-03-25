/**
 * 插件相关IPC路由
 */
import { ipcMain } from 'electron';
import { BaseIPCManager } from './base';
import { IPC_METHODS } from '@/types/ipc';
import { pluginActionController } from '../controllers/PluginActionController';
import { pluginViewController } from '../controllers/PluginViewController';
import { pluginStoreController } from '../controllers/PluginStoreController';

export class PluginIPCManager extends BaseIPCManager {
  private static instance: PluginIPCManager;

  private constructor() {
    super('PluginIPCManager');
  }

  /**
   * 获取 PluginIPCManager 实例
   */
  public static getInstance(): PluginIPCManager {
    if (!PluginIPCManager.instance) {
      PluginIPCManager.instance = new PluginIPCManager();
    }
    return PluginIPCManager.instance;
  }

  /**
   * 注册插件相关的IPC处理函数
   */
  public registerHandlers(): void {
    const handlers = {
      // 插件动作相关
      [IPC_METHODS.GET_PLUGIN_ACTIONS]: (_, keyword = '') =>
        pluginActionController.getActions(keyword),
      [IPC_METHODS.EXECUTE_PLUGIN_ACTION]: (_, actionId: string) =>
        pluginActionController.executeAction(actionId),
      [IPC_METHODS.GET_ACTION_VIEW]: (_, actionId: string) =>
        pluginActionController.getActionView(actionId),

      // 插件视图相关
      [IPC_METHODS.CREATE_PLUGIN_VIEW]: (_, { viewId, url }) =>
        pluginViewController.createView(viewId, url),
      [IPC_METHODS.SHOW_PLUGIN_VIEW]: (_, { viewId, bounds }) =>
        pluginViewController.showView(viewId, bounds),
      [IPC_METHODS.HIDE_PLUGIN_VIEW]: (_, { viewId }) =>
        pluginViewController.hideView(viewId),
      [IPC_METHODS.DESTROY_PLUGIN_VIEW]: (_, { viewId }) =>
        pluginViewController.destroyView(viewId),
      [IPC_METHODS.TOGGLE_PLUGIN_DEVTOOLS]: (_, { viewId }) =>
        pluginViewController.toggleDevTools(viewId),

      // 插件商店相关
      [IPC_METHODS.GET_STORE_PLUGINS]: () =>
        pluginStoreController.getStorePlugins(),
      [IPC_METHODS.GET_PLUGIN_DIRECTORIES]: () =>
        pluginStoreController.getDirectories(),
      [IPC_METHODS.GET_PLUGINS]: () => pluginStoreController.getPlugins(),
      [IPC_METHODS.OPEN_PLUGIN_DIRECTORY]: (_, directory: string) =>
        pluginStoreController.openDirectory(directory),
    };

    Object.entries(handlers).forEach(([channel, handler]) => {
      ipcMain.handle(channel, handler);
    });
  }
}

export const pluginIPCManager = PluginIPCManager.getInstance();
