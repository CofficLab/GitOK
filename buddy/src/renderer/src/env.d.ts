/// <reference types="vite/client" />

import { PluginAPi } from '@/types/plugin-api';
import { CommandApi } from '@/types/command-api';
import { IpcApi } from '@/types/ipc-api';
import { OverlaidApi } from '@/types/overlaid-api';
import { WindowApi } from '@/types/window-api';
import { UILogApi } from '@/types/ui-log-api';

interface ElectronApi {
  ipc: IpcApi;
  window: WindowApi;
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
