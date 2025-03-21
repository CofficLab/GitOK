/**
 * Electron API的类型定义
 */

// 插件API接口
interface PluginsViewsAPI {
  // 创建插件视图
  create: (
    viewId: string,
    url: string
  ) => Promise<{ success: boolean; viewId?: string; error?: string }>;

  // 显示插件视图
  show: (
    viewId: string,
    bounds?: { x: number; y: number; width: number; height: number }
  ) => Promise<{ success: boolean; error?: string }>;

  // 隐藏插件视图
  hide: (viewId: string) => Promise<{ success: boolean; error?: string }>;

  // 销毁插件视图
  destroy: (viewId: string) => Promise<{ success: boolean; error?: string }>;

  // 切换插件视图的开发者工具
  toggleDevTools: (
    viewId: string
  ) => Promise<{ success: boolean; error?: string }>;
}

// 扩展插件API接口，添加views
interface PluginsAPI {
  // 获取所有可用的插件动作
  getPluginActions: (keyword?: string) => Promise<any[]>;

  // 执行插件动作
  executeAction: (actionId: string) => Promise<any>;

  // 获取动作视图内容
  getActionView: (actionId: string) => Promise<any>;

  // 获取所有插件
  getAllPlugins: () => Promise<any[]>;

  // 获取本地插件
  getLocalPlugins: () => Promise<any[]>;

  // 获取已安装插件
  getInstalledPlugins: () => Promise<any[]>;

  // 安装插件
  installPlugin: (pluginPath: string) => Promise<any>;

  // 卸载插件
  uninstallPlugin: (pluginId: string) => Promise<any>;

  // 插件视图相关API
  views: PluginsViewsAPI;
}

// MCP API接口
interface MCPAPI {
  // 启动MCP服务
  start: () => Promise<{ success: boolean; message: string }>;

  // 停止MCP服务
  stop: () => Promise<{ success: boolean; message: string }>;

  // 发送命令到MCP服务
  sendCommand: (
    command: string
  ) => Promise<{ success: boolean; response: string }>;

  // 保存配置
  saveConfig: (config: {
    scriptPath: string;
    startupCommands: string[];
  }) => Promise<{ success: boolean; message: string }>;

  // 获取配置
  getConfig: () => Promise<{ scriptPath: string; startupCommands: string[] }>;

  // 打开文件对话框
  openFileDialog: () => Promise<string | null>;
}

// 窗口配置接口
interface WindowConfig {
  showTrafficLights: boolean;
  showDebugToolbar?: boolean;
  debugToolbarPosition?: 'right' | 'bottom' | 'left' | 'top';
}

// Electron API接口
interface ElectronAPI {
  // 插件相关API
  plugins: PluginsAPI;

  // MCP相关API
  mcp: MCPAPI;

  // 发送IPC消息
  send: (channel: string, ...args: unknown[]) => void;

  // 接收IPC消息
  receive: (channel: string, callback: (...args: unknown[]) => void) => void;

  // 移除IPC监听器
  removeListener: (
    channel: string,
    callback: (...args: unknown[]) => void
  ) => void;

  // 获取窗口配置
  getWindowConfig: () => Promise<WindowConfig>;

  // 设置窗口配置
  setWindowConfig: (config: Partial<WindowConfig>) => Promise<void>;

  // 窗口配置变更事件
  onWindowConfigChanged: (
    callback: (event: any, config: WindowConfig) => void
  ) => () => void;

  // 切换Command键双击功能
  toggleCommandDoublePress: (
    enabled: boolean
  ) => Promise<{ success: boolean; reason?: string; already?: boolean }>;

  // Command键双击事件
  onCommandDoublePressed: (callback: (event: any) => void) => () => void;

  // 窗口通过Command键隐藏事件
  onWindowHiddenByCommand: (callback: (event: any) => void) => () => void;

  // 窗口通过Command键激活事件
  onWindowActivatedByCommand: (callback: (event: any) => void) => () => void;
}

// 声明全局变量
declare global {
  interface Window {
    electron: ElectronAPI;
    api: ElectronAPI;
  }
}
