import { ViewBounds } from "@coffic/buddy-types";
import { IPC_METHODS } from "@/types/ipc-methods.js";

const ipc = window.ipc

export const viewIpc = {
    async upsertView(pagePath: string, bounds: ViewBounds): Promise<void> {
        await ipc.invoke(IPC_METHODS.UPSERT_VIEW, pagePath, bounds);
    },

    async destroyViews(): Promise<void> {
        await ipc.invoke(IPC_METHODS.Destroy_Plugin_Views);
    },
};