import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { pluginViewManager } from '../managers/PluginViewManager';
import { logger } from '../managers/LogManager';

/**
 * 插件视图相关的IPC路由配置
 */
export const pluginViewRoutes: IpcRoute[] = [
  {
    channel: IPC_METHODS.CREATE_PLUGIN_VIEW,
    handler: async (_, { viewId, url }) => {
      try {
        const mainWindowBounds = await pluginViewManager.createView({
          viewId,
          url,
        });
        return { success: true, data: mainWindowBounds };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`创建插件视图窗口失败: ${viewId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.SHOW_PLUGIN_VIEW,
    handler: async (_, { viewId, bounds }) => {
      try {
        const result = await pluginViewManager.showView(viewId, bounds);
        return { success: true, data: result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`显示插件视图窗口失败: ${viewId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.HIDE_PLUGIN_VIEW,
    handler: async (_, { viewId }) => {
      try {
        const result = pluginViewManager.hideView(viewId);
        return { success: true, data: result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`隐藏插件视图窗口失败: ${viewId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.DESTROY_PLUGIN_VIEW,
    handler: async (_, { viewId }) => {
      try {
        const result = await pluginViewManager.destroyView(viewId);
        return { success: true, data: result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`销毁插件视图窗口失败: ${viewId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.TOGGLE_PLUGIN_DEVTOOLS,
    handler: (_, { viewId }) => {
      try {
        const result = pluginViewManager.toggleDevTools(viewId);
        return { success: true, data: result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`切换插件视图开发者工具失败: ${viewId}`, {
          error: errorMessage,
        });
        return { success: false, error: errorMessage };
      }
    },
  },
];