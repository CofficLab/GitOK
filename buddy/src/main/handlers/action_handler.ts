import { IpcRoute } from '../provider/RouterService.js';
import { IpcResponse, SuperAction } from '@coffic/buddy-types';
import { actionManager } from '../managers/ActionManager.js';
import { logger } from '../managers/LogManager.js';
import { pluginManager } from '../managers/PluginManager.js';
import { IPC_METHODS } from '@/types/ipc-methods.js';
/**
 * 插件动作相关的IPC路由配置
 */
export const pluginActionRoutes: IpcRoute[] = [
	{
		channel: IPC_METHODS.GET_ACTIONS,
		handler: async (_, keyword = ''): Promise<IpcResponse<SuperAction[]>> => {
			try {
				const actions = await actionManager.getActions(keyword);
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
			return await pluginManager.executeAction(actionId, keyword);
		},
	},
	{
		channel: IPC_METHODS.GET_ACTION_VIEW,
		handler: async (_, actionId: string): Promise<string> => {
			return await actionManager.getActionView(actionId);
		},
	},
];