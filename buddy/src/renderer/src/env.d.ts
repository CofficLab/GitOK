/// <reference types="vite/client" />

import { PluginAPi } from '@/types/api-plugin';
import { CommandApi } from '@/types/api-command';
import { IpcApi } from '@/types/api-message';
import { OverlaidApi } from '@/types/api-overlaid';
import { UILogApi } from '@/types/api-log';
import { ElectronApi } from '@/types/api-all';


declare global {
  interface Window {
    electron: ElectronApi;
  }
}
