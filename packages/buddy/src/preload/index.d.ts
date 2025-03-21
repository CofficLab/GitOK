import { ElectronAPI } from '@electron-toolkit/preload';

interface ElectronAPI {
  readonly versions: Readonly<NodeJS.ProcessVersions>;
}

declare global {
  interface Window {
    electron: ElectronAPI;
    api: unknown;
    electronAPI: unknown;
  }
}
