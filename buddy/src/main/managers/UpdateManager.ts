/**
 * 更新管理器
 * 负责应用的自动更新功能
 */
import { autoUpdater } from 'electron-updater';
import { dialog, BrowserWindow } from 'electron';
import { logger } from './LogManager';

// 导入后面要创建的事件发送器
import { sendUpdateEvent } from '../handlers/update_router';

export class UpdateManager {
  private mainWindow: BrowserWindow | null = null;

  /**
   * 初始化更新管理器
   * @param mainWindow 主窗口引用
   */
  public initialize(mainWindow: BrowserWindow): void {
    this.mainWindow = mainWindow;

    // 配置日志输出
    autoUpdater.logger = logger;

    // 配置允许草稿和预发布版本
    autoUpdater.allowDowngrade = true;
    autoUpdater.allowPrerelease = true;

    // 在开发环境中强制启用更新配置
    if (process.env.NODE_ENV === 'development') {
      autoUpdater.forceDevUpdateConfig = false;
    }

    // 设置更新事件监听
    this.setupEventListeners();

    // 启动时检查更新
    setTimeout(() => {
      this.checkForUpdates();
    }, 3000); // 延迟3秒检查，避免应用启动时阻塞
  }

  /**
   * 设置更新事件监听
   */
  private setupEventListeners(): void {
    // 检查更新出错
    autoUpdater.on('error', (error) => {
      logger.error('更新检查失败', { error: error.message });
      sendUpdateEvent('error', { message: error.message });
    });

    // 检查更新
    autoUpdater.on('checking-for-update', () => {
      logger.info('正在检查更新...');
      sendUpdateEvent('checking-for-update', {});
    });

    // 发现可用更新
    autoUpdater.on('update-available', (info) => {
      logger.info('发现新版本', { version: info.version });
      sendUpdateEvent('update-available', info);
      this.notifyUpdateAvailable(info);
    });

    // 没有可用更新
    autoUpdater.on('update-not-available', (info) => {
      logger.info('当前已是最新版本', { version: info.version });
      sendUpdateEvent('update-not-available', info);
    });

    // 更新下载进度
    autoUpdater.on('download-progress', (progressObj) => {
      logger.debug('下载更新中', {
        percent: progressObj.percent,
        speed: progressObj.bytesPerSecond,
      });
      sendUpdateEvent('download-progress', progressObj);
    });

    // 更新下载完成
    autoUpdater.on('update-downloaded', (info) => {
      logger.info('更新下载完成', { version: info.version });
      sendUpdateEvent('update-downloaded', info);
      this.notifyUpdateReady(info);
    });
  }

  /**
   * 通知用户有可用更新
   */
  private notifyUpdateAvailable(info: any): void {
    if (!this.mainWindow) return;

    dialog
      .showMessageBox(this.mainWindow, {
        type: 'info',
        title: '发现新版本',
        message: `发现新版本 ${info.version}`,
        detail: '新版本已经发布，是否开始下载？',
        buttons: ['立即下载', '稍后再说'],
        cancelId: 1,
      })
      .then(({ response }) => {
        if (response === 0) {
          autoUpdater.downloadUpdate();
        }
      });
  }

  /**
   * 通知用户更新已准备好安装
   */
  private notifyUpdateReady(info: any): void {
    if (!this.mainWindow) return;

    dialog
      .showMessageBox(this.mainWindow, {
        type: 'info',
        title: '安装更新',
        message: `${info.version} 已准备就绪`,
        detail: '更新已下载，应用将重启并安装',
        buttons: ['现在安装', '稍后安装'],
        cancelId: 1,
      })
      .then(({ response }) => {
        if (response === 0) {
          // 重启并安装
          autoUpdater.quitAndInstall(false, true);
        }
      });
  }

  /**
   * 手动检查更新
   */
  public checkForUpdates(): void {
    logger.info('手动检查更新');
    autoUpdater.checkForUpdates().catch((error) => {
      logger.error('手动检查更新失败', { error: error.message });
    });
  }
}

// 导出单例
export const updateManager = new UpdateManager();
