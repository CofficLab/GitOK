/**
 * 插件系统主模块
 * 负责插件的加载、注册和管理
 */
import { ipcMain } from 'electron';
import { PluginManager } from './types';
import {
  loadLocalPlugins,
  loadInstalledPlugins,
  installPlugin,
  uninstallPlugin,
} from './plugin-loader';
import { Logger } from '../utils/Logger';

// 创建插件管理器实例
const pluginManager = new PluginManager();

// 创建日志记录器
const logger = new Logger('PluginSystem');

/**
 * 初始化插件系统
 * 加载插件并注册IPC处理函数
 */
export async function initializePluginSystem() {
  logger.info('初始化插件系统');

  // 加载本地和已安装的插件
  await loadPlugins();

  // === 搜索和动作相关 API ===
  // 获取插件动作 - 使用invoke方式
  ipcMain.handle('get-plugin-actions', async (_, keyword = '') => {
    logger.debug(`收到invoke请求: get-plugin-actions, 关键词: "${keyword}"`);
    try {
      const actions = await pluginManager.getAllActions(keyword);
      logger.debug(`获取到 ${actions.length} 个插件动作`);
      return actions;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`获取插件动作失败`, { error: errorMessage });
      return [];
    }
  });

  // 获取插件动作 - 使用send/receive方式
  ipcMain.on('get-plugin-actions', (event, keyword = '') => {
    logger.debug(
      `收到send请求: get-plugin-actions, 关键词: "${keyword}", 发送者: ${event.sender.id}`
    );

    pluginManager
      .getAllActions(keyword)
      .then((actions) => {
        logger.debug(`获取到 ${actions.length} 个插件动作，准备回复`);
        event.reply('get-plugin-actions-reply', actions);
        logger.debug('已回复: get-plugin-actions-reply');
      })
      .catch((error) => {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('获取插件动作失败', { error: errorMessage });
        event.reply('get-plugin-actions-reply', []);
        logger.debug('已回复空数组: get-plugin-actions-reply');
      });
  });

  // 执行插件动作 - 使用invoke方式
  ipcMain.handle('execute-plugin-action', async (_, actionId) => {
    logger.debug(
      `收到invoke请求: execute-plugin-action, 动作ID: "${actionId}"`
    );

    try {
      logger.debug(`开始执行插件动作: ${actionId}`);
      const result = await pluginManager.executeAction(actionId);
      logger.debug(`动作执行成功: ${actionId}`);
      return { success: true, result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`执行插件动作失败: ${actionId}`, { error: errorMessage });
      return {
        success: false,
        error: errorMessage,
      };
    }
  });

  // 执行插件动作 - 使用send/receive方式
  ipcMain.on('execute-plugin-action', async (event, actionId) => {
    logger.debug(
      `收到send请求: execute-plugin-action, 动作ID: "${actionId}", 发送者: ${event.sender.id}`
    );

    try {
      logger.debug(`开始执行插件动作: ${actionId}`);
      const result = await pluginManager.executeAction(actionId);
      logger.debug(`动作执行成功: ${actionId}, 准备回复`);
      event.reply('execute-plugin-action-reply', { success: true, result });
      logger.debug('已回复: execute-plugin-action-reply (成功)');
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`执行插件动作失败: ${actionId}`, { error: errorMessage });
      event.reply('execute-plugin-action-reply', {
        success: false,
        error: errorMessage,
      });
      logger.debug('已回复: execute-plugin-action-reply (失败)');
    }
  });

  // 获取动作视图内容
  ipcMain.handle('get-action-view', async (_, actionId) => {
    logger.debug(`收到invoke请求: get-action-view, 动作ID: "${actionId}"`);

    try {
      logger.debug(`开始获取动作视图内容: ${actionId}`);
      const html = await pluginManager.getActionViewContent(actionId);
      logger.debug(
        `获取动作视图成功: ${actionId}, HTML长度: ${html.length}字节`
      );
      return { success: true, html };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`获取动作视图失败: ${actionId}`, { error: errorMessage });
      return {
        success: false,
        error: errorMessage,
      };
    }
  });

  // === 插件管理相关 API ===
  // 获取所有插件
  ipcMain.handle('get-all-plugins', async () => {
    logger.debug(`收到invoke请求: get-all-plugins`);
    const plugins = pluginManager.getAllPlugins();
    logger.debug(`获取到 ${plugins.length} 个插件`);
    return plugins;
  });

  // 获取本地插件
  ipcMain.handle('get-local-plugins', async () => {
    logger.debug(`收到invoke请求: get-local-plugins`);
    // 过滤出本地插件
    const plugins = pluginManager
      .getAllPlugins()
      .filter((plugin) => plugin.isLocal);
    logger.debug(`获取到 ${plugins.length} 个本地插件`);
    return plugins;
  });

  // 获取已安装插件
  ipcMain.handle('get-installed-plugins', async () => {
    logger.debug(`收到invoke请求: get-installed-plugins`);
    // 过滤出已安装但非本地的插件
    const plugins = pluginManager
      .getAllPlugins()
      .filter((plugin) => plugin.isInstalled && !plugin.isLocal);
    logger.debug(`获取到 ${plugins.length} 个已安装插件`);
    return plugins;
  });

  // 安装插件
  ipcMain.handle('install-plugin', async (_, pluginPath) => {
    logger.debug(`收到invoke请求: install-plugin, 路径: "${pluginPath}"`);

    try {
      logger.debug(`开始安装插件: ${pluginPath}`);
      await installPlugin(pluginPath);
      logger.debug(`插件安装成功，重新加载插件`);

      // 重新加载插件
      await loadPlugins();
      return { success: true };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`安装插件失败: ${pluginPath}`, { error: errorMessage });
      return {
        success: false,
        error: errorMessage,
      };
    }
  });

  // 卸载插件
  ipcMain.handle('uninstall-plugin', async (_, pluginId) => {
    logger.debug(`收到invoke请求: uninstall-plugin, 插件ID: "${pluginId}"`);

    try {
      logger.debug(`开始卸载插件: ${pluginId}`);
      await uninstallPlugin(pluginId);
      logger.debug(`插件卸载成功，重新加载插件`);

      // 重新加载插件
      await loadPlugins();
      return { success: true };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`卸载插件失败: ${pluginId}`, { error: errorMessage });
      return {
        success: false,
        error: errorMessage,
      };
    }
  });

  logger.info('插件系统已完成初始化');
  return pluginManager;
}

/**
 * 加载所有插件
 */
async function loadPlugins() {
  logger.info('开始加载所有插件');

  // 加载本地插件
  const localPlugins = await loadLocalPlugins();
  logger.info(`加载了 ${localPlugins.length} 个本地插件，准备注册`);

  localPlugins.forEach((plugin) => pluginManager.registerPlugin(plugin));

  // 加载已安装的插件
  const installedPlugins = await loadInstalledPlugins();
  logger.info(`加载了 ${installedPlugins.length} 个已安装插件，准备注册`);

  installedPlugins.forEach((plugin) => {
    // 避免重复注册
    if (!pluginManager.getPlugin(plugin.id)) {
      pluginManager.registerPlugin(plugin);
    } else {
      logger.debug(`跳过重复插件: ${plugin.id}`);
    }
  });

  logger.info(
    `插件加载完成，共加载了 ${pluginManager.getAllPlugins().length} 个插件`
  );
}

// 导出插件管理器
export { pluginManager };
