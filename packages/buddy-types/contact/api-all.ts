import { AiApi } from "./api-ai.js";
import { IpcApi } from "./api-message.js";
import { PluginAPi } from "./api-plugin.js";

export interface ElectronApi {
    ai: AiApi,
    ipc: IpcApi;
    plugins: PluginAPi;
    update: any;
}