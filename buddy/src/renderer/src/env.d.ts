/// <reference types="vite/client" />

import { PluginAPi } from '@/types/api-plugin';
import { CommandApi } from '@/types/api-command';
import { IpcApi } from '@/types/api-message';
import { OverlaidApi } from '@/types/api-overlaid';
import { UILogApi } from '@/types/api-log';

// 上下文菜单API类型
interface ContextMenuApi {
  showContextMenu: (type: string, hasSelection: boolean) => void;
  onCopyCode: (callback: () => void) => () => void;
}

interface ElectronApi {
  ipc: IpcApi;
  command: CommandApi;
  plugins: PluginAPi;
  overlaid: OverlaidApi;
  ui: UILogApi;
  contextMenu: ContextMenuApi;
  update: any; // 如果有更新API的类型定义，应该引入
}

declare global {
  interface Window {
    electron: ElectronApi;
  }
}
