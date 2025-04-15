/**
 * 应用状态管理器
 * 负责监控应用的激活状态以及其他应用的状态
 */
import { app, BrowserWindow } from 'electron';
import { BaseManager } from './BaseManager';
import {
  ActiveApplication,
  getFrontmostApplication,
} from '@coffic/active-app-monitor';
import { logger } from './LogManager';
import { AppEvents, SuperApp } from '@coffic/buddy-types';

const verbose = false;

class StateManager extends BaseManager {
  private static instance: StateManager;
  private overlaidApp: SuperApp | null = null;

  private constructor() {
    super({
      name: 'StateManager',
      enableLogging: true,
      logLevel: 'info',
    });

    // 监听应用激活事件
    this.setupAppStateListeners();
  }

  /**
   * 获取 StateManager 实例
   */
  public static getInstance(): StateManager {
    if (!StateManager.instance) {
      StateManager.instance = new StateManager();
    }
    return StateManager.instance;
  }

  /**
   * 统一发送事件到主进程和所有渲染进程
   * @param channel 事件名称
   * @param args 事件参数
   */
  private emitAndBroadcast(channel: string, ...args: any[]): void {
    // 用于主进程内部的模块间通信
    this.emit(channel, ...args);

    // 用于向所有渲染进程广播事件
    this.broadcastToAllWindows(channel, ...args);
  }

  /**
   * 设置应用状态监听器
   */
  private setupAppStateListeners(): void {
    // 监听应用激活事件
    app.on('activate', () => {
      logger.info('应用激活事件');
      this.emitAndBroadcast(AppEvents.ActIVATED);
    });

    // 监听应用失去焦点事件
    app.on('browser-window-blur', () => {
      this.emitAndBroadcast(AppEvents.DEACTIVATED);
    });

    // 添加窗口获得焦点事件监听
    app.on('browser-window-focus', () => {
      this.emitAndBroadcast(AppEvents.ActIVATED);
    });
  }

  /**
   * 向所有窗口广播事件
   * @param channel 事件名称
   * @param args 事件参数
   */
  private broadcastToAllWindows(channel: string, ...args: any[]): void {
    try {
      const windows = BrowserWindow.getAllWindows();
      for (const win of windows) {
        if (!win.isDestroyed()) {
          win.webContents.send(channel, ...args);
        }
      }
    } catch (error) {
      this.handleError(error, '向渲染进程广播事件失败');
    }
  }

  /**
   * 获取当前被覆盖的应用信息
   */
  getOverlaidApp(): ActiveApplication | null {
    return this.overlaidApp;
  }

  /**
   * 设置当前被覆盖的应用信息
   */
  setOverlaidApp(app: ActiveApplication | null): void {
    this.overlaidApp = app;
    this.emitAndBroadcast(AppEvents.OVERLAID_APP_CHANGED, app);
  }

  /**
   * 获取当前活跃的应用信息
   */
  getCurrentActiveApp(): ActiveApplication | null {
    logger.debug('获取当前活跃应用信息');
    if (process.platform !== 'darwin') {
      return null;
    }

    try {
      const frontmostApp = getFrontmostApplication();
      if (frontmostApp) {

        if (verbose) {
          logger.debug('当前活跃应用信息:', frontmostApp);
        }

        return frontmostApp;
      }
    } catch (error) {
      logger.error('获取当前活跃应用信息失败', { error });
    }
    return null;
  }

  /**
   * 更新当前活跃的应用信息
   * 获取当前活跃的应用并更新状态
   */
  updateActiveApp(): void {
    if (process.platform !== 'darwin') {
      return;
    }

    const frontmostApp = this.getCurrentActiveApp();
    if (frontmostApp) {
      logger.debug('更新被覆盖的应用信息');
      this.setOverlaidApp(frontmostApp);
    } else {
      logger.debug('无法获取当前活跃的应用信息');
      this.setOverlaidApp(null);
    }
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    try {
      // 移除所有事件监听器
      this.removeAllListeners();
      // 移除应用状态监听器
      app.removeAllListeners('activate');
      app.removeAllListeners('browser-window-blur');
      app.removeAllListeners('browser-window-focus');
      app.removeAllListeners('window-all-closed');
    } catch (error) {
      this.handleError(error, '状态管理器清理失败');
    }
  }
}

// 导出单例
export const appStateManager = StateManager.getInstance();
