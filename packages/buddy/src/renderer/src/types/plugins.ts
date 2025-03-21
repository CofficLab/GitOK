/**
 * 插件视图信息
 */
export interface BuddyPluginViewInfo {
  id: string
  pluginId: string
  name: string
  icon?: string
  component: string
  absolutePath: string
}

/**
 * 插件信息
 */
export interface BuddyPluginInfo {
  id: string
  name: string
  version: string
  description?: string
  isActive: boolean
}

/**
 * 插件API定义
 */
export interface PluginsAPI {
  getViews: () => Promise<BuddyPluginViewInfo[]>
  getAllPlugins: () => Promise<BuddyPluginInfo[]>
  activatePlugin: (pluginId: string) => Promise<boolean>
  deactivatePlugin: (pluginId: string) => Promise<boolean>
}
