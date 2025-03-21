interface MCPAPI {
  start: () => Promise<{ success: boolean; message: string }>;
  stop: () => Promise<{ success: boolean; message: string }>;
  sendCommand: (
    command: string
  ) => Promise<{ success: boolean; response: string }>;
  saveConfig: (config: {
    scriptPath: string;
    startupCommands: string[];
  }) => Promise<{ success: boolean; message: string }>;
  getConfig: () => Promise<{ scriptPath: string; startupCommands: string[] }>;
  openFileDialog: () => Promise<string | null>;
}

interface PluginsAPI {
  getPluginActions: () => Promise<any[]>;
  executeAction: (actionId: string) => Promise<any>;
}

interface ElectronAPI {
  mcp: MCPAPI;
  send: (channel: string, ...args: unknown[]) => void;
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;
  plugins: PluginsAPI;
  getWindowConfig: () => Promise<{ showTrafficLights: boolean }>;
  setWindowConfig: (
    config: Partial<{ showTrafficLights: boolean }>
  ) => Promise<void>;
  onWindowConfigChanged: (
    callback: (event: unknown, config: { showTrafficLights: boolean }) => void
  ) => () => void;
  toggleCommandDoublePress: (
    enabled: boolean
  ) => Promise<{ success: boolean; reason?: string; already?: boolean }>;
  onCommandDoublePressed: (callback: (event: unknown) => void) => () => void;
  onWindowHiddenByCommand: (callback: (event: unknown) => void) => () => void;
  onWindowActivatedByCommand: (
    callback: (event: unknown) => void
  ) => () => void;
}

interface Window {
  api: ElectronAPI;
  electron: ElectronAPI;
}
