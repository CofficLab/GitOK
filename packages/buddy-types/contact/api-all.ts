import { IpcApi } from "./api-message.js";
import { PluginAPi } from "./api-plugin.js";

export interface ElectronApi {
    ipc: IpcApi;
    plugins: PluginAPi;
}