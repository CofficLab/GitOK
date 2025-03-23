/**
 * Electron 主进程入口文件
 * 负责应用生命周期管理和各种管理器的初始化与协调
 */
import { app, BrowserWindow } from 'electron';
import { electronApp, optimizer } from '@electron-toolkit/utils';
import { initLogger } from './utils/initLogger';
import { Logger } from './utils/Logger';
import { configManager } from './managers/ConfigManager';
import { windowManager } from './managers/WindowManager';
import { pluginManager } from './managers/PluginManager';
import { commandKeyManager } from './managers/CommandKeyManager';
import { ipcManager } from './managers/IPCManager';

// 在应用启动最开始就禁用所有不需要的特性
if (!app.isPackaged) {
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
  app.commandLine.appendSwitch('log-level', '3'); // 只显示错误和严重错误
} else {
  // 生产模式下完全禁用日志
  app.commandLine.appendSwitch('disable-logging');
}

// 首先初始化日志系统
const isDevelopment = !app.isPackaged;
initLogger(isDevelopment);

// 创建主应用日志记录器
const config = configManager.getConfig().main || {};
const logger = new Logger('Main', {
  enabled: config.enableLogging,
  level: config.logLevel,
});

// 主窗口引用 - 通过窗口管理器获取
let mainWindow: BrowserWindow | null = null;

// 防止多实例运行
logger.debug('检查应用实例');
const isSingleInstance = app.requestSingleInstanceLock();
if (!isSingleInstance) {
  logger.info('检测到应用的另一个实例已在运行，退出当前实例');
  app.quit();
  process.exit(0);
}

// 处理第二个实例启动
app.on('second-instance', () => {
  logger.info('检测到第二个应用实例启动，激活主窗口');
  // 重复启动时，显示现有窗口
  mainWindow = windowManager.getMainWindow();
  if (mainWindow) {
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.show();
    mainWindow.focus();
  }
});

// 应用准备就绪
app.whenReady().then(async () => {
  logger.info('应用准备就绪');

  // 设置应用ID
  electronApp.setAppUserModelId('com.electron');
  logger.debug('设置应用用户模型ID');

  // 应用优化
  app.on('browser-window-created', (_, window) => {
    logger.debug('新窗口创建，设置窗口快捷键监听');
    optimizer.watchWindowShortcuts(window);
  });

  // 创建窗口
  logger.info('创建主窗口');
  mainWindow = windowManager.createWindow();

  // 设置Command键双击管理器的主窗口引用
  logger.debug('设置Command键双击管理器窗口引用');
  commandKeyManager.setMainWindow(mainWindow);

  // 在macOS上设置Command键双击监听器（非Spotlight模式下）
  const windowConfig = configManager.getWindowConfig();
  if (process.platform === 'darwin' && !windowConfig.spotlightMode) {
    logger.info('在macOS上设置Command键双击监听器');
    const result = await commandKeyManager.setupCommandKeyListener(mainWindow);
    if (result.success) {
      logger.info('Command键双击监听器设置成功');
    } else {
      logger.warn('Command键双击监听器设置失败', { error: result.error });
    }
  }

  // 设置全局快捷键
  logger.info('设置全局快捷键');
  windowManager.setupGlobalShortcut();

  // 初始化插件系统
  logger.info('初始化插件系统');
  await pluginManager.initialize();

  // 注册IPC处理器
  logger.debug('注册IPC处理器');
  ipcManager.registerHandlers();

  // 当应用被激活时（macOS特性）
  app.on('activate', function () {
    logger.info('应用被激活');
    // 在macOS上，当点击dock图标且没有其他窗口打开时，通常会重新创建一个窗口
    if (BrowserWindow.getAllWindows().length === 0) {
      logger.info('没有活动窗口，创建新窗口');
      mainWindow = windowManager.createWindow();
      commandKeyManager.setMainWindow(mainWindow);
    }
  });

  logger.info('应用初始化完成，等待用户交互');
});

// 窗口关闭时处理
app.on('window-all-closed', () => {
  logger.info('所有窗口已关闭');
  if (process.platform !== 'darwin') {
    logger.info('非macOS平台，退出应用');
    app.quit();
  }
});

// 应用退出前的清理工作
app.on('will-quit', () => {
  logger.info('应用即将退出，执行清理工作');

  // 清理窗口管理器资源
  logger.debug('清理窗口管理器资源');
  windowManager.cleanup();

  // 清理Command键监听器
  logger.debug('清理Command键监听器');
  commandKeyManager.cleanup();

  logger.info('应用清理完成，准备退出');
});
