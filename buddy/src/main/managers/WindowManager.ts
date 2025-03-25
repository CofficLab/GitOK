/**
 * 窗口管理器
 * 负责创建、管理主窗口以及处理窗口相关配置和事件
 */
import { shell, BrowserWindow, screen, globalShortcut } from 'electron';
import { join } from 'path';
import { is } from '@electron-toolkit/utils';
import icon from '../../../resources/icon.png?asset';
import { configManager } from './ConfigManager';
import { appStateManager } from './StateManager';
import { BaseManager } from './BaseManager';
import { logger } from './LogManager';

class WindowManager extends BaseManager {
  private static instance: WindowManager;
  private mainWindow: BrowserWindow | null = null;
  private configManager = configManager;

  private constructor() {
    const windowConfig = configManager.getWindowConfig();
    super({
      name: 'WindowManager',
      enableLogging: windowConfig.enableLogging ?? true,
      logLevel: windowConfig.logLevel || 'info',
    });
  }

  /**
   * 获取 WindowManager 实例
   */
  public static getInstance(): WindowManager {
    if (!WindowManager.instance) {
      WindowManager.instance = new WindowManager();
    }
    return WindowManager.instance;
  }

  /**
   * 获取主窗口实例
   */
  getMainWindow(): BrowserWindow | null {
    return this.mainWindow;
  }

  /**
   * 创建主窗口
   */
  createWindow(): BrowserWindow {
    logger.info('开始创建主窗口');
    const windowConfig = this.configManager.getWindowConfig();
    const {
      showDebugToolbar,
      debugToolbarPosition = 'right',
      spotlightMode,
    } = windowConfig;

    logger.debug('窗口配置', { windowConfig });

    try {
      // 如果窗口已经存在，先销毁它
      if (this.mainWindow && !this.mainWindow.isDestroyed()) {
        logger.debug('销毁已存在的窗口');
        this.mainWindow.destroy();
      }

      // 创建窗口配置
      const windowOptions = this.createWindowOptions(windowConfig);

      // 创建浏览器窗口
      logger.debug('创建浏览器窗口', { options: windowOptions });
      this.mainWindow = new BrowserWindow(windowOptions);

      // 设置窗口事件处理
      this.setupWindowEvents(
        spotlightMode,
        showDebugToolbar,
        debugToolbarPosition
      );

      // 加载窗口内容
      this.loadWindowContent();

      // Spotlight模式下设置窗口失焦自动隐藏
      if (spotlightMode) {
        logger.debug('Spotlight模式：设置窗口失焦自动隐藏');
        this.setupBlurHandler();
      }

      logger.info('主窗口创建完成');
      return this.mainWindow;
    } catch (error) {
      throw new Error(this.handleError(error, '创建主窗口失败', true));
    }
  }

  /**
   * 创建窗口配置选项
   */
  private createWindowOptions(
    windowConfig: any
  ): Electron.BrowserWindowConstructorOptions {
    const { showTrafficLights, spotlightMode, spotlightSize, alwaysOnTop } =
      windowConfig;

    // 基本窗口配置
    const windowOptions: Electron.BrowserWindowConstructorOptions = {
      width: spotlightMode ? spotlightSize.width : 1200,
      height: spotlightMode ? spotlightSize.height : 1400,
      show: false,
      autoHideMenuBar: true,
      frame: showTrafficLights !== false,
      ...(process.platform === 'linux' ? { icon } : {}),
      webPreferences: {
        preload: join(__dirname, '../preload/app-preload.js'),
        sandbox: false,
        webSecurity: true,
        contextIsolation: true,
        nodeIntegration: false,
        devTools: is.dev,
        spellcheck: false,
        autoplayPolicy: 'document-user-activation-required',
      },
    };

    // Spotlight模式特定配置
    if (spotlightMode) {
      Object.assign(windowOptions, this.getSpotlightModeOptions(alwaysOnTop));
    } else if (process.platform === 'darwin') {
      // 常规模式下的macOS特定配置
      Object.assign(windowOptions, this.getMacOSOptions(showTrafficLights));
    }

    return windowOptions;
  }

  /**
   * 获取Spotlight模式的窗口选项
   */
  private getSpotlightModeOptions(
    alwaysOnTop: boolean
  ): Partial<Electron.BrowserWindowConstructorOptions> {
    return {
      frame: false,
      transparent: true,
      resizable: false,
      movable: true,
      center: true,
      alwaysOnTop,
      skipTaskbar: true,
      vibrancy: 'under-window',
      visualEffectState: 'active',
      roundedCorners: true,
    };
  }

  /**
   * 获取macOS特定的窗口选项
   */
  private getMacOSOptions(
    showTrafficLights: boolean
  ): Partial<Electron.BrowserWindowConstructorOptions> {
    return {
      titleBarStyle: showTrafficLights ? 'default' : 'hiddenInset',
      trafficLightPosition: showTrafficLights ? undefined : { x: -20, y: -20 },
    };
  }

  /**
   * 设置窗口事件
   */
  private setupWindowEvents(
    spotlightMode: boolean,
    showDebugToolbar: boolean,
    debugToolbarPosition: 'right' | 'bottom' | 'left' | 'undocked' | 'detach'
  ): void {
    if (!this.mainWindow) return;

    // 窗口加载完成后显示
    this.mainWindow.on('ready-to-show', () => {
      logger.debug('窗口准备就绪');
      if (!spotlightMode && this.mainWindow) {
        logger.info('显示主窗口');
        this.mainWindow.show();
      }

      // 根据配置决定是否打开开发者工具及其位置
      if (showDebugToolbar && this.mainWindow) {
        logger.debug(`打开开发者工具，位置: ${debugToolbarPosition}`);
        this.mainWindow.webContents.openDevTools({
          mode: debugToolbarPosition,
        });
      }
    });

    // 处理外部链接
    this.mainWindow.webContents.setWindowOpenHandler((details) => {
      logger.debug('拦截外部链接打开请求', { url: details.url });
      shell.openExternal(details.url);
      return { action: 'deny' };
    });
  }

  /**
   * 加载窗口内容
   */
  private loadWindowContent(): void {
    if (!this.mainWindow) return;

    if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
      logger.debug('开发模式：加载开发服务器URL', {
        url: process.env['ELECTRON_RENDERER_URL'],
      });
      this.mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL']);
    } else {
      const htmlPath = join(__dirname, '../../renderer/index.html');
      logger.debug('生产模式：加载本地HTML文件', { path: htmlPath });
      this.mainWindow.loadFile(htmlPath);
    }
  }

  /**
   * 设置窗口失焦处理
   */
  private setupBlurHandler(): void {
    if (!this.mainWindow) return;

    this.mainWindow.on('blur', () => {
      const windowConfig = this.configManager.getWindowConfig();
      if (
        this.mainWindow &&
        !this.mainWindow.isDestroyed() &&
        windowConfig.spotlightMode
      ) {
        this.handleWindowHide(true);
      }
    });
  }

  /**
   * 处理窗口隐藏
   * @param isBlur 是否是由失焦触发的隐藏
   */
  private handleWindowHide(isBlur: boolean = false): void {
    if (!this.mainWindow || this.mainWindow.isDestroyed()) return;

    // 使用标志记录最后一次显示的时间
    // @ts-ignore 忽略类型检查错误
    const lastShowTime = this.mainWindow.lastShowTime || 0;
    const now = Date.now();

    // @ts-ignore 忽略类型检查错误
    const justTriggered = this.mainWindow.justTriggered === true;

    // 如果是失焦触发的隐藏，且窗口刚刚显示，则忽略
    if (isBlur && (justTriggered || now - lastShowTime < 500)) {
      logger.debug('忽略失焦事件，窗口刚刚显示');
      return;
    }

    logger.info(
      isBlur ? '窗口失去焦点，自动隐藏' : '窗口当前可见，执行隐藏操作'
    );
    // 清除被覆盖的应用信息
    appStateManager.setOverlaidApp(null);
    this.mainWindow.hide();
  }

  /**
   * 处理窗口显示
   */
  private async handleWindowShow(): Promise<void> {
    if (!this.mainWindow || this.mainWindow.isDestroyed()) return;

    logger.info('窗口当前不可见，执行显示操作');

    // 更新当前活跃的应用信息
    if (process.platform === 'darwin') {
      appStateManager.updateActiveApp();
    }

    const windowConfig = this.configManager.getWindowConfig();

    // 获取当前鼠标所在屏幕的信息
    const cursorPoint = screen.getCursorScreenPoint();
    const currentDisplay = screen.getDisplayNearestPoint(cursorPoint);
    logger.debug('获取屏幕信息', {
      cursorPoint,
      display: {
        id: currentDisplay.id,
        bounds: currentDisplay.bounds,
        workArea: currentDisplay.workArea,
      },
    });

    // 计算窗口在当前显示器上的居中位置
    const windowWidth =
      windowConfig.spotlightMode && windowConfig.spotlightSize
        ? windowConfig.spotlightSize.width
        : this.mainWindow.getBounds().width;
    const windowHeight =
      windowConfig.spotlightMode && windowConfig.spotlightSize
        ? windowConfig.spotlightSize.height
        : this.mainWindow.getBounds().height;

    const x = Math.floor(
      currentDisplay.workArea.x +
        (currentDisplay.workArea.width - windowWidth) / 2
    );
    const y = Math.floor(
      currentDisplay.workArea.y +
        (currentDisplay.workArea.height - windowHeight) / 2
    );

    logger.debug('计算窗口位置', { windowWidth, windowHeight, x, y });

    // 记录显示时间戳
    // @ts-ignore 忽略类型检查错误
    this.mainWindow.lastShowTime = Date.now();
    // 设置额外的标志，表示窗口刚刚被通过快捷键打开
    // @ts-ignore 忽略类型检查错误
    this.mainWindow.justTriggered = true;
    logger.debug('设置窗口保护标志，防止立即失焦隐藏');

    // 窗口是否跟随桌面
    if (windowConfig.followDesktop) {
      await this.showWindowWithDesktopFollow(x, y);
    } else {
      await this.showWindowNormal(x, y);
    }
  }

  /**
   * 使用跟随桌面模式显示窗口
   */
  private async showWindowWithDesktopFollow(
    x: number,
    y: number
  ): Promise<void> {
    if (!this.mainWindow) return;

    logger.info('窗口配置为跟随桌面模式');

    if (process.platform === 'darwin') {
      await this.showWindowMacOS(x, y);
    } else {
      await this.showWindowOtherPlatforms(x, y);
    }
  }

  /**
   * macOS平台特定的窗口显示逻辑
   */
  private async showWindowMacOS(x: number, y: number): Promise<void> {
    if (!this.mainWindow) return;

    const windowConfig = this.configManager.getWindowConfig();
    logger.debug('跨桌面显示窗口：执行macOS特定优化');

    // 1. 先确保窗口不可见
    if (this.mainWindow.isVisible()) {
      logger.debug('窗口已可见，先隐藏');
      this.mainWindow.hide();
    }

    // 2. 设置位置
    logger.debug(`设置窗口位置 (${x}, ${y})`);
    this.mainWindow.setPosition(x, y);

    // 3. 使窗口在所有工作区可见，包括全屏应用
    logger.debug('设置窗口在所有工作区可见，包括全屏应用');
    this.mainWindow.setVisibleOnAllWorkspaces(true, {
      visibleOnFullScreen: true,
    });

    // 4. 确保窗口是顶层窗口
    const originalAlwaysOnTop = this.mainWindow.isAlwaysOnTop();
    logger.debug(`临时设置窗口置顶，原始状态: ${originalAlwaysOnTop}`);
    this.mainWindow.setAlwaysOnTop(true, 'screen-saver');

    // 5. 显示窗口
    logger.debug('显示窗口');
    this.mainWindow.show();

    // 6. 确保窗口聚焦
    logger.debug('聚焦窗口');
    this.mainWindow.focus();

    // 7. 还原到单桌面可见（重要：延迟执行这一步）
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
          logger.debug('将窗口设置回当前工作区可见');
          this.mainWindow.setVisibleOnAllWorkspaces(false);
          // 还原原始的置顶状态
          logger.debug(
            `还原窗口置顶状态: ${originalAlwaysOnTop || !!windowConfig.alwaysOnTop}`
          );
          this.mainWindow.setAlwaysOnTop(
            originalAlwaysOnTop || !!windowConfig.alwaysOnTop,
            windowConfig.alwaysOnTop ? 'pop-up-menu' : 'normal'
          );

          // 延迟500毫秒后重置justTriggered标志
          setTimeout(() => {
            if (this.mainWindow && !this.mainWindow.isDestroyed()) {
              // @ts-ignore 忽略类型检查错误
              this.mainWindow.justTriggered = false;
              logger.debug('窗口触发保护期已结束');
            }
          }, 500);
        }
        resolve();
      }, 300);
    });
  }

  /**
   * 其他平台的窗口显示逻辑
   */
  private async showWindowOtherPlatforms(x: number, y: number): Promise<void> {
    if (!this.mainWindow) return;

    const windowConfig = this.configManager.getWindowConfig();
    logger.debug('非macOS平台跨桌面显示窗口');

    // 设置窗口位置
    this.mainWindow.setPosition(x, y);

    // 确保在所有工作区可见，包括全屏应用
    this.mainWindow.setVisibleOnAllWorkspaces(true, {
      visibleOnFullScreen: true,
    });

    // 临时设置顶层状态
    const originalAlwaysOnTop = this.mainWindow.isAlwaysOnTop();
    this.mainWindow.setAlwaysOnTop(true);

    // 显示并聚焦窗口
    this.mainWindow.show();
    this.mainWindow.focus();

    // 还原设置
    this.mainWindow.setVisibleOnAllWorkspaces(false);
    this.mainWindow.setAlwaysOnTop(
      originalAlwaysOnTop || !!windowConfig.alwaysOnTop
    );

    // 延迟500毫秒后重置justTriggered标志
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
          // @ts-ignore 忽略类型检查错误
          this.mainWindow.justTriggered = false;
          logger.debug('窗口触发保护期已结束');
        }
        resolve();
      }, 500);
    });
  }

  /**
   * 普通模式显示窗口
   */
  private async showWindowNormal(x: number, y: number): Promise<void> {
    if (!this.mainWindow) return;

    logger.info('窗口配置为不跟随桌面模式');
    this.mainWindow.setPosition(x, y);
    this.mainWindow.show();
    this.mainWindow.focus();

    // 延迟500毫秒后重置justTriggered标志
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
          // @ts-ignore 忽略类型检查错误
          this.mainWindow.justTriggered = false;
          logger.debug('窗口触发保护期已结束');
        }
        resolve();
      }, 500);
    });
  }

  /**
   * 显示或隐藏主窗口
   */
  toggleMainWindow(): void {
    if (!this.mainWindow) {
      this.handleError(
        new Error('尝试切换窗口状态但没有主窗口实例'),
        '切换窗口状态失败'
      );
      return;
    }

    try {
      if (this.mainWindow.isVisible()) {
        this.handleWindowHide(false);
      } else {
        this.handleWindowShow();
      }
    } catch (error) {
      this.handleError(error, '切换窗口状态失败');
    }
  }

  /**
   * 设置全局快捷键
   */
  setupGlobalShortcut(): void {
    try {
      // 清除已有的快捷键
      logger.info('设置全局快捷键');
      logger.debug('清除已有的全局快捷键');
      globalShortcut.unregisterAll();

      const windowConfig = this.configManager.getWindowConfig();

      // 如果启用了Spotlight模式，注册全局快捷键
      if (windowConfig.spotlightMode && windowConfig.spotlightHotkey) {
        logger.debug(
          `尝试注册Spotlight模式全局快捷键: ${windowConfig.spotlightHotkey}`
        );
        if (
          !globalShortcut.register(
            windowConfig.spotlightHotkey,
            this.toggleMainWindow.bind(this)
          )
        ) {
          throw new Error(`注册快捷键失败: ${windowConfig.spotlightHotkey}`);
        }
        logger.info(`已成功注册全局快捷键: ${windowConfig.spotlightHotkey}`);
      } else {
        logger.debug('未启用Spotlight模式或未设置快捷键，跳过全局快捷键注册');
      }
    } catch (error) {
      this.handleError(error, '设置全局快捷键失败');
    }
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    try {
      logger.info('WindowManager清理资源');

      // 取消注册所有快捷键
      logger.debug('取消注册所有全局快捷键');
      globalShortcut.unregisterAll();

      // 关闭窗口（如果需要的话）
      if (this.mainWindow && !this.mainWindow.isDestroyed()) {
        logger.debug('关闭主窗口');
        this.mainWindow.close();
        this.mainWindow = null;
      }

      logger.info('WindowManager资源清理完成');
    } catch (error) {
      this.handleError(error, 'WindowManager资源清理失败');
    }
  }
}

// 导出单例
export const windowManager = WindowManager.getInstance();
