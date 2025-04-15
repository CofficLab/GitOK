import { AiApi } from "./api-ai";
import { CommandApi } from "./api-command";
import { IpcApi } from "./api-message";
import { PluginAPi } from "./api-plugin";

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