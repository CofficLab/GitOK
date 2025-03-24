/**
 * 类型定义入口文件
 * 集中导出所有类型定义
 */

// 导出 Electron 相关类型
export * from './electron';
export * from './ipc';
export * from './window';
export * from './store';

// 导出插件相关类型,解决命名冲突
export * from './plugin';

// 导出插件视图相关类型
export * from './plugin-view';

export interface PluginAction {
  id: string;
  title: string;
  description?: string;
  icon?: string;
  viewPath?: string;
  plugin: string; // 插件ID
  devTools?: boolean; // 是否启用开发者工具
  viewMode?: 'embedded' | 'window'; // 视图模式
}
