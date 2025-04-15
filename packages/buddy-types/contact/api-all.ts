import { AiApi } from "./api-ai.js";
import { CommandApi } from "./api-command.js";
import { IpcApi } from "./api-message.js";
import { PluginAPi } from "./api-plugin.js";

export interface ElectronApi {
    ai: AiApi,
    ipc: IpcApi;
    command: CommandApi;
    plugins: PluginAPi;
    update: any;
}