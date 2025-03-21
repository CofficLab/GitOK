/**
 * 插件系统类型定义
 */

/**
 * 插件视图信息
 */
export interface BuddyPluginViewInfo {
  id: string;
  name: string;
  absolutePath: string;
  icon?: string;
}

/**
 * 插件元数据
 */
export interface BuddyPluginMeta {
  id: string;
  name: string;
  version: string;
  description: string;
  author?: string;
}

/**
 * 插件注册表项
 */
export interface PluginRegistryItem {
  version: string;
  installedAt: string;
  enabled: boolean;
  source: string;
}

/**
 * 插件API类型声明
 */
export interface BuddyPluginAPI {
  getViews(): Promise<BuddyPluginViewInfo[]>;
  installPlugin(path: string): Promise<{ success: boolean; error?: string }>;
  uninstallPlugin(id: string): Promise<{ success: boolean }>;
}

/**
 * 扩展Window接口以支持插件API
 */
declare global {
  interface Window {
    api: {
      plugins: BuddyPluginAPI;
    };
    electronAPI: {
      getPlugins(): Promise<Record<string, PluginRegistryItem>>;
      installPlugin(
        path: string
      ): Promise<{ success: boolean; error?: string }>;
      uninstallPlugin(id: string): Promise<{ success: boolean }>;
      openPluginFile(): Promise<{
        success: boolean;
        canceled?: boolean;
        filePath?: string;
      }>;
      installSamplePlugin(): Promise<{
        success: boolean;
        pluginId?: string;
        error?: string;
      }>;
    };
  }
}
