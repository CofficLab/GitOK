/**
 * IPC 通信中的方法名称常量
 */
export const IPC_METHODS = {
  // 基础功能
  Open_Folder: 'open-folder',
  Create_View: 'create-view',
  Destroy_View: 'destroy-view',
  Destroy_Plugin_Views: 'destroy-plugin-views',
  Update_View_Bounds: 'update-view-bounds',
  Upsert_View: 'upsert-view',

  // 插件相关
  Plugin_Is_Installed: 'plugin-is-installed',
  Get_PLUGIN_ACTIONS: 'get-plugin-actions',
  Get_PLUGIN_PAGE_SOURCE_CODE: 'get-plugin-page-source-code',
  EXECUTE_PLUGIN_ACTION: 'execute-plugin-action',
  GET_ACTION_VIEW: 'get-action-view',
  CREATE_PLUGIN_VIEW: 'create-plugin-view',
  SHOW_PLUGIN_VIEW: 'show-plugin-view',
  HIDE_PLUGIN_VIEW: 'hide-plugin-view',
  DESTROY_PLUGIN_VIEW: 'destroy-plugin-view',
  TOGGLE_PLUGIN_DEVTOOLS: 'toggle-plugin-devtools',

  // 插件商店相关
  GET_USER_PLUGINS: 'plugin:getStorePlugins',
  GET_DEV_PLUGINS: 'plugin:getDevPlugins',
  GET_REMOTE_PLUGINS: 'plugin:getRemotePlugins',
  DOWNLOAD_PLUGIN: 'plugin:downloadPlugin',
  GET_PLUGIN_DIRECTORIES: 'plugin:getUserPluginDirectory',
  GET_PLUGINS: 'plugin:getPlugins',
  UNINSTALL_PLUGIN: 'plugin:uninstallPlugin',
  OPEN_PLUGIN_DIRECTORY: 'plugin:openDirectory',

  // 被覆盖的应用
  Get_Current_App: 'overlaid-app:getCurrent',

  // AI功能相关
  AI_CHAT: 'ai:chat',

  // 流式AI聊天相关
  AI_CHAT_SEND: 'ai:chatSend',
  AI_CHAT_STREAM_CHUNK: 'ai:chatStreamChunk',
  AI_CHAT_STREAM_DONE: 'ai:chatStreamDone',
  AI_CHAT_CANCEL: 'ai:chatCancel',

  // 配置管理相关
  CONFIG_GET_ALL: 'config:getAll',
  CONFIG_GET: 'config:get',
  CONFIG_SET: 'config:set',
  CONFIG_DELETE: 'config:delete',
  CONFIG_RESET: 'config:reset',
  CONFIG_GET_PATH: 'config:getPath',

  // 开发测试相关方法
  DEV_TEST_ECHO: 'dev:test:echo',           // 回显测试
  DEV_TEST_ERROR: 'dev:test:error',         // 错误处理测试
  DEV_TEST_STREAM: 'dev:test:stream',       // 流处理测试
} as const;

/**
 * IPC 方法名称类型
 */
export type IpcMethod = (typeof IPC_METHODS)[keyof typeof IPC_METHODS];
