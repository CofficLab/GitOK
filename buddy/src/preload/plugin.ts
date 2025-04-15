/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import { PluginAPi } from '@coffic/buddy-types';
import { pluginLifecycle } from './plugin-life';
import { pluginManagement } from './plugin-managerment';
import { pluginViews } from './plugin-views';

export const pluginApi: PluginAPi = {
  views: pluginViews,
  management: pluginManagement,
  lifecycle: pluginLifecycle,
};
