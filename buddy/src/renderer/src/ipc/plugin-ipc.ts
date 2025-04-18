import { ViewBounds } from "@coffic/buddy-types";

export const pluginIpc = {
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