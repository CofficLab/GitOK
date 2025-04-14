import { createViewArgs } from "@/types/args";
import { IPC_METHODS } from "@/types/ipc-methods";
import { IpcResponse } from "@/types/ipc-response";

const electronApi = window.electron;
const ipc = electronApi.ipc;

export const viewApi = {
    async createView(options: createViewArgs): Promise<unknown> {
        return await ipc.invoke(IPC_METHODS.Create_View, options);
    },

    async updateViewBounds(pagePath: string, bounds: Electron.Rectangle): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Update_View_Bounds, pagePath, bounds);
        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },

    async upsertView(pagePath: string, bounds: Electron.Rectangle): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Upsert_View, pagePath, bounds);
        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },

    async destroyView(pagePath: string): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Destroy_View, pagePath);

        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },

    async destroyPluginViews(): Promise<unknown> {
        const response: IpcResponse<any> = await ipc.invoke(IPC_METHODS.Destroy_Plugin_Views);
        if (response.success) {
            return response.data;
        } else {
            throw new Error(response.error);
        }
    },
};