/**
 * 插件系统类型定义
 * 定义插件接口和相关类型
 */

/**
 * 基本插件接口
 * 所有插件必须实现这个接口
 */
export interface BuddyPlugin {
  id: string // 插件唯一标识符
  name: string // 插件名称
  version: string // 插件版本
  description?: string // 插件描述

  // 生命周期方法
  initialize(): Promise<void> // 初始化插件
  activate(): Promise<void> // 激活插件
  deactivate(): Promise<void> // 停用插件

  // 可选的UI组件
  getViews?(): BuddyPluginView[]

  // 可选的IPC处理器注册
  registerIpcHandlers?(): void
}

/**
 * 插件视图定义
 */
export interface BuddyPluginView {
  name: string // 视图名称
  icon?: string // 图标名称
  component: string // 组件路径 (相对于插件根目录)
}

/**
 * 插件配置信息
 * 从package.json的buddy字段读取
 */
export interface BuddyPluginConfig {
  id: string // 插件ID
  name: string // 插件名称
  version?: string // 插件版本
  description?: string // 插件描述
  entry: string // 入口文件路径
  views?: BuddyPluginView[] // 视图定义
  permissions?: string[] // 权限列表
}

/**
 * 插件视图信息
 * 包含视图的完整信息，包括所属插件ID
 */
export interface BuddyPluginViewInfo extends BuddyPluginView {
  id: string // 视图唯一ID (通常是 pluginId-viewName)
  pluginId: string // 所属插件ID
  absolutePath: string // 组件的绝对路径
}
