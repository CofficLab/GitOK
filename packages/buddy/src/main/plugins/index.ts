/**
 * 插件系统主模块
 * 负责插件的加载、注册和管理
 */
import { ipcMain } from 'electron';
import { PluginManager } from './types';
import { gitPlugin } from './git-plugin.js';
import { npmPlugin } from './npm-plugin.js';
import { vscodePlugin } from './vscode-plugin.js';

// 创建插件管理器实例
const pluginManager = new PluginManager();

// 注册内置插件
pluginManager.registerPlugin(gitPlugin);
pluginManager.registerPlugin(npmPlugin);
pluginManager.registerPlugin(vscodePlugin);

/**
 * 初始化插件系统
 * 注册IPC处理函数
 */
export function initializePluginSystem() {
  // 获取所有插件动作 - 使用invoke方式
  ipcMain.handle('get-plugin-actions', async () => {
    return pluginManager.getAllActions();
  });

  // 获取所有插件动作 - 使用send/receive方式
  ipcMain.on('get-plugin-actions', (event) => {
    try {
      const actions = pluginManager.getAllActions();
      event.reply('get-plugin-actions-reply', actions);
    } catch (error) {
      console.error('Error getting plugin actions:', error);
      event.reply('get-plugin-actions-reply', []);
    }
  });

  // 执行插件动作 - 使用invoke方式
  ipcMain.handle('execute-plugin-action', async (_, actionId: string) => {
    try {
      const result = await pluginManager.executeAction(actionId);
      return { success: true, result };
    } catch (error) {
      console.error(`执行插件动作失败: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 执行插件动作 - 使用send/receive方式
  ipcMain.on('execute-plugin-action', async (event, actionId: string) => {
    try {
      const result = await pluginManager.executeAction(actionId);
      event.reply('execute-plugin-action-reply', { success: true, result });
    } catch (error) {
      console.error(`执行插件动作失败: ${error}`);
      event.reply('execute-plugin-action-reply', {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  console.log('插件系统已初始化');
  return pluginManager;
}

// 导出插件管理器
export { pluginManager };
