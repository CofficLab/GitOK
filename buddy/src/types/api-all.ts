import { ConfigAPI } from "@/preload/config";
import { AiApi } from "./api-ai";
import { CommandApi } from "./api-command";
import { DevApi } from "./api-dev";
import { IpcApi } from "./api-message";
import { OverlaidApi } from "./api-overlaid";
import { PluginAPi } from "./api-plugin";

// 上下文菜单API类型
interface ContextMenuApi {
    showContextMenu: (type: string, hasSelection: boolean) => void;
    onCopyCode: (callback: () => void) => () => void;
}

export interface ElectronApi {
    ai: AiApi,
    dev: DevApi,
    ipc: IpcApi;
    command: CommandApi;
    plugins: PluginAPi;
    overlaid: OverlaidApi;
    contextMenu: ContextMenuApi;
    update: any;
    config: ConfigAPI;
}