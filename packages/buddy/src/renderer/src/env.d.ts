/// <reference types="vite/client" />

interface WindowConfig {
  showTrafficLights: boolean;
}

interface ElectronAPI {
  getWindowConfig: () => Promise<WindowConfig>;
  setWindowConfig: (config: Partial<WindowConfig>) => Promise<void>;
  onWindowConfigChanged: (
    callback: (event: Electron.IpcRendererEvent, config: WindowConfig) => void
  ) => () => void;
  ipcRenderer: {
    send: (channel: 'ping') => void;
  };
  process: {
    versions: {
      electron: string;
      chrome: string;
      node: string;
    };
  };
}

interface Window {
  electron: ElectronAPI;
  api: {
    send: (channel: string, ...args: unknown[]) => void;
    receive: (channel: string, callback: (...args: unknown[]) => void) => void;
    removeListener: (
      channel: string,
      callback: (...args: unknown[]) => void
    ) => void;
  };
}

declare global {
  interface Window {
    api: Window['api'];
  }
}
