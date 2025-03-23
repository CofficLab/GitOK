/**
 * 插件视图管理器
 * 负责创建、管理和销毁插件视图窗口
 * 支持两种模式：
 * 1. 嵌入式视图(embedded) - 创建BrowserWindow但不显示，通过webContents注入到主窗口
 * 2. 独立窗口视图(window) - 创建独立的BrowserWindow并显示
 */
import { BrowserWindow, app, BrowserView } from 'electron';
import { is } from '@electron-toolkit/utils';
import { join } from 'path';
import { EventEmitter } from 'events';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import { windowManager } from './WindowManager';
import { pluginManager } from './PluginManager';

// 视图模式
export type ViewMode = 'embedded' | 'window';

interface PluginViewOptions {
  viewId: string;
  url: string;
  viewMode?: ViewMode;
  bounds?: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

class PluginViewManager extends EventEmitter {
  private static instance: PluginViewManager;
  private viewWindows: Map<string, BrowserWindow> = new Map();
  private viewBrowserViews: Map<string, BrowserView> = new Map();
  private logger: Logger;

  private constructor() {
    super();
    // 从配置文件中读取日志配置
    const config = configManager.getConfig().plugins || {};
    this.logger = new Logger('PluginViewManager', {
      enabled: config.enableLogging ?? true,
      level: config.logLevel || 'info',
    });
    this.logger.info('PluginViewManager 初始化');
  }

  /**
   * 获取 PluginViewManager 实例
   */
  public static getInstance(): PluginViewManager {
    if (!PluginViewManager.instance) {
      PluginViewManager.instance = new PluginViewManager();
    }
    return PluginViewManager.instance;
  }

  /**
   * 创建插件视图窗口
   * @param options 视图选项
   * @returns 主窗口的位置和大小信息，用于定位新窗口
   */
  public async createView(options: PluginViewOptions): Promise<{
    x: number;
    y: number;
    width: number;
    height: number;
  } | null> {
    const { viewId, url, viewMode = 'embedded' } = options;

    // 如果已存在同ID的窗口，先销毁它
    if (this.viewWindows.has(viewId) || this.viewBrowserViews.has(viewId)) {
      this.logger.debug(`销毁已存在的插件视图: ${viewId}`);
      await this.destroyView(viewId);
    }

    // 获取主窗口的位置和大小信息
    const mainWindow = windowManager.getMainWindow();
    if (!mainWindow) {
      this.logger.error('主窗口不存在，无法创建插件视图');
      return null;
    }

    const mainWindowBounds = mainWindow.getBounds();
    this.logger.debug(`主窗口位置信息: `, { bounds: mainWindowBounds });

    // 解析动作ID
    let actionId = '';
    if (url.startsWith('plugin-view://')) {
      actionId = url.substring(13);

      // 删除可能存在的前导斜杠
      if (actionId.startsWith('/')) {
        actionId = actionId.substring(1);
      }
    }

    if (!actionId) {
      throw new Error(`无效的插件视图URL: ${url}`);
    }

    // 准备HTML内容
    let htmlContent = '';
    try {
      this.logger.debug(`获取动作视图内容: ${actionId}`);
      htmlContent = await pluginManager.getActionView(actionId);
      this.logger.debug(`获取到HTML内容，长度: ${htmlContent.length} 字节`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`获取动作视图内容失败:`, { error: errorMessage });
      throw new Error(`获取动作视图内容失败: ${errorMessage}`);
    }

    try {
      // 获取动作信息，判断是否需要启用开发者工具
      const actions = await pluginManager.getPluginActions();
      const actionInfo = actions.find((a) => a.id === actionId);
      const devToolsEnabled = actionInfo?.devTools === true;

      this.logger.debug(`获取动作信息: ${JSON.stringify(actionInfo || {})}`);

      if (viewMode === 'window') {
        // 创建独立窗口视图
        return this.createWindowView(
          viewId,
          htmlContent,
          mainWindowBounds,
          devToolsEnabled
        );
      } else {
        // 创建嵌入式视图
        return this.createEmbeddedView(
          viewId,
          htmlContent,
          mainWindowBounds,
          devToolsEnabled
        );
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`创建插件视图失败:`, { error: errorMessage });
      throw new Error(`创建插件视图失败: ${errorMessage}`);
    }
  }

  /**
   * 创建独立窗口视图
   * @param viewId 视图ID
   * @param htmlContent HTML内容
   * @param mainWindowBounds 主窗口位置信息
   * @param devToolsEnabled 是否启用开发者工具
   * @returns 主窗口位置信息
   */
  private async createWindowView(
    viewId: string,
    htmlContent: string,
    mainWindowBounds: { x: number; y: number; width: number; height: number },
    devToolsEnabled: boolean
  ): Promise<{ x: number; y: number; width: number; height: number }> {
    const mainWindow = windowManager.getMainWindow();
    if (!mainWindow) {
      throw new Error('主窗口不存在');
    }

    // 创建插件视图窗口
    const viewWindow = new BrowserWindow({
      width: 600,
      height: mainWindowBounds.height,
      x: mainWindowBounds.x + mainWindowBounds.width,
      y: mainWindowBounds.y,
      parent: mainWindow,
      show: false,
      frame: true,
      webPreferences: {
        preload: join(__dirname, '../preload/plugin-preload.js'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false,
        webSecurity: true,
        devTools: is.dev || devToolsEnabled,
      },
    });

    // 处理窗口关闭事件
    viewWindow.on('closed', () => {
      this.logger.debug(`插件视图窗口已关闭: ${viewId}`);
      this.viewWindows.delete(viewId);
      this.emit('view-closed', viewId);
    });

    // 存储窗口实例
    this.viewWindows.set(viewId, viewWindow);
    this.logger.info(`插件视图窗口已创建: ${viewId}`);

    // 加载HTML内容
    this.logger.debug(`加载HTML内容到窗口，长度: ${htmlContent.length} 字节`);
    await viewWindow.loadURL(
      `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`
    );

    // 如果需要启用开发者工具，延迟打开
    if (devToolsEnabled) {
      this.logger.info(`动作指定了启用开发者工具，延迟打开`);
      setTimeout(() => {
        try {
          if (
            !viewWindow.isDestroyed() &&
            viewWindow.webContents &&
            !viewWindow.webContents.isDevToolsOpened()
          ) {
            this.logger.info(`实际打开开发者工具: ${viewId}`);
            viewWindow.webContents.openDevTools();
          }
        } catch (e) {
          this.logger.error(`打开开发者工具失败: ${e}`);
        }
      }, 1000);
    }

    return mainWindowBounds;
  }

  /**
   * 创建嵌入式视图
   * @param viewId 视图ID
   * @param htmlContent HTML内容
   * @param mainWindowBounds 主窗口位置信息
   * @param devToolsEnabled 是否启用开发者工具
   * @returns 主窗口位置信息
   */
  private async createEmbeddedView(
    viewId: string,
    htmlContent: string,
    mainWindowBounds: { x: number; y: number; width: number; height: number },
    devToolsEnabled: boolean
  ): Promise<{ x: number; y: number; width: number; height: number }> {
    const mainWindow = windowManager.getMainWindow();
    if (!mainWindow) {
      throw new Error('主窗口不存在');
    }

    // 创建BrowserView之前先检查是否已存在，如果存在则先移除
    try {
      // 查找并移除可能已经存在的视图
      this.viewBrowserViews.forEach((existingView, existingViewId) => {
        if (existingViewId === viewId) {
          try {
            mainWindow.removeBrowserView(existingView);
            this.viewBrowserViews.delete(existingViewId);
            this.logger.debug(`移除已存在的嵌入式视图: ${existingViewId}`);
          } catch (e) {
            this.logger.warn(`移除已存在视图失败: ${e}`);
          }
        }
      });
    } catch (e) {
      this.logger.warn(`清理已存在视图时出错: ${e}`);
    }

    // 创建BrowserView
    const view = new BrowserView({
      webPreferences: {
        preload: join(__dirname, '../preload/plugin-preload.js'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false,
        webSecurity: true,
        devTools: is.dev || devToolsEnabled,
      },
    });

    // 存储视图实例
    this.viewBrowserViews.set(viewId, view);
    this.logger.info(`嵌入式视图已创建: ${viewId}`);

    // 设置默认边界，确保视图有一个合理的初始大小
    const defaultBounds = {
      x: 0,
      y: 0,
      width: mainWindowBounds.width,
      height: Math.round(mainWindowBounds.height * 0.8),
    };
    view.setBounds(defaultBounds);
    this.logger.debug(
      `设置嵌入式视图初始边界: ${JSON.stringify(defaultBounds)}`
    );

    // 加载HTML内容
    this.logger.debug(
      `加载HTML内容到嵌入式视图，长度: ${htmlContent.length} 字节`
    );
    try {
      await view.webContents.loadURL(
        `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`
      );
      this.logger.debug(`HTML内容已加载到嵌入式视图: ${viewId}`);
    } catch (loadError) {
      this.logger.error(`加载HTML内容到嵌入式视图失败: ${loadError}`);
      throw new Error(`加载HTML内容到嵌入式视图失败: ${loadError}`);
    }

    // 向主窗口发送事件，通知嵌入式视图已创建
    if (!mainWindow.isDestroyed()) {
      mainWindow.webContents.send('embedded-view-created', { viewId });
      this.logger.info(`通知渲染进程嵌入式视图已创建: ${viewId}`);
    }

    // 如果需要启用开发者工具，延迟打开
    if (devToolsEnabled) {
      this.logger.info(`动作指定了启用开发者工具，延迟打开`);
      setTimeout(() => {
        try {
          if (view.webContents && !view.webContents.isDevToolsOpened()) {
            this.logger.info(`实际打开开发者工具: ${viewId}`);
            view.webContents.openDevTools();
          }
        } catch (e) {
          this.logger.error(`打开开发者工具失败: ${e}`);
        }
      }, 1000);
    }

    return mainWindowBounds;
  }

  /**
   * 显示插件视图窗口
   * @param viewId 视图ID
   * @param bounds 窗口位置和大小
   * @returns 是否成功
   */
  public async showView(
    viewId: string,
    bounds?: { x: number; y: number; width: number; height: number }
  ): Promise<boolean> {
    this.logger.debug(
      `尝试显示视图: ${viewId}, 边界: ${JSON.stringify(bounds || {})}`
    );

    // 首先检查独立窗口视图
    const viewWindow = this.viewWindows.get(viewId);
    if (viewWindow) {
      try {
        // 如果提供了新的位置和大小，更新窗口
        if (bounds) {
          viewWindow.setBounds(bounds);
        }
        viewWindow.show();
        this.logger.info(`插件视图窗口已显示: ${viewId}`);
        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`显示插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    }

    // 然后检查嵌入式视图
    const view = this.viewBrowserViews.get(viewId);
    if (view) {
      try {
        const mainWindow = windowManager.getMainWindow();
        if (!mainWindow) {
          this.logger.error('主窗口不存在，无法显示嵌入式视图');
          return false;
        }

        // 确保边界值存在且合理
        if (!bounds || !this.isValidBounds(bounds)) {
          this.logger.warn(
            `嵌入式视图边界值不合理，使用默认值: ${JSON.stringify(bounds || {})}`
          );
          // 默认设置为主窗口的中央区域
          const mainBounds = mainWindow.getBounds();
          const width = Math.min(600, mainBounds.width - 100);
          const height = Math.min(400, mainBounds.height - 100);
          const x = Math.floor((mainBounds.width - width) / 2);
          const y = Math.floor((mainBounds.height - height) / 2);
          bounds = { x, y, width, height };
        }

        this.logger.debug(`实际使用的边界值: ${JSON.stringify(bounds)}`);

        // 先移除所有现有的BrowserView
        try {
          // 只移除当前要显示的视图，而不是移除所有视图
          // 这样可以避免主窗口闪烁
          const existingViews = mainWindow.getBrowserViews();
          const viewToRemove = existingViews.find((v) => v === view);
          if (viewToRemove) {
            this.logger.debug(`移除视图准备重新添加: ${viewId}`);
            mainWindow.removeBrowserView(viewToRemove);
          }
        } catch (removeError) {
          this.logger.warn(`移除视图失败: ${removeError}`);
        }

        // 设置视图的边界
        view.setBounds(bounds);
        this.logger.debug(`已设置视图边界: ${JSON.stringify(bounds)}`);

        // 将BrowserView添加到主窗口
        mainWindow.addBrowserView(view);
        this.logger.info(`嵌入式视图已添加到主窗口: ${viewId}`);

        // 立即刷新视图
        try {
          view.webContents.invalidate();
        } catch (invalidateError) {
          this.logger.warn(`刷新视图失败: ${invalidateError}`);
        }

        // 通知渲染进程显示嵌入式视图
        if (!mainWindow.isDestroyed()) {
          mainWindow.webContents.send('show-embedded-view', { viewId, bounds });
          this.logger.info(`通知渲染进程显示嵌入式视图: ${viewId}`);
        }

        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`显示嵌入式视图失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    }

    this.logger.error(`未找到插件视图: ${viewId}`);
    return false;
  }

  /**
   * 检查边界值是否合法
   * @param bounds 边界值
   * @returns 是否合法
   */
  private isValidBounds(bounds: {
    x: number;
    y: number;
    width: number;
    height: number;
  }): boolean {
    return (
      typeof bounds.x === 'number' &&
      typeof bounds.y === 'number' &&
      typeof bounds.width === 'number' &&
      typeof bounds.height === 'number' &&
      bounds.width > 10 &&
      bounds.height > 10 &&
      bounds.x >= 0 &&
      bounds.y >= 0
    );
  }

  /**
   * 隐藏插件视图窗口
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public hideView(viewId: string): boolean {
    // 检查独立窗口视图
    const viewWindow = this.viewWindows.get(viewId);
    if (viewWindow) {
      try {
        viewWindow.hide();
        this.logger.info(`插件视图窗口已隐藏: ${viewId}`);
        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`隐藏插件视图窗口失败:`, { error: errorMessage });
        return false;
      }
    }

    // 检查嵌入式视图
    const view = this.viewBrowserViews.get(viewId);
    if (view) {
      try {
        const mainWindow = windowManager.getMainWindow();
        if (!mainWindow) {
          this.logger.error('主窗口不存在，无法隐藏嵌入式视图');
          return false;
        }

        // 从主窗口移除BrowserView
        mainWindow.removeBrowserView(view);
        this.logger.info(`嵌入式视图已从主窗口移除: ${viewId}`);

        // 通知渲染进程隐藏嵌入式视图
        if (!mainWindow.isDestroyed()) {
          mainWindow.webContents.send('hide-embedded-view', { viewId });
          this.logger.info(`通知渲染进程隐藏嵌入式视图: ${viewId}`);
        }

        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`隐藏嵌入式视图失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    }

    this.logger.error(`未找到插件视图: ${viewId}`);
    return false;
  }

  /**
   * 销毁插件视图窗口
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public async destroyView(viewId: string): Promise<boolean> {
    // 检查独立窗口视图
    const viewWindow = this.viewWindows.get(viewId);
    if (viewWindow) {
      try {
        // 关闭窗口
        viewWindow.destroy();
        this.viewWindows.delete(viewId);
        this.logger.info(`插件视图窗口已销毁: ${viewId}`);
        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`销毁插件视图窗口失败:`, { error: errorMessage });
        return false;
      }
    }

    // 检查嵌入式视图
    const view = this.viewBrowserViews.get(viewId);
    if (view) {
      try {
        // 销毁视图
        // BrowserView没有直接的destroy方法，需要先从主窗口移除
        const mainWindow = windowManager.getMainWindow();
        if (mainWindow && !mainWindow.isDestroyed()) {
          // 从主窗口移除BrowserView
          mainWindow.removeBrowserView(view);
        }
        // 将其引用置为null
        this.viewBrowserViews.delete(viewId);
        this.logger.info(`嵌入式视图已销毁: ${viewId}`);

        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`销毁嵌入式视图失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    }

    // 没有找到视图，也算作成功
    this.logger.warn(`未找到插件视图，无需销毁: ${viewId}`);
    return true;
  }

  /**
   * 切换插件视图窗口的开发者工具
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public toggleDevTools(viewId: string): boolean {
    // 检查独立窗口视图
    const viewWindow = this.viewWindows.get(viewId);
    if (viewWindow) {
      try {
        // 检查窗口状态
        if (viewWindow.isDestroyed()) {
          this.logger.error(`插件视图窗口已销毁: ${viewId}`);
          return false;
        }

        // 确保webContents存在
        if (!viewWindow.webContents) {
          this.logger.error(`插件视图窗口webContents不存在: ${viewId}`);
          return false;
        }

        const isOpen = viewWindow.webContents.isDevToolsOpened();
        this.logger.debug(
          `开发者工具当前状态: ${isOpen ? '已打开' : '未打开'}`
        );

        if (isOpen) {
          this.logger.info(`关闭开发者工具: ${viewId}`);
          viewWindow.webContents.closeDevTools();
        } else {
          this.logger.info(`打开开发者工具: ${viewId}`);
          viewWindow.webContents.openDevTools();
        }

        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`切换开发者工具失败:`, { error: errorMessage });
        return false;
      }
    }

    // 检查嵌入式视图
    const view = this.viewBrowserViews.get(viewId);
    if (view) {
      try {
        // 确保webContents存在
        if (!view.webContents) {
          this.logger.error(`嵌入式视图webContents不存在: ${viewId}`);
          return false;
        }

        const isOpen = view.webContents.isDevToolsOpened();
        this.logger.debug(
          `嵌入式视图开发者工具当前状态: ${isOpen ? '已打开' : '未打开'}`
        );

        if (isOpen) {
          this.logger.info(`关闭嵌入式视图开发者工具: ${viewId}`);
          view.webContents.closeDevTools();
        } else {
          this.logger.info(`打开嵌入式视图开发者工具: ${viewId}`);
          view.webContents.openDevTools();
        }

        return true;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`切换嵌入式视图开发者工具失败: ${viewId}`, {
          error: errorMessage,
        });
        return false;
      }
    }

    this.logger.error(`未找到插件视图: ${viewId}`);
    return false;
  }

  /**
   * 关闭所有插件视图窗口
   */
  public closeAllViews(): void {
    this.logger.info(`关闭所有插件视图窗口: ${this.viewWindows.size} 个`);
    for (const [viewId, window] of this.viewWindows.entries()) {
      try {
        if (!window.isDestroyed()) {
          window.destroy();
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`关闭插件视图窗口失败: ${viewId}`, {
          error: errorMessage,
        });
      }
    }
    this.viewWindows.clear();
  }
}

// 导出单例
export const pluginViewManager = PluginViewManager.getInstance();
