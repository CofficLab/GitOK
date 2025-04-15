/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import { PluginAPi } from '@coffic/buddy-types';
import { pluginLifecycle } from './plugin-life.js';
import { pluginManagement } from './plugin-managerment.js';
import { pluginViews } from './plugin-views.js';

export const pluginApi: PluginAPi = {
  views: pluginViews,
  management: pluginManagement,
  lifecycle: pluginLifecycle,
};
