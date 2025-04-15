import { AiApi } from "./api-ai.js";
import { CommandApi } from "./api-command.js";
import { IpcApi } from "./api-message.js";
import { PluginAPi } from "./api-plugin.js";

// 上下文菜单API类型
interface ContextMenuApi {
    showContextMenu: (type: string, hasSelection: boolean) => void;
    onCopyCode: (callback: () => void) => () => void;
}

export interface ElectronApi {
    ai: AiApi,
    ipc: IpcApi;
    command: CommandApi;
    plugins: PluginAPi;
    contextMenu: ContextMenuApi;
    update: any;
}