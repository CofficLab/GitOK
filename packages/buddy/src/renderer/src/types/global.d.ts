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

// 插件动作类型
interface PluginAction {
  id: string;
  title: string;
  description: string;
  icon: string;
  plugin: string;
  viewPath?: string;
}

// 插件信息类型
interface PluginInfo {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  isInstalled: boolean;
  isLocal: boolean;
}

interface PluginsAPI {
  getPluginActions: (keyword?: string) => Promise<PluginAction[]>;
  executeAction: (actionId: string) => Promise<any>;
  getActionView: (
    actionId: string
  ) => Promise<{ success: boolean; html?: string; error?: string }>;
  getAllPlugins: () => Promise<PluginInfo[]>;
  getLocalPlugins: () => Promise<PluginInfo[]>;
  getInstalledPlugins: () => Promise<PluginInfo[]>;
  installPlugin: (
    pluginPath: string
  ) => Promise<{ success: boolean; error?: string }>;
  uninstallPlugin: (
    pluginId: string
  ) => Promise<{ success: boolean; error?: string }>;
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
