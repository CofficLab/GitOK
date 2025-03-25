/**
 * 应用状态管理器
 * 负责监控应用的激活状态以及其他应用的状态
 */
import { app } from 'electron';
import { configManager } from './ConfigManager';
import { BaseManager } from './BaseManager';
import {
  ActiveApplication,
  getFrontmostApplication,
} from '@coffic/active-app-monitor';
import { stateLogger as logger } from './LogManager';

class StateManager extends BaseManager {
  private static instance: StateManager;
  private overlaidApp: ActiveApplication | null = null;

  private constructor() {
    const { enableLogging, logLevel } = configManager.getWindowConfig();
    super({
      name: 'StateManager',
      enableLogging: enableLogging ?? true,
      logLevel: logLevel || 'info',
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
   * 设置应用状态监听器
   */
  private setupAppStateListeners(): void {
    // 监听应用激活事件
    app.on('activate', () => {
      this.emit('app-activated');
    });

    // 监听应用失去焦点事件
    app.on('browser-window-blur', () => {
      this.emit('app-deactivated');
    });
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
    this.emit('overlaid-app-changed', app);
  }

  /**
   * 获取当前活跃的应用信息
   */
  getCurrentActiveApp(): ActiveApplication | null {
    if (process.platform !== 'darwin') {
      return null;
    }

    try {
      const frontmostApp = getFrontmostApplication();
      if (frontmostApp) {
        logger.info(
          `当前活跃应用: ${frontmostApp.name} (${frontmostApp.bundleId})`
        );
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
      app.removeAllListeners('window-all-closed');
    } catch (error) {
      this.handleError(error, '状态管理器清理失败');
    }
  }
}

// 导出单例
export const appStateManager = StateManager.getInstance();
