import { IPC_METHODS, IpcResponse } from '@coffic/buddy-types';
import { SendableAction } from '@/types/sendable-action.js';

const ipc = window.ipc;

export const actionIpc = {
    async getActions(keyword = ''): Promise<SendableAction[]> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.Get_PLUGIN_ACTIONS, keyword);
        if (response.success) {
            return response.data as SendableAction[];
        } else {
            throw new Error(response.error);
        }
    },

    executeAction: async (actionId: string, keyword: string) => {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.EXECUTE_PLUGIN_ACTION, actionId, keyword);
        if (response.success) {
            return response.data as SendableAction[];
        } else {
            throw new Error(response.error);
        }
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