import { AiApi } from "./api-ai";
import { CommandApi } from "./api-command";
import { UILogApi } from "./api-log";
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
    ipc: IpcApi;
    command: CommandApi;
    plugins: PluginAPi;
    overlaid: OverlaidApi;
    ui: UILogApi;
    contextMenu: ContextMenuApi;
    update: any; // 如果有更新API的类型定义，应该引入
}