/**
 * 插件相关IPC处理函数
 */
import { ipcMain, shell } from 'electron';
import { BaseIPCManager } from './base';
import { pluginManager } from '../managers/PluginManager';
import { pluginViewManager } from '../managers/PluginViewManager';
import { pluginActionManager } from '../managers/PluginActionManager';
import { IpcResponse, IPC_METHODS } from '@/types/ipc';
import { SuperAction } from '@/types/super_action';
import { ipcLogger as logger } from '../managers/LogManager';

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
    logger.debug('注册插件相关IPC处理函数');

    this.registerPluginStoreHandlers();
    this.registerPluginActionHandlers();
    this.registerPluginViewHandlers();
  }

  /**
   * 注册插件商店相关处理函数
   */
  private registerPluginStoreHandlers(): void {
    // 获取插件商店列表
    ipcMain.handle('plugin:getStorePlugins', async () => {
      logger.debug('处理IPC请求: plugin:getStorePlugins');
      try {
        const plugins = await pluginManager.getStorePlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取插件目录信息
    ipcMain.handle('plugin:getDirectories', () => {
      logger.debug('处理IPC请求: plugin:getDirectories');
      try {
        const directories = pluginManager.getPluginDirectories();
        return { success: true, directories };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件目录信息失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取已安装的插件列表
    ipcMain.handle('plugin:getPlugins', async () => {
      logger.debug('处理IPC请求: plugin:getPlugins');
      try {
        const plugins = pluginManager.getPlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 打开插件目录
    ipcMain.handle('plugin:openDirectory', (_, directory: string) => {
      logger.debug('处理IPC请求: plugin:openDirectory', { directory });
      try {
        shell.openPath(directory);
        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('打开插件目录失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });
  }

  /**
   * 注册插件动作相关处理函数
   */
  private registerPluginActionHandlers(): void {
    // 获取插件动作列表
    ipcMain.handle(
      IPC_METHODS.GET_PLUGIN_ACTIONS,
      async (
        _event,
        keyword: string = ''
      ): Promise<IpcResponse<SuperAction[]>> => {
        logger.debug('处理IPC请求: get-plugin-actions');
        try {
          const actions = await pluginActionManager.getActions(keyword);
          return { success: true, data: actions };
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          logger.error('获取插件动作失败', { error: errorMessage });
          return { success: false, error: errorMessage };
        }
      }
    );

    // 执行插件动作
    ipcMain.handle(
      IPC_METHODS.EXECUTE_PLUGIN_ACTION,
      async (_event, actionId: string): Promise<IpcResponse<unknown>> => {
        logger.debug(`处理IPC请求: execute-plugin-action: ${actionId}`);
        try {
          const result = await pluginActionManager.executeAction(actionId);
          return { success: true, data: result };
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          logger.error(`执行插件动作失败: ${actionId}`, {
            error: errorMessage,
          });
          return { success: false, error: errorMessage };
        }
      }
    );

    // 获取动作视图内容
    ipcMain.handle(
      IPC_METHODS.GET_ACTION_VIEW,
      async (_event, actionId: string): Promise<IpcResponse<string>> => {
        logger.debug(`处理IPC请求: get-action-view: ${actionId}`);
        try {
          const html = await pluginActionManager.getActionView(actionId);
          return { success: true, data: html };
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          return { success: false, error: errorMessage };
        }
      }
    );
  }

  /**
   * 注册插件视图相关处理函数
   */
  private registerPluginViewHandlers(): void {
    // 创建插件视图窗口
    ipcMain.handle('create-plugin-view', async (_, { viewId, url }) => {
      logger.debug(`处理IPC请求: create-plugin-view: ${viewId}, url: ${url}`);
      try {
        const mainWindowBounds = await pluginViewManager.createView({
          viewId,
          url,
        });
        return mainWindowBounds;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`创建插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return null;
      }
    });

    // 显示插件视图窗口
    ipcMain.handle('show-plugin-view', async (_, { viewId, bounds }) => {
      logger.debug(`处理IPC请求: show-plugin-view: ${viewId}`);
      try {
        const result = await pluginViewManager.showView(viewId, bounds);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`显示插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 隐藏插件视图窗口
    ipcMain.handle('hide-plugin-view', async (_, { viewId }) => {
      logger.debug(`处理IPC请求: hide-plugin-view: ${viewId}`);
      try {
        const result = pluginViewManager.hideView(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`隐藏插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 销毁插件视图窗口
    ipcMain.handle('destroy-plugin-view', async (_, { viewId }) => {
      logger.debug(`处理IPC请求: destroy-plugin-view: ${viewId}`);
      try {
        const result = await pluginViewManager.destroyView(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`销毁插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 切换插件视图窗口的开发者工具
    ipcMain.handle('toggle-plugin-devtools', async (_, { viewId }) => {
      logger.debug(`处理IPC请求: toggle-plugin-devtools: ${viewId}`);
      try {
        const result = pluginViewManager.toggleDevTools(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`切换插件视图开发者工具失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });
  }
}

export const pluginIPCManager = PluginIPCManager.getInstance();
