/**
 * Command键双击管理器
 * 负责处理macOS平台Command键双击的监听和响应
 */
import { BrowserWindow } from 'electron';
import { EventEmitter } from 'events';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';

// 声明CommandKeyListener类型但不导入
// @ts-ignore 忽略CommandKeyListener模块导入错误
type CommandKeyListener = {
  on(event: string, callback: Function): void;
  start(): Promise<boolean>;
  stop(): boolean;
  isListening(): boolean;
};

class CommandKeyManager extends EventEmitter {
  private static instance: CommandKeyManager;
  private commandKeyListener: CommandKeyListener | null = null;
  private mainWindow: BrowserWindow | null = null;
  private logger: Logger;

  private constructor() {
    super();
    // 从配置文件中读取日志配置
    const config = configManager.getConfig().command || {};
    this.logger = new Logger('CommandKeyManager', {
      enabled: config.enableLogging,
      level: config.logLevel,
    });
    this.logger.info('CommandKeyManager 初始化');
  }

  /**
   * 获取 CommandKeyManager 实例
   */
  public static getInstance(): CommandKeyManager {
    if (!CommandKeyManager.instance) {
      CommandKeyManager.instance = new CommandKeyManager();
    }
    return CommandKeyManager.instance;
  }

  /**
   * 设置主窗口引用
   */
  setMainWindow(window: BrowserWindow): void {
    this.mainWindow = window;
    this.logger.info('设置主窗口引用');
  }

  /**
   * 设置Command键双击监听器
   */
  async setupCommandKeyListener(
    window: BrowserWindow
  ): Promise<{ success: boolean; error?: string }> {
    try {
      this.logger.info('开始设置Command键双击监听器');

      // 如果监听器已经存在，先停止它
      if (this.commandKeyListener) {
        this.logger.debug('停止已存在的监听器');
        this.commandKeyListener.stop();
        this.commandKeyListener = null;
      }

      // 动态导入模块
      try {
        this.logger.debug('尝试导入@coffic/command-key-listener模块');
        const module = await import('@coffic/command-key-listener');
        const CommandKeyListenerClass = module.CommandKeyListener;

        // 创建新的监听器实例
        this.commandKeyListener = new CommandKeyListenerClass();

        if (!this.commandKeyListener) {
          const errMsg = '创建Command键双击监听器实例失败';
          this.logger.error(errMsg);
          return { success: false, error: errMsg };
        }

        // 监听双击Command键事件
        this.logger.debug('注册Command键双击事件处理');
        this.commandKeyListener.on('command-double-press', () => {
          if (window && !window.isDestroyed()) {
            // 切换窗口状态：如果窗口聚焦则隐藏，否则显示并聚焦
            if (window.isFocused()) {
              // 窗口当前在前台，隐藏它
              this.logger.info('Command键双击 - 窗口隐藏');
              window.hide();
              // 发送事件到渲染进程通知窗口已隐藏
              window.webContents.send('window-hidden-by-command');
            } else {
              // 窗口当前不在前台，显示并聚焦它
              this.logger.info('Command键双击 - 窗口显示并聚焦');
              window.show();
              window.focus();
              // 发送事件到渲染进程通知窗口已激活
              window.webContents.send('window-activated-by-command');
            }
            // 无论如何都发送命令键双击事件
            window.webContents.send('command-double-pressed');
          }
        });

        // 异步启动监听器
        this.logger.debug('开始启动监听器');
        const result = await this.commandKeyListener.start();
        if (result) {
          this.logger.info('Command键双击监听器启动成功');
          return { success: true };
        } else {
          const errMsg = 'Command键双击监听器启动失败';
          this.logger.error(errMsg);
          return { success: false, error: errMsg };
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error('加载Command键双击监听器模块失败', {
          error: errorMessage,
        });
        return {
          success: false,
          error: errorMessage,
        };
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error('初始化Command键双击监听器失败', {
        error: errorMessage,
      });
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  /**
   * 启用Command键双击功能
   */
  async enableCommandKeyListener(): Promise<{
    success: boolean;
    already?: boolean;
    starting?: boolean;
    reason?: string;
  }> {
    if (process.platform !== 'darwin') {
      this.logger.warn('尝试在非macOS平台启用Command键双击功能');
      return { success: false, reason: '此功能仅在macOS上可用' };
    }

    if (this.commandKeyListener && this.isListening()) {
      this.logger.debug('Command键双击监听器已在运行中');
      return { success: true, already: true };
    }

    this.logger.info('尝试启用Command键双击功能');
    const mainWindow =
      this.mainWindow ||
      BrowserWindow.getFocusedWindow() ||
      BrowserWindow.getAllWindows()[0];
    if (mainWindow) {
      const result = await this.setupCommandKeyListener(mainWindow);
      // 由于设置过程是异步的，无法立即获取结果，返回启动中状态
      if (result.success) {
        this.logger.info('Command键双击监听器启动中');
        return { success: true, starting: true };
      } else {
        this.logger.error('Command键双击监听器启动失败', {
          reason: result.error,
        });
        return { success: false, reason: result.error };
      }
    }

    this.logger.error('没有可用窗口，无法启用Command键双击功能');
    return { success: false, reason: '没有可用窗口' };
  }

  /**
   * 禁用Command键双击功能
   */
  disableCommandKeyListener(): { success: boolean; already?: boolean } {
    if (this.commandKeyListener) {
      this.logger.info('禁用Command键双击功能');
      const result = this.commandKeyListener.stop();
      this.commandKeyListener = null;
      return { success: result };
    }
    this.logger.debug('Command键双击监听器已禁用或不存在');
    return { success: true, already: true };
  }

  /**
   * 检查Command键双击监听器是否运行中
   */
  isListening(): boolean {
    return !!this.commandKeyListener && this.commandKeyListener.isListening();
  }

  /**
   * 清理资源
   */
  cleanup(): void {
    this.logger.info('清理Command键双击监听器资源');
    if (this.commandKeyListener) {
      this.commandKeyListener.stop();
      this.commandKeyListener = null;
    }
  }
}

// 导出单例
export const commandKeyManager = CommandKeyManager.getInstance();
