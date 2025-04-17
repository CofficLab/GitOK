import { ViewBounds } from "@coffic/buddy-types";

const ipc = window.ipc

export const pluginIpc = {
    async createView(pluginId: string, id: string): Promise<void> {
        console.log(ipc)
        console.log(pluginId, id);
    },

    async showView(pluginId: string, bounds: ViewBounds): Promise<boolean> {
        console.log(pluginId, bounds);
        return true;
    },

    async toggleDevTools(pluginId: string): Promise<void> {
        console.log(pluginId);
    },

    async destroyView(pluginId: string): Promise<void> {
        console.log(pluginId);
    }
};