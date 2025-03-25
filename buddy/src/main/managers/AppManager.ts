/**
 * 应用管理器
 * 负责应用的生命周期管理、初始化和清理工作
 */
import { app, BrowserWindow } from 'electron';
import { electronApp, optimizer } from '@electron-toolkit/utils';
import { logger } from './LogManager';
import { windowManager } from './WindowManager';
import { pluginManager } from './PluginManager';
import { commandKeyManager } from './CommandKeyManager';
import { pluginViewManager } from './PluginViewManager';

export class AppManager {
  private mainWindow: BrowserWindow | null = null;

  /**
   * 设置应用事件监听器
   */
  private setupEventListeners(): void {
    // 处理第二个实例启动
    app.on('second-instance', () => {
      logger.info('检测到第二个应用实例启动，激活主窗口');
      this.mainWindow = windowManager.getMainWindow();
      if (this.mainWindow) {
        if (this.mainWindow.isMinimized()) this.mainWindow.restore();
        this.mainWindow.show();
        this.mainWindow.focus();
      }
    });

    // 窗口创建事件
    app.on('browser-window-created', (_, window) => {
      logger.debug('新窗口创建，设置窗口快捷键监听');
      optimizer.watchWindowShortcuts(window);
    });

    // macOS 激活事件
    app.on('activate', () => {
      logger.info('应用被激活');
      if (BrowserWindow.getAllWindows().length === 0) {
        logger.info('没有活动窗口，创建新窗口');
        this.mainWindow = windowManager.createWindow();
        commandKeyManager.setMainWindow(this.mainWindow);
      }
    });

    // 窗口全部关闭事件
    app.on('window-all-closed', () => {
      logger.info('所有窗口已关闭');
      if (process.platform !== 'darwin') {
        logger.info('非macOS平台，退出应用');
        app.quit();
      }
    });

    // 应用退出前事件
    app.on('will-quit', () => {
      logger.info('应用即将退出，执行清理工作');
      this.cleanup();
    });
  }

  /**
   * 初始化应用
   */
  private async initialize(): Promise<void> {
    logger.info('应用准备就绪');

    // 设置应用ID
    electronApp.setAppUserModelId('com.electron');

    // 创建主窗口
    this.mainWindow = windowManager.createWindow();

    // 设置Command键双击管理器
    logger.debug('设置Command键双击管理器窗口引用');
    commandKeyManager.setMainWindow(this.mainWindow);

    // macOS特定配置
    if (process.platform === 'darwin') {
      logger.info('在macOS上设置Command键双击监听器');
      const result = await commandKeyManager.setupCommandKeyListener(
        this.mainWindow
      );
      if (result.success) {
        logger.info('Command键双击监听器设置成功');
      } else {
        logger.warn('Command键双击监听器设置失败', {
          error: result.error,
        });
      }
    }

    // 设置全局快捷键
    logger.info('设置全局快捷键');
    windowManager.setupGlobalShortcut();

    // 初始化插件系统
    logger.info('初始化插件系统');
    await pluginManager.initialize();

    logger.info('应用初始化完成，等待用户交互');
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    logger.debug('清理窗口管理器资源');
    windowManager.cleanup();

    logger.debug('清理Command键监听器');
    commandKeyManager.cleanup();

    logger.debug('关闭所有插件视图窗口');
    pluginViewManager.closeAllViews();

    logger.info('应用清理完成，准备退出');
  }

  /**
   * 启动应用
   */
  public async start(): Promise<void> {
    this.setupEventListeners();

    await app.whenReady();
    await this.initialize();
  }
}

// 导出单例实例
export const appManager = new AppManager();
