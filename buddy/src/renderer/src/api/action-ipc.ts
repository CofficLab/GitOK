import { IPC_METHODS } from "@/types/ipc-methods";
import { IpcResponse } from "@/types/ipc-response";
import { SuperAction } from "@/types/super_action";

const ipc = window.electron.ipc;

export const actionIpc = {
    async getActions(keyword = ''): Promise<SuperAction[]> {
        const response: IpcResponse<unknown> = await ipc.invoke(IPC_METHODS.Get_PLUGIN_ACTIONS, keyword);
        if (response.success) {
            return response.data as SuperAction[];
        } else {
            throw new Error(response.error);
        }
    },
};