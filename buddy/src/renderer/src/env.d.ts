/// <reference types="vite/client" />

import { PluginAPi } from '@/types/api-plugin';
import { CommandApi } from '@/types/api-command';
import { IpcApi } from '@/types/api-message';
import { OverlaidApi } from '@/types/api-overlaid';
import { UILogApi } from '@/types/api-log';



declare global {
  interface Window {
    electron: ElectronApi;
  }
}
