/**
 * 应用管理器
 * 负责应用的生命周期管理、初始化和清理工作
 */
import { app, BrowserWindow } from 'electron';
import { electronApp, optimizer } from '@electron-toolkit/utils';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import { windowManager } from './WindowManager';
import { pluginManager } from './PluginManager';
import { commandKeyManager } from './CommandKeyManager';
import { ipcManager } from './IPCManager';

export class AppManager {
  private logger: Logger;
  private mainWindow: BrowserWindow | null = null;
  private isDevelopment: boolean;

  constructor() {
    this.isDevelopment = !app.isPackaged;
    const config = configManager.getConfig().app || {};
    this.logger = new Logger('AppManager', {
      enabled: config.enableLogging,
      level: config.logLevel,
    });
  }

  /**
   * 禁用不必要的特性和警告
   */
  private disableUnnecessaryFeatures(): void {
    if (this.isDevelopment) {
      // 开发模式下的配置
      app.commandLine.appendSwitch(
        'disable-features',
        [
          'Autofill',
          'AutofillServerCommunication',
          'ChromeWhatsNewUI',
          'CalculateNativeWinOcclusion',
          'HardwareMediaKeyHandling',
          'MediaSessionService',
          'DesktopCaptureMacV2',
          'WarnBeforeQuitting',
        ].join(',')
      );

      // 禁用各种试验性功能
      app.commandLine.appendSwitch('disable-site-isolation-trials');
      app.commandLine.appendSwitch('disable-ipc-flooding-protection');

      // 禁用不必要的日志
      app.commandLine.appendSwitch('force-renderer-accessibility', 'disabled');
      app.commandLine.appendSwitch('log-level', '3');
    } else {
      app.commandLine.appendSwitch('disable-logging');
    }
  }

  /**
   * 检查是否是单实例运行
   */
  private checkSingleInstance(): boolean {
    this.logger.debug('检查应用实例');
    const isSingleInstance = app.requestSingleInstanceLock();

    if (!isSingleInstance) {
      this.logger.info('检测到应用的另一个实例已在运行，退出当前实例');
      app.quit();
      process.exit(0);
    }

    return true;
  }

  /**
   * 设置应用事件监听器
   */
  private setupEventListeners(): void {
    // 处理第二个实例启动
    app.on('second-instance', () => {
      this.logger.info('检测到第二个应用实例启动，激活主窗口');
      this.mainWindow = windowManager.getMainWindow();
      if (this.mainWindow) {
        if (this.mainWindow.isMinimized()) this.mainWindow.restore();
        this.mainWindow.show();
        this.mainWindow.focus();
      }
    });

    // 窗口创建事件
    app.on('browser-window-created', (_, window) => {
      this.logger.debug('新窗口创建，设置窗口快捷键监听');
      optimizer.watchWindowShortcuts(window);
    });

    // macOS 激活事件
    app.on('activate', () => {
      this.logger.info('应用被激活');
      if (BrowserWindow.getAllWindows().length === 0) {
        this.logger.info('没有活动窗口，创建新窗口');
        this.mainWindow = windowManager.createWindow();
        commandKeyManager.setMainWindow(this.mainWindow);
      }
    });

    // 窗口全部关闭事件
    app.on('window-all-closed', () => {
      this.logger.info('所有窗口已关闭');
      if (process.platform !== 'darwin') {
        this.logger.info('非macOS平台，退出应用');
        app.quit();
      }
    });

    // 应用退出前事件
    app.on('will-quit', () => {
      this.logger.info('应用即将退出，执行清理工作');
      this.cleanup();
    });
  }

  /**
   * 初始化应用
   */
  private async initialize(): Promise<void> {
    this.logger.info('应用准备就绪');

    // 设置应用ID
    electronApp.setAppUserModelId('com.electron');
    this.logger.debug('设置应用用户模型ID');

    // 创建主窗口
    this.logger.info('创建主窗口');
    this.mainWindow = windowManager.createWindow();

    // 设置Command键双击管理器
    this.logger.debug('设置Command键双击管理器窗口引用');
    commandKeyManager.setMainWindow(this.mainWindow);

    // macOS特定配置
    const windowConfig = configManager.getWindowConfig();
    if (process.platform === 'darwin' && !windowConfig.spotlightMode) {
      this.logger.info('在macOS上设置Command键双击监听器');
      const result = await commandKeyManager.setupCommandKeyListener(
        this.mainWindow
      );
      if (result.success) {
        this.logger.info('Command键双击监听器设置成功');
      } else {
        this.logger.warn('Command键双击监听器设置失败', {
          error: result.error,
        });
      }
    }

    // 设置全局快捷键
    this.logger.info('设置全局快捷键');
    windowManager.setupGlobalShortcut();

    // 初始化插件系统
    this.logger.info('初始化插件系统');
    await pluginManager.initialize();

    // 注册IPC处理器
    this.logger.debug('注册IPC处理器');
    ipcManager.registerHandlers();

    this.logger.info('应用初始化完成，等待用户交互');
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    this.logger.debug('清理窗口管理器资源');
    windowManager.cleanup();

    this.logger.debug('清理Command键监听器');
    commandKeyManager.cleanup();

    this.logger.info('应用清理完成，准备退出');
  }

  /**
   * 启动应用
   */
  public async start(): Promise<void> {
    this.disableUnnecessaryFeatures();
    this.checkSingleInstance();
    this.setupEventListeners();

    await app.whenReady();
    await this.initialize();
  }
}

// 导出单例实例
export const appManager = new AppManager();
