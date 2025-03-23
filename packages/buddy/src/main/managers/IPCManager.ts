/**
 * IPC管理器
 * 负责处理主进程与渲染进程之间的IPC通信
 */
import { ipcMain } from 'electron';
import { EventEmitter } from 'events';
import { configManager } from './ConfigManager';
import { commandKeyManager } from './CommandKeyManager';
import { Logger } from '../utils/Logger';
import { pluginManager } from './PluginManager';
import { pluginViewManager } from './PluginViewManager';
import { shell } from 'electron';
import { join } from 'path';
import { app } from 'electron';
import fs from 'fs';
import path from 'path';

class IPCManager extends EventEmitter {
  private static instance: IPCManager;
  private configManager = configManager;
  private commandKeyManager = commandKeyManager;
  private logger: Logger;

  private constructor() {
    super();
    // 从配置文件中读取日志配置
    const config = this.configManager.getConfig().ipc || {};
    this.logger = new Logger('IPCManager', {
      enabled: config.enableLogging,
      level: config.logLevel,
    });
    this.logger.info('IPCManager 初始化');
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

    // 获取插件目录信息
    ipcMain.handle('plugin:getDirectories', async () => {
      this.logger.debug('处理IPC请求: plugin:getDirectories');
      try {
        const directories = pluginManager.getPluginDirectories();
        return { success: true, directories };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件目录失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 获取插件商店列表
    ipcMain.handle('plugin:getStorePlugins', async () => {
      this.logger.debug('处理IPC请求: plugin:getStorePlugins');
      try {
        const plugins = await pluginManager.getStorePlugins();
        return { success: true, plugins };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件商店列表失败', { error: errorMessage });
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

    // 获取插件动作
    ipcMain.handle('get-plugin-actions', async (_, keyword = '') => {
      this.logger.debug('处理IPC请求: get-plugin-actions');
      try {
        const actions = await pluginManager.getPluginActions(keyword);
        return { success: true, actions };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('获取插件动作失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });

    // 执行插件动作
    ipcMain.handle('execute-plugin-action', async (_, actionId) => {
      this.logger.debug(`处理IPC请求: execute-plugin-action: ${actionId}`);
      try {
        const result = await pluginManager.executePluginAction(actionId);
        return { success: true, result };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`执行插件动作失败: ${actionId}`, {
          error: errorMessage,
        });
        return { success: false, error: errorMessage };
      }
    });

    // 获取动作视图内容
    ipcMain.handle('get-action-view', async (_, actionId) => {
      this.logger.debug(`处理IPC请求: get-action-view: ${actionId}`);
      try {
        const html = await pluginManager.getActionView(actionId);
        return { success: true, html, content: html };
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
    ipcMain.handle('plugin:openDirectory', async (_, directory: string) => {
      try {
        // 如果是相对路径，则转换为绝对路径
        const absolutePath = directory.startsWith('/')
          ? directory
          : join(app.getPath('userData'), directory);

        // 使用系统默认程序打开目录
        await shell.openPath(absolutePath);

        return {
          success: true,
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('Failed to open directory:', { error: errorMessage });
        return {
          success: false,
          error: '无法打开目录',
        };
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

    // 创建示例插件
    ipcMain.handle('plugin:createExamplePlugin', async () => {
      this.logger.debug('处理IPC请求: plugin:createExamplePlugin');
      try {
        // 获取插件目录
        const pluginDirectories = pluginManager.getPluginDirectories();
        // 直接使用插件管理器提供的开发插件目录路径
        const devPluginDir = pluginDirectories.dev;
        const examplePluginTargetDir = path.join(
          devPluginDir,
          'example-plugin'
        );

        // 创建开发插件目录（如果不存在）
        if (!fs.existsSync(devPluginDir)) {
          fs.mkdirSync(devPluginDir, { recursive: true });
        }

        // 如果目标插件已存在，先删除它
        if (fs.existsSync(examplePluginTargetDir)) {
          this.logger.info(
            `目标目录已存在，删除现有示例插件: ${examplePluginTargetDir}`
          );
          fs.rmSync(examplePluginTargetDir, { recursive: true, force: true });
        }

        // 确定示例插件源目录
        let sourceDir = '';

        if (app.isPackaged) {
          // 生产环境 - 从资源目录复制
          sourceDir = path.join(
            app.getAppPath(),
            '..',
            'resources',
            'plugins',
            'examples',
            'example-plugin'
          );
          this.logger.debug(`生产环境示例插件源目录: ${sourceDir}`);
        } else {
          // 开发环境 - 从项目目录复制
          sourceDir = path.join(
            app.getAppPath(),
            '..',
            '..',
            'packages',
            'example-plugin'
          );
          this.logger.debug(`开发环境示例插件源目录: ${sourceDir}`);
        }

        if (!fs.existsSync(sourceDir)) {
          throw new Error(`源示例插件目录不存在: ${sourceDir}`);
        }

        // 复制示例插件到开发插件目录
        this.logger.info(
          `复制示例插件: ${sourceDir} -> ${examplePluginTargetDir}`
        );
        this.copyFolderSync(sourceDir, examplePluginTargetDir);

        // 刷新插件管理器
        this.logger.info('重新加载插件');

        // 重新初始化插件管理器
        await pluginManager.initialize();

        return {
          success: true,
          message: '示例插件创建成功',
          path: examplePluginTargetDir,
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('创建示例插件失败', { error: errorMessage });
        return { success: false, error: errorMessage };
      }
    });
  }

  /**
   * 递归复制目录及其内容
   * @param src 源目录
   * @param dest 目标目录
   */
  private copyFolderSync(src: string, dest: string): void {
    // 如果目标目录不存在，创建它
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    // 获取源目录中的所有文件和文件夹
    const entries = fs.readdirSync(src, { withFileTypes: true });

    // 复制每个文件和子目录
    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);

      if (entry.isDirectory()) {
        // 递归复制子目录
        this.copyFolderSync(srcPath, destPath);
      } else {
        // 复制文件
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }
}

// 导出单例
export const ipcManager = IPCManager.getInstance();
