import { IPC_METHODS } from "@/types/ipc-methods";
import { IpcResponse } from "@/types/ipc-response";

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const viewIpc = {
    async upsertView(pagePath: string, bounds: Electron.Rectangle): Promise<void> {
        await ipc.invoke(IPC_METHODS.Upsert_View, pagePath, bounds);
    },

    async destroyViews(): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Destroy_Plugin_Views);
        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },
};