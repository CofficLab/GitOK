import { IPC_METHODS, ViewBounds } from "@coffic/buddy-types";

const ipc = window.ipc

export const viewIpc = {
    async upsertView(pagePath: string, bounds: ViewBounds): Promise<void> {
        await ipc.invoke(IPC_METHODS.Upsert_View, pagePath, bounds);
    },

    async destroyViews(): Promise<void> {
        await ipc.invoke(IPC_METHODS.Destroy_Plugin_Views);
    },
};