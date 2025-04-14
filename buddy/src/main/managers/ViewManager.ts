/**
 * 视图管理器
 */
import { BrowserView } from 'electron';
import { is } from '@electron-toolkit/utils';
import { windowManager } from './WindowManager';
import { ViewBounds } from '@/types/plugin-view';
import { join } from 'path';
import { logger } from './LogManager';
import { createViewArgs } from '@/types/args';

const verbose = true;

export class ViewManager {
    private views: Map<string, BrowserView> = new Map();

    /**
     * 创建视图
     */
    public async createView(args: createViewArgs): Promise<ViewBounds> {
        if (!args) {
            throw new Error('创建视图的参数不能为空');
        }

        if (verbose) {
            logger.info('创建视图:', args);
        }

        const mainWindow = windowManager.getMainWindow();
        if (!mainWindow) {
            throw new Error('主窗口不存在');
        }

        // 创建视图
        const view = new BrowserView({
            webPreferences: {
                preload: join(__dirname, '../preload/plugin-preload.js'),
                sandbox: false,
                contextIsolation: true,
                nodeIntegration: false,
                webSecurity: true,
                devTools: is.dev,
            }
        });

        // 设置视图边界
        const mainWindowBounds = args || mainWindow.getBounds();
        const viewBounds = {
            x: mainWindowBounds.x || 0,
            y: mainWindowBounds.y || 0,
            width: mainWindowBounds.width,
            height: mainWindowBounds.height || Math.round(mainWindowBounds.height * 0.8),
        };

        view.setBounds(viewBounds);

        // 加载HTML内容，如果提供了content参数，则使用content，否则读取pagePath对应的文件内容
        const htmlContent = args.content ?? (args.pagePath ? require('fs').readFileSync(args.pagePath, 'utf-8') : '');
        view.webContents.loadURL(
            `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`
        );

        // 将视图添加到主窗口并保存到Map中
        mainWindow.addBrowserView(view);
        this.views.set(args.pagePath ?? "wild", view);

        return viewBounds;
    }

    /**
     * 销毁视图
     */
    public destroyView(pagePath: string): void {
        logger.info('销毁视图:', pagePath);

        const view = this.views.get(pagePath);
        if (!view) {
            logger.warn('试图销毁不存在的视图:', pagePath);
            return;
        }

        const mainWindow = windowManager.getMainWindow();
        if (!mainWindow) return;

        mainWindow.removeBrowserView(view);
        this.views.delete(pagePath);
        view.webContents.close();
    }

    /**
     * 销毁所有视图
     */
    public destroyAllViews(): void {
        for (const [pagePath] of this.views) {
            this.destroyView(pagePath);
        }
    }
}

// 导出单例实例
export const viewManager = new ViewManager();
