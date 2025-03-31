/**
 * 插件系统模块
 * 处理插件的安装、卸载、执行等功能
 */
import {
  PluginAPi,
} from '@/types/api-plugin';
import { pluginLifecycle } from './plugin-life';
import { pluginManagement } from './plugin-managerment';
import { pluginActions } from './plugin-actions';
import { pluginViews } from './plugin-views';

export const pluginApi: PluginAPi = {
  views: pluginViews,
  management: pluginManagement,
  actions: pluginActions,
  lifecycle: pluginLifecycle,
};
