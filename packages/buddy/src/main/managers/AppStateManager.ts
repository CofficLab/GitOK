/**
 * 应用状态管理器
 * 负责监控应用的激活状态以及其他应用的状态
 */
import { app } from 'electron';
import { configManager } from './ConfigManager';
import { BaseManager } from './BaseManager';
import { ActiveApplication } from '@coffic/active-app-monitor';

class AppStateManager extends BaseManager {
  private static instance: AppStateManager;
  private overlaidApp: ActiveApplication | null = null;

  private constructor() {
    const { enableLogging, logLevel } = configManager.getWindowConfig();
    super({
      name: 'AppStateManager',
      enableLogging: enableLogging ?? true,
      logLevel: logLevel || 'info',
    });

    // 监听应用激活事件
    this.setupAppStateListeners();
  }

  /**
   * 获取 AppStateManager 实例
   */
  public static getInstance(): AppStateManager {
    if (!AppStateManager.instance) {
      AppStateManager.instance = new AppStateManager();
    }
    return AppStateManager.instance;
  }

  /**
   * 设置应用状态监听器
   */
  private setupAppStateListeners(): void {
    // 监听应用激活事件
    app.on('activate', () => {
      this.logger.info('应用被激活');
      this.emit('app-activated');
    });

    // 监听应用失去焦点事件
    app.on('browser-window-blur', () => {
      this.logger.info('应用失去焦点');
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
    if (app) {
      this.logger.info(`记录被覆盖的应用: ${app.name} (${app.bundleId})`);
    } else {
      this.logger.info('清除被覆盖的应用信息');
    }
    this.emit('overlaid-app-changed', app);
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
      this.handleError(error, '应用状态管理器清理失败');
    }
  }
}

// 导出单例
export const appStateManager = AppStateManager.getInstance();
