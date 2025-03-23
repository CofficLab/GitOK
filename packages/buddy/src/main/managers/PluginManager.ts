/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 */
import { BrowserWindow, BrowserView, ipcMain } from 'electron';
import { join } from 'path';
import { EventEmitter } from 'events';
import { ConfigManager } from './ConfigManager';
import { Logger } from '../utils/Logger';

const debug = false;

export class PluginManager extends EventEmitter {
  private pluginViews = new Map<string, BrowserView>();
  private configManager: ConfigManager;
  private logger: Logger;

  constructor(configManager: ConfigManager) {
    super();
    this.configManager = configManager;
    this.logger = new Logger('PluginManager');
    if (debug) {
      this.logger.info('PluginManager 初始化');
    }
  }

  /**
   * 初始化插件系统
   */
  async initialize(): Promise<void> {
    try {
      if (debug) {
        this.logger.info('开始初始化插件系统');
      }
      // 这里可以放置一些插件系统初始化代码
      // 例如加载插件配置、预加载插件等
      await import('../plugins/index.js').then(({ initializePluginSystem }) => {
        return initializePluginSystem();
      });

      if (debug) {
        this.logger.info('插件系统初始化完成');
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('插件系统初始化失败', { error: errorMessage });
    }
  }

  /**
   * 注册插件视图相关的IPC处理函数
   */
  registerPluginViewHandlers(): void {
    if (debug) {
      this.logger.info('注册插件视图相关的IPC处理函数');
    }

    // 创建插件视图
    ipcMain.handle('create-plugin-view', async (event, { viewId, url }) => {
      if (debug) {
        this.logger.debug('处理IPC请求: create-plugin-view', { viewId, url });
      }
      const window = BrowserWindow.fromWebContents(event.sender);
      if (!window) {
        this.logger.error('无法找到主窗口');
        return { success: false, error: '无法找到主窗口' };
      }

      try {
        const view = this.createPluginView(window, viewId, url);
        if (!view) {
          this.logger.error('创建视图失败', { viewId, url });
          return { success: false, error: '创建视图失败' };
        }
        return { success: true, viewId };
      } catch (error) {
        return {
          success: false,
          error: error instanceof Error ? error.message : String(error),
        };
      }
    });

    // 显示插件视图
    ipcMain.handle('show-plugin-view', async (event, { viewId, bounds }) => {
      if (debug) {
        this.logger.debug('处理IPC请求: show-plugin-view', { viewId, bounds });
      }
      const window = BrowserWindow.fromWebContents(event.sender);
      if (!window) {
        this.logger.error('无法找到主窗口');
        return { success: false, error: '无法找到主窗口' };
      }

      const view = this.pluginViews.get(viewId);
      if (!view) {
        this.logger.error(`视图不存在: ${viewId}`);
        return { success: false, error: `视图不存在: ${viewId}` };
      }

      try {
        // 显示视图
        if (debug) {
          this.logger.debug(`显示视图: ${viewId}`);
        }
        window.setBrowserView(view);

        // 设置视图边界
        const viewBounds = bounds || {
          x: Math.floor(window.getBounds().width * 0.25), // 水平居中（左侧缩进25%）
          y: Math.floor(window.getBounds().height * 0.15), // 垂直方向稍微往下一点
          width: Math.floor(window.getBounds().width * 0.5), // 宽度为窗口的1/2
          height: Math.floor(window.getBounds().height * 0.6), // 高度为窗口的60%，留出状态栏空间
        };

        // 记录视图位置和大小
        if (debug) {
          this.logger.debug(`设置视图边界: ${JSON.stringify(viewBounds)}`);
        }
        view.setBounds(viewBounds);

        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`显示视图失败: ${viewId}`, { error: errorMessage });
        return {
          success: false,
          error: errorMessage,
        };
      }
    });

    // 隐藏插件视图
    ipcMain.handle('hide-plugin-view', async (event, { viewId }) => {
      this.logger.debug('处理IPC请求: hide-plugin-view', { viewId });
      const window = BrowserWindow.fromWebContents(event.sender);
      if (!window) {
        this.logger.error('无法找到主窗口');
        return { success: false, error: '无法找到主窗口' };
      }

      try {
        // 移除当前的BrowserView
        this.logger.debug(`隐藏视图: ${viewId}`);
        window.setBrowserView(null);
        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`隐藏视图失败: ${viewId}`, { error: errorMessage });
        return {
          success: false,
          error: errorMessage,
        };
      }
    });

    // 关闭并销毁插件视图
    ipcMain.handle('destroy-plugin-view', async (event, { viewId }) => {
      this.logger.debug('处理IPC请求: destroy-plugin-view', { viewId });
      const window = BrowserWindow.fromWebContents(event.sender);
      if (!window) {
        this.logger.error('无法找到主窗口');
        return { success: false, error: '无法找到主窗口' };
      }

      const view = this.pluginViews.get(viewId);
      if (!view) {
        this.logger.warn(`试图销毁不存在的视图: ${viewId}`);
        return { success: false, error: `视图不存在: ${viewId}` };
      }

      try {
        // 首先隐藏视图
        this.logger.debug(`开始销毁视图: ${viewId}`);
        window.setBrowserView(null);

        // 从窗口中移除视图并从Map中删除
        window.removeBrowserView(view);
        this.pluginViews.delete(viewId);
        this.logger.info(`视图已销毁: ${viewId}`);

        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`销毁视图失败: ${viewId}`, { error: errorMessage });
        return {
          success: false,
          error: errorMessage,
        };
      }
    });

    // 处理插件视图发送给主应用的消息
    ipcMain.on('plugin-to-host', (event, { channel, data }) => {
      // 找到发送消息的视图
      const pluginViewId = this.findPluginViewIdByWebContents(event.sender);
      if (!pluginViewId) {
        if (debug) {
          console.error('无法找到发送消息的插件视图');
        }
        return;
      }

      // 找到主窗口
      const mainWindow = BrowserWindow.getAllWindows().find((win) =>
        win
          .getBrowserViews()
          .some((view) => view.webContents.id === event.sender.id)
      );

      if (!mainWindow) {
        if (debug) {
          console.error('无法找到主窗口');
        }
        return;
      }

      // 转发消息到主应用
      mainWindow.webContents.send('plugin-message', {
        viewId: pluginViewId,
        channel,
        data,
      });
    });

    // 处理从主应用发送到插件视图的消息
    ipcMain.on('host-to-plugin', (event, { viewId, channel, data }) => {
      // 找到对应的视图
      const view = this.pluginViews.get(viewId);
      if (!view) {
        if (debug) {
          console.error(`找不到插件视图: ${viewId}`);
        }
        return;
      }

      // 转发消息到插件视图
      view.webContents.send('host-to-plugin', {
        channel,
        data,
      });
    });

    // 处理插件视图准备就绪的消息
    ipcMain.on('plugin-view-ready', (event) => {
      const viewId = this.findPluginViewIdByWebContents(event.sender);
      if (!viewId) {
        if (debug) {
          console.error('无法找到发送ready消息的插件视图');
        }
        return;
      }

      if (debug) {
        console.log(`插件视图准备就绪: ${viewId}`);
      }

      // 可以在这里执行一些初始化操作，比如发送插件信息
    });

    // 处理插件视图请求关闭的消息
    ipcMain.on('plugin-close-view', (event) => {
      const viewId = this.findPluginViewIdByWebContents(event.sender);
      if (!viewId) {
        if (debug) {
          console.error('无法找到请求关闭的插件视图');
        }
        return;
      }

      if (debug) {
        console.log(`插件视图请求关闭: ${viewId}`);
      }

      // 找到主窗口
      const mainWindow = BrowserWindow.getAllWindows().find((win) =>
        win
          .getBrowserViews()
          .some((view) => view.webContents.id === event.sender.id)
      );

      if (!mainWindow) {
        if (debug) {
          console.error('无法找到主窗口');
        }
        return;
      }

      // 通知主应用插件视图请求关闭
      mainWindow.webContents.send('plugin-close-requested', {
        viewId,
      });
    });

    // 获取插件信息
    ipcMain.handle('get-plugin-info', (event) => {
      const viewId = this.findPluginViewIdByWebContents(event.sender);
      if (!viewId) {
        return { success: false, error: '无法找到插件视图' };
      }

      return {
        success: true,
        viewId,
        // 可以在这里添加更多插件相关信息
      };
    });

    // 切换插件视图的开发者工具
    ipcMain.handle('toggle-plugin-devtools', async (event, { viewId }) => {
      if (debug) {
        this.logger.debug('处理IPC请求: toggle-plugin-devtools', { viewId });
      }
      const view = this.pluginViews.get(viewId);
      if (!view) {
        this.logger.error(`视图不存在: ${viewId}`);
        return { success: false, error: `视图不存在: ${viewId}` };
      }

      try {
        if (view.webContents.isDevToolsOpened()) {
          view.webContents.closeDevTools();
          if (debug) {
            this.logger.info(`已关闭插件视图的开发者工具: ${viewId}`);
          }
        } else {
          // 获取窗口配置
          const windowConfig = this.configManager.getWindowConfig();
          view.webContents.openDevTools({
            mode: windowConfig.debugToolbarPosition || 'right',
          });
          if (debug) {
            this.logger.info(`已打开插件视图的开发者工具: ${viewId}`);
          }
        }
        return { success: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`切换插件视图开发者工具失败: ${viewId}`, {
          error: errorMessage,
        });
        return {
          success: false,
          error: errorMessage,
        };
      }
    });
  }

  /**
   * 创建插件视图
   * @param mainWindow 主窗口
   * @param viewId 视图ID
   * @param url 加载的URL或HTML文件路径
   */
  private createPluginView(
    mainWindow: BrowserWindow,
    viewId: string,
    url: string
  ): BrowserView | null {
    try {
      if (debug) {
        this.logger.info(`创建插件视图`, { viewId, url });
      }

      // 创建BrowserView而不是WebContentsView
      const view = new BrowserView({
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          sandbox: true,
          preload: join(__dirname, '../../preload/plugin-preload.js'),
          // 允许开发者工具
          devTools: true,
        },
      });

      // 存储视图引用
      this.pluginViews.set(viewId, view);

      // 加载URL或HTML内容
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // 加载远程URL
        view.webContents.loadURL(url);
      } else if (
        url.startsWith('<html') ||
        url.startsWith('<!DOCTYPE') ||
        url.startsWith('data:')
      ) {
        // 直接加载HTML内容
        view.webContents.loadURL(
          `data:text/html;charset=utf-8,${encodeURIComponent(url)}`
        );
      } else {
        // 加载文件 - 这里假设url是相对于应用根目录的路径
        try {
          // 直接从插件获取HTML内容
          import('../plugins/index.js').then(async ({ pluginManager }) => {
            try {
              // 使用ActionView获取的viewPath对应的viewId来请求HTML内容
              // 假设viewId格式为 view_timestamp_actionId_random
              const parts = viewId.split('_');
              const actionId = parts.length >= 3 ? parts[2] : null;

              if (!actionId) {
                if (debug) {
                  console.log('无法从视图ID中提取动作ID:', viewId);
                }
                const errorHtml = `<html><body><h1>错误</h1><p>无法加载视图: 无效的视图ID</p></body></html>`;
                view.webContents.loadURL(
                  `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
                );
                return;
              }

              if (debug) {
                console.log(`尝试获取动作 ${actionId} 的视图内容`);
              }

              // 获取所有动作
              const actions = await pluginManager.getAllActions();
              const action = actions.find((a) => a.id === actionId);

              if (!action) {
                if (debug) {
                  console.log(`未找到动作: ${actionId}`);
                }
                const errorHtml = `<html><body><h1>错误</h1><p>无法加载视图: 未找到动作</p></body></html>`;
                view.webContents.loadURL(
                  `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
                );
                return;
              }

              // 使用插件API获取视图内容
              const html = await pluginManager.getActionViewContent(actionId);
              if (debug) {
                console.log(`成功获取HTML内容，长度: ${html.length}`);
              }
              view.webContents.loadURL(
                `data:text/html;charset=utf-8,${encodeURIComponent(html)}`
              );
            } catch (error: any) {
              console.error('获取视图内容失败:', error);
              const errorHtml = `<html><body><h1>错误</h1><p>加载视图失败: ${error?.message || '未知错误'}</p></body></html>`;
              view.webContents.loadURL(
                `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
              );
            }
          });
        } catch (error: any) {
          console.error(`加载视图内容失败:`, error);
          const errorHtml = `<html><body><h1>错误</h1><p>加载视图失败: ${error?.message || '未知错误'}</p></body></html>`;
          view.webContents.loadURL(
            `data:text/html;charset=utf-8,${encodeURIComponent(errorHtml)}`
          );
        }
      }

      // 监听视图销毁事件，清理引用
      view.webContents.on('destroyed', () => {
        if (debug) {
          console.log(`插件视图已销毁: ${viewId}`);
        }
        this.pluginViews.delete(viewId);
      });

      // 添加DOM就绪事件监听，在内容加载后自动打开开发者工具
      view.webContents.on('dom-ready', () => {
        if (debug) {
          console.log(`插件视图DOM已就绪: ${viewId}`);
        }

        // 获取窗口配置
        const windowConfig = this.configManager.getWindowConfig();

        // 如果配置启用了开发者工具，则打开它
        if (windowConfig.showDebugToolbar) {
          view.webContents.openDevTools({
            mode: windowConfig.debugToolbarPosition || 'right',
          });
        }
      });

      return view;
    } catch (error) {
      console.error(`创建插件视图失败:`, error);
      return null;
    }
  }

  /**
   * 根据WebContents查找对应的插件视图ID
   */
  private findPluginViewIdByWebContents(
    webContents: Electron.WebContents
  ): string | null {
    for (const [viewId, view] of this.pluginViews.entries()) {
      if (view.webContents.id === webContents.id) {
        return viewId;
      }
    }
    return null;
  }
}
