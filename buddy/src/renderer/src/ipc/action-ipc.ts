import { IpcResponse } from '@coffic/buddy-types';
import { SendableAction } from '@/types/sendable-action.js';
import { logger } from '@/renderer/src/utils/logger.js';
import { IPC_METHODS } from '@/types/ipc-methods';
const ipc = window.ipc;

export const actionIpc = {
    async getActions(keyword = ''): Promise<SendableAction[]> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.GET_ACTIONS, keyword);
        if (response.success) {
            return response.data as SendableAction[];
        } else {
            throw new Error(response.error);
        }
    },

    executeAction: async (actionId: string, keyword: string) => {
        logger.info(`执行插件动作: ${actionId}, 关键词: ${keyword}`);

        return await ipc.invoke(IPC_METHODS.EXECUTE_PLUGIN_ACTION, actionId, keyword);
    },

    async getActionView(actionId: string): Promise<string> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.GET_ACTION_VIEW, actionId);
        if (response.success) {
            return response.data as string;
        } else {
            throw new Error(response.error);
        }
    },
};