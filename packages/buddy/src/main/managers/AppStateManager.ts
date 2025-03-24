/**
 * 应用状态管理器
 * 负责监控应用的激活状态以及其他应用的状态
 */
import { app } from 'electron';
import { EventEmitter } from 'events';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import {
  getFrontmostApplication,
  ActiveApplication,
} from '@coffic/active-app-monitor';

class AppStateManager extends EventEmitter {
  private static instance: AppStateManager;
  private logger: Logger;
  private overlaidApp: ActiveApplication | null = null;

  private constructor() {
    super();
    const { enableLogging, logLevel } = configManager.getWindowConfig();
    this.logger = new Logger('AppStateManager', {
      enabled: enableLogging ?? true,
      level: logLevel || 'info',
    });
    this.logger.info('AppStateManager 初始化');

    // 测试原生模块
    this.testNativeModule();

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
   * 测试原生模块
   */
  testNativeModule(): void {
    try {
      const frontmostApp = getFrontmostApplication();
      if (frontmostApp) {
        this.logger.info('原生模块测试: 获取前台应用信息成功', frontmostApp);
      } else {
        this.logger.warn('原生模块测试: 未能获取前台应用信息');
      }
    } catch (error) {
      this.logger.error('原生模块测试失败', { error });
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
  cleanup(): void {
    this.logger.info('AppStateManager清理资源');
    this.removeAllListeners();
    this.overlaidApp = null;
  }
}

// 导出单例
export const appStateManager = AppStateManager.getInstance();
