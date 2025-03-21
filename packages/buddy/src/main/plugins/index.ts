/**
 * 插件系统主模块
 * 负责插件的加载、注册和管理
 */
import { ipcMain, BrowserWindow } from 'electron';
import { PluginManager } from './types';
import {
  loadLocalPlugins,
  loadInstalledPlugins,
  installPlugin,
  uninstallPlugin,
} from './plugin-loader';

// 创建插件管理器实例
const pluginManager = new PluginManager();

// 日志函数
const logInfo = (message: string, ...args: any[]) => {
  console.log(`[插件系统:主模块] ${message}`, ...args);
};

const logError = (message: string, ...args: any[]) => {
  console.error(`[插件系统:主模块] ${message}`, ...args);
};

const logDebug = (message: string, ...args: any[]) => {
  console.log(`[插件系统:主模块:调试] ${message}`, ...args);
};

/**
 * 初始化插件系统
 * 加载插件并注册IPC处理函数
 */
export async function initializePluginSystem() {
  logInfo('初始化插件系统');

  // 加载本地和已安装的插件
  await loadPlugins();

  // === 搜索和动作相关 API ===
  // 获取插件动作 - 使用invoke方式
  ipcMain.handle('get-plugin-actions', async (_, keyword = '') => {
    logDebug(`收到invoke请求: get-plugin-actions, 关键词: "${keyword}"`);
    try {
      const actions = await pluginManager.getAllActions(keyword);
      logDebug(`获取到 ${actions.length} 个插件动作`);
      return actions;
    } catch (error) {
      logError(`获取插件动作失败:`, error);
      return [];
    }
  });

  // 获取插件动作 - 使用send/receive方式
  ipcMain.on('get-plugin-actions', (event, keyword = '') => {
    logDebug(
      `收到send请求: get-plugin-actions, 关键词: "${keyword}", 发送者: ${event.sender.id}`
    );

    pluginManager
      .getAllActions(keyword)
      .then((actions) => {
        logDebug(`获取到 ${actions.length} 个插件动作，准备回复`);
        event.reply('get-plugin-actions-reply', actions);
        logDebug('已回复: get-plugin-actions-reply');
      })
      .catch((error) => {
        logError('Error getting plugin actions:', error);
        event.reply('get-plugin-actions-reply', []);
        logDebug('已回复空数组: get-plugin-actions-reply');
      });
  });

  // 执行插件动作 - 使用invoke方式
  ipcMain.handle('execute-plugin-action', async (_, actionId) => {
    logDebug(`收到invoke请求: execute-plugin-action, 动作ID: "${actionId}"`);

    try {
      logDebug(`开始执行插件动作: ${actionId}`);
      const result = await pluginManager.executeAction(actionId);
      logDebug(`动作执行成功: ${actionId}`);
      return { success: true, result };
    } catch (error) {
      logError(`执行插件动作失败: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 执行插件动作 - 使用send/receive方式
  ipcMain.on('execute-plugin-action', async (event, actionId) => {
    logDebug(
      `收到send请求: execute-plugin-action, 动作ID: "${actionId}", 发送者: ${event.sender.id}`
    );

    try {
      logDebug(`开始执行插件动作: ${actionId}`);
      const result = await pluginManager.executeAction(actionId);
      logDebug(`动作执行成功: ${actionId}, 准备回复`);
      event.reply('execute-plugin-action-reply', { success: true, result });
      logDebug('已回复: execute-plugin-action-reply (成功)');
    } catch (error) {
      logError(`执行插件动作失败: ${error}`);
      event.reply('execute-plugin-action-reply', {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      });
      logDebug('已回复: execute-plugin-action-reply (失败)');
    }
  });

  // 获取动作视图内容
  ipcMain.handle('get-action-view', async (_, actionId) => {
    logDebug(`收到invoke请求: get-action-view, 动作ID: "${actionId}"`);

    try {
      logDebug(`开始获取动作视图内容: ${actionId}`);
      const html = await pluginManager.getActionViewContent(actionId);
      logDebug(`获取动作视图成功: ${actionId}, HTML长度: ${html.length}字节`);
      return { success: true, html };
    } catch (error) {
      logError(`获取动作视图失败: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // === 插件管理相关 API ===
  // 获取所有插件
  ipcMain.handle('get-all-plugins', async () => {
    logDebug(`收到invoke请求: get-all-plugins`);
    const plugins = pluginManager.getAllPlugins();
    logDebug(`获取到 ${plugins.length} 个插件`);
    return plugins;
  });

  // 获取本地插件
  ipcMain.handle('get-local-plugins', async () => {
    logDebug(`收到invoke请求: get-local-plugins`);
    // 过滤出本地插件
    const plugins = pluginManager
      .getAllPlugins()
      .filter((plugin) => plugin.isLocal);
    logDebug(`获取到 ${plugins.length} 个本地插件`);
    return plugins;
  });

  // 获取已安装插件
  ipcMain.handle('get-installed-plugins', async () => {
    logDebug(`收到invoke请求: get-installed-plugins`);
    // 过滤出已安装但非本地的插件
    const plugins = pluginManager
      .getAllPlugins()
      .filter((plugin) => plugin.isInstalled && !plugin.isLocal);
    logDebug(`获取到 ${plugins.length} 个已安装插件`);
    return plugins;
  });

  // 安装插件
  ipcMain.handle('install-plugin', async (_, pluginPath) => {
    logDebug(`收到invoke请求: install-plugin, 路径: "${pluginPath}"`);

    try {
      logDebug(`开始安装插件: ${pluginPath}`);
      await installPlugin(pluginPath);
      logDebug(`插件安装成功，重新加载插件`);

      // 重新加载插件
      await loadPlugins();
      return { success: true };
    } catch (error) {
      logError(`安装插件失败: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  // 卸载插件
  ipcMain.handle('uninstall-plugin', async (_, pluginId) => {
    logDebug(`收到invoke请求: uninstall-plugin, 插件ID: "${pluginId}"`);

    try {
      logDebug(`开始卸载插件: ${pluginId}`);
      await uninstallPlugin(pluginId);
      logDebug(`插件卸载成功，重新加载插件`);

      // 重新加载插件
      await loadPlugins();
      return { success: true };
    } catch (error) {
      logError(`卸载插件失败: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  });

  logInfo('插件系统已完成初始化');
  return pluginManager;
}

/**
 * 加载所有插件
 */
async function loadPlugins() {
  logInfo('开始加载所有插件');

  // 加载本地插件
  const localPlugins = await loadLocalPlugins();
  logInfo(`加载了 ${localPlugins.length} 个本地插件，准备注册`);

  localPlugins.forEach((plugin) => pluginManager.registerPlugin(plugin));

  // 加载已安装的插件
  const installedPlugins = await loadInstalledPlugins();
  logInfo(`加载了 ${installedPlugins.length} 个已安装插件，准备注册`);

  installedPlugins.forEach((plugin) => {
    // 避免重复注册
    if (!pluginManager.getPlugin(plugin.id)) {
      pluginManager.registerPlugin(plugin);
    } else {
      logDebug(`跳过重复插件: ${plugin.id}`);
    }
  });

  logInfo(
    `插件加载完成，共加载了 ${pluginManager.getAllPlugins().length} 个插件`
  );
}

// 导出插件管理器
export { pluginManager };
