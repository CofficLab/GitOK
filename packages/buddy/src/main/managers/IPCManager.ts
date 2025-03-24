/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { ipcMain, shell, BrowserWindow } from 'electron';
import { configManager } from './ConfigManager';
import { commandKeyManager } from './CommandKeyManager';
import { pluginManager } from './PluginManager';
import { pluginViewManager } from './PluginViewManager';
import { appStateManager } from './AppStateManager';
import { pluginActionManager } from './PluginActionManager';
import { BaseManager } from './BaseManager';

class IPCManager extends BaseManager {
  private static instance: IPCManager;
  private configManager = configManager;
  private commandKeyManager = commandKeyManager;

  private constructor() {
    const config = configManager.getConfig().ipc || {};
    super({
      name: 'IPCManager',
      enableLogging: config.enableLogging,
      logLevel: config.logLevel,
    });

    // 注册被覆盖应用相关的IPC处理函数
    this.registerOverlaidAppHandlers();
  }

  /**
   * 获取 IPCManager 实例
   */
  public static getInstance(): IPCManager {
    if (!IPCManager.instance) {
      IPCManager.instance = new IPCManager();
    }
    return IPCManager.instance;
  }

  /**
   * 注册所有IPC处理函数
   */
  public registerHandlers(): void {
    this.logger.info('开始注册IPC处理函数');
    this.registerConfigHandlers();
    this.registerCommandKeyHandlers();
    this.registerPluginHandlers();
    this.logger.info('IPC处理函数注册完成');
  }

  /**
   * 注册配置相关的IPC处理函数
   */
  private registerConfigHandlers(): void {
    this.logger.debug('注册配置相关IPC处理函数');

    // 获取窗口配置
    ipcMain.handle('getWindowConfig', () => {
      this.logger.debug('处理IPC请求: getWindowConfig');
      return this.configManager.getWindowConfig();
    });
  }

  /**
   * 注册Command键相关的IPC处理函数
   */
  private registerCommandKeyHandlers(): void {
    this.logger.debug('注册Command键相关IPC处理函数');

    // 检查Command键功能是否可用
    ipcMain.handle('checkCommandKey', () => {
      this.logger.debug('处理IPC请求: checkCommandKey');
      return process.platform === 'darwin';
    });

    // 检查Command键监听器状态
    ipcMain.handle('isCommandKeyEnabled', () => {
      this.logger.debug('处理IPC请求: isCommandKeyEnabled');
      return this.commandKeyManager.isListening();
    });

    // 启用Command键监听
    ipcMain.handle('enableCommandKey', async () => {
      this.logger.debug('处理IPC请求: enableCommandKey');
      const result = await this.commandKeyManager.enableCommandKeyListener();
      return result;
    });

    // 禁用Command键监听
    ipcMain.handle('disableCommandKey', () => {
      this.logger.debug('处理IPC请求: disableCommandKey');
      const result = this.commandKeyManager.disableCommandKeyListener();
      return result;
    });
  }

  /**
   * 注册插件相关的IPC处理函数
   */
  private registerPluginHandlers(): void {
    this.logger.debug('注册插件相关IPC处理函数');

    // 获取插件商店列表
    ipcMain.handle('plugin:getStorePlugins', async () => {
      this.logger.debug('处理IPC请求: plugin:getStorePlugins');
      try {
        const plugins = await pluginManager.getStorePlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取插件目录信息
    ipcMain.handle('plugin:getDirectories', () => {
      this.logger.debug('处理IPC请求: plugin:getDirectories');
      try {
        const directories = pluginManager.getPluginDirectories();
        return { success: true, directories };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件目录信息失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取已安装的插件列表
    ipcMain.handle('plugin:getPlugins', async () => {
      this.logger.debug('处理IPC请求: plugin:getPlugins');
      try {
        const plugins = pluginManager.getPlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件列表失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取插件动作列表
    ipcMain.handle(
      'get-plugin-actions',
      async (_event, keyword: string = '') => {
        this.logger.debug('处理IPC请求: get-plugin-actions');
        try {
          const actions = await pluginActionManager.getActions(keyword);
          return { success: true, actions };
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          this.logger.error('获取插件动作失败', { error: errorMessage });
          return { success: false, error: errorMessage };
        }
      }
    );

    // 执行插件动作
    ipcMain.handle(
      'execute-plugin-action',
      async (_event, actionId: string) => {
        this.logger.debug(`处理IPC请求: execute-plugin-action: ${actionId}`);
        try {
          const result = await pluginActionManager.executeAction(actionId);
          return { success: true, result };
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          this.logger.error(`执行插件动作失败: ${actionId}`, {
            error: errorMessage,
          });
          return { success: false, error: errorMessage };
        }
      }
    );

    // 获取动作视图内容
    ipcMain.handle('get-action-view', async (_event, actionId: string) => {
      this.logger.debug(`处理IPC请求: get-action-view: ${actionId}`);
      try {
        const html = await pluginActionManager.getActionView(actionId);
        return { success: true, html };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`获取动作视图失败: ${actionId}`, {
          error: errorMessage,
        });
        return { success: false, error: errorMessage };
      }
    });

    // 打开插件目录
    ipcMain.handle('plugin:openDirectory', (_, directory: string) => {
      this.logger.debug('处理IPC请求: plugin:openDirectory', { directory });
      try {
        shell.openPath(directory);
        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('打开插件目录失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 创建插件视图窗口
    ipcMain.handle('create-plugin-view', async (_, { viewId, url }) => {
      this.logger.debug(
        `处理IPC请求: create-plugin-view: ${viewId}, url: ${url}`
      );
      try {
        const mainWindowBounds = await pluginViewManager.createView({
          viewId,
          url,
        });
        return mainWindowBounds;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`创建插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return null;
      }
    });

    // 显示插件视图窗口
    ipcMain.handle('show-plugin-view', async (_, { viewId, bounds }) => {
      this.logger.debug(`处理IPC请求: show-plugin-view: ${viewId}`);
      try {
        const result = await pluginViewManager.showView(viewId, bounds);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`显示插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 隐藏插件视图窗口
    ipcMain.handle('hide-plugin-view', async (_, { viewId }) => {
      this.logger.debug(`处理IPC请求: hide-plugin-view: ${viewId}`);
      try {
        const result = pluginViewManager.hideView(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`隐藏插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 销毁插件视图窗口
    ipcMain.handle('destroy-plugin-view', async (_, { viewId }) => {
      this.logger.debug(`处理IPC请求: destroy-plugin-view: ${viewId}`);
      try {
        const result = await pluginViewManager.destroyView(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`销毁插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });

    // 切换插件视图窗口的开发者工具
    ipcMain.handle('toggle-plugin-devtools', async (_, { viewId }) => {
      this.logger.debug(`处理IPC请求: toggle-plugin-devtools: ${viewId}`);
      try {
        const result = pluginViewManager.toggleDevTools(viewId);
        return result;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`切换插件视图开发者工具失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    });
  }

  /**
   * 注册被覆盖应用相关的IPC处理函数
   */
  private registerOverlaidAppHandlers(): void {
    this.logger.debug('注册被覆盖应用相关IPC处理函数');

    // 监听被覆盖应用变化事件
    appStateManager.on('overlaid-app-changed', (app: any) => {
      // 向所有渲染进程广播被覆盖应用变化事件
      this.logger.debug('广播被覆盖应用变化事件', app);
      const windows = BrowserWindow.getAllWindows();
      windows.forEach((window) => {
        window.webContents.send('overlaid-app-changed', app);
      });
    });
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    try {
      // 移除所有IPC事件监听器
      ipcMain.removeAllListeners();
    } catch (error) {
      this.handleError(error, 'IPC管理器资源清理失败');
    }
  }
}

// 导出单例
export const ipcManager = IPCManager.getInstance();
