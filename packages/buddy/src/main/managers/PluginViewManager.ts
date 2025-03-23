/**
 * 插件视图管理器
 * 负责创建、管理和销毁插件视图窗口
 */
import { BrowserWindow, app } from 'electron';
import { is } from '@electron-toolkit/utils';
import { join } from 'path';
import { EventEmitter } from 'events';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import { windowManager } from './WindowManager';
import { pluginManager } from './PluginManager';

interface PluginViewOptions {
  viewId: string;
  url: string;
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
    const { viewId, url } = options;

    // 如果已存在同ID的窗口，先销毁它
    if (this.viewWindows.has(viewId)) {
      this.logger.debug(`销毁已存在的插件视图窗口: ${viewId}`);
      await this.destroyView(viewId);
    }

    // 获取主窗口的位置和大小信息
    const mainWindow = windowManager.getMainWindow();
    if (!mainWindow) {
      this.logger.error('主窗口不存在，无法创建插件视图窗口');
      return null;
    }

    const mainWindowBounds = mainWindow.getBounds();
    this.logger.debug(`主窗口位置信息: `, { bounds: mainWindowBounds });

    try {
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
          devTools: is.dev,
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

      // 获取动作ID
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

      this.logger.debug(`处理动作ID: ${actionId}`);

      // 从插件管理器获取HTML内容
      try {
        this.logger.debug(`获取动作视图内容: ${actionId}`);
        const html = await pluginManager.getActionView(actionId);

        // 加载HTML内容
        this.logger.debug(`加载HTML内容，长度: ${html.length} 字节`);
        await viewWindow.loadURL(
          `data:text/html;charset=utf-8,${encodeURIComponent(html)}`
        );
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`获取或加载动作视图内容失败:`, {
          error: errorMessage,
        });
        throw new Error(`获取或加载动作视图内容失败: ${errorMessage}`);
      }

      return mainWindowBounds;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`创建插件视图窗口失败:`, { error: errorMessage });
      throw new Error(`创建插件视图窗口失败: ${errorMessage}`);
    }
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
    const viewWindow = this.viewWindows.get(viewId);
    if (!viewWindow) {
      this.logger.error(`未找到插件视图窗口: ${viewId}`);
      return false;
    }

    try {
      // 如果提供了位置信息，设置窗口位置和大小
      if (bounds) {
        this.logger.debug(`设置插件视图窗口位置: `, { bounds });
        viewWindow.setBounds(bounds);
      }

      // 显示窗口
      viewWindow.show();
      this.logger.info(`插件视图窗口已显示: ${viewId}`);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`显示插件视图窗口失败:`, { error: errorMessage });
      return false;
    }
  }

  /**
   * 隐藏插件视图窗口
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public hideView(viewId: string): boolean {
    const viewWindow = this.viewWindows.get(viewId);
    if (!viewWindow) {
      this.logger.error(`未找到插件视图窗口: ${viewId}`);
      return false;
    }

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

  /**
   * 销毁插件视图窗口
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public async destroyView(viewId: string): Promise<boolean> {
    const viewWindow = this.viewWindows.get(viewId);
    if (!viewWindow) {
      this.logger.warn(`未找到插件视图窗口: ${viewId}`);
      return false;
    }

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

  /**
   * 切换插件视图窗口的开发者工具
   * @param viewId 视图ID
   * @returns 是否成功
   */
  public toggleDevTools(viewId: string): boolean {
    const viewWindow = this.viewWindows.get(viewId);
    if (!viewWindow) {
      this.logger.error(`未找到插件视图窗口: ${viewId}`);
      return false;
    }

    try {
      if (viewWindow.webContents.isDevToolsOpened()) {
        viewWindow.webContents.closeDevTools();
      } else {
        viewWindow.webContents.openDevTools();
      }
      this.logger.info(`已切换插件视图窗口的开发者工具: ${viewId}`);
      return true;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`切换开发者工具失败:`, { error: errorMessage });
      return false;
    }
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
