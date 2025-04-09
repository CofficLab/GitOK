import { IPC_METHODS } from '@/types/ipc-methods';
import { IpcRoute } from '../provider/RouterService';
import { IpcResponse } from '@/types/ipc-response';
import { SuperAction } from '@/types/super_action';
import { pluginActionManager } from '../managers/PluginActionManager';
import { logger } from '../managers/LogManager';

/**
 * 插件动作相关的IPC路由配置
 */
export const pluginActionRoutes: IpcRoute[] = [
  {
    channel: IPC_METHODS.GET_PLUGIN_ACTIONS,
    handler: async (_, keyword = ''): Promise<IpcResponse<SuperAction[]>> => {
      try {
        const actions = await pluginActionManager.getActions(keyword);
        return { success: true, data: actions };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件动作失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.EXECUTE_PLUGIN_ACTION,
    handler: async (_, actionId: string, keyword: string): Promise<IpcResponse<unknown>> => {
      try {
        const result = await pluginActionManager.executeAction(actionId, keyword);
        return { success: true, data: result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`执行插件动作失败: ${actionId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
  {
    channel: IPC_METHODS.GET_ACTION_VIEW,
    handler: async (_, actionId: string): Promise<IpcResponse<string>> => {
      logger.debug(`获取动作视图: ${actionId}`);
      try {
        const html = await pluginActionManager.getActionView(actionId);
        return { success: true, data: html };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`获取动作视图失败: ${actionId}`, { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    },
  },
];