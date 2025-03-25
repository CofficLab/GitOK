/**
 * IPC 通信相关的类型定义
 */

/**
 * IPC 响应的基础接口
 */
export interface IpcResponse<T> {
  success: boolean;
  error?: string;
  data?: T;
}

/**
 * IPC 通信中的方法名称常量
 */
export const IPC_METHODS = {
  GET_PLUGIN_ACTIONS: 'get-plugin-actions',
  EXECUTE_PLUGIN_ACTION: 'execute-plugin-action',
  GET_ACTION_VIEW: 'get-action-view',
  CREATE_PLUGIN_VIEW: 'create-plugin-view',
  SHOW_PLUGIN_VIEW: 'show-plugin-view',
  HIDE_PLUGIN_VIEW: 'hide-plugin-view',
  DESTROY_PLUGIN_VIEW: 'destroy-plugin-view',
  TOGGLE_PLUGIN_DEVTOOLS: 'toggle-plugin-devtools',
  // 插件商店相关
  GET_STORE_PLUGINS: 'plugin:getStorePlugins',
  GET_PLUGIN_DIRECTORIES: 'plugin:getDirectories',
  GET_PLUGINS: 'plugin:getPlugins',
  OPEN_PLUGIN_DIRECTORY: 'plugin:openDirectory',
} as const;

/**
 * IPC 方法名称类型
 */
export type IpcMethod = (typeof IPC_METHODS)[keyof typeof IPC_METHODS];
