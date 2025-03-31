/// <reference types="vite/client" />

import { PluginAPi } from '@/types/api-plugin';
import { CommandApi } from '@/types/api-command';
import { IpcApi } from '@/types/api-message';
import { OverlaidApi } from '@/types/api-overlaid';
import { UILogApi } from '@/types/api-log';

interface ElectronApi {
  ipc: IpcApi;
  command: CommandApi;
  plugins: PluginAPi;
  overlaid: OverlaidApi;
  ui: UILogApi;
}

declare global {
  interface Window {
    electron: ElectronApi;
  }
}
