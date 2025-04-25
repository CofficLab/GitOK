/**
 * 视图管理器
 */
import { WebContentsView } from 'electron';
import { is } from '@electron-toolkit/utils';
import { windowManager } from './WindowManager.js';
import { join } from 'path';
import { logger } from './LogManager.js';
import { ViewBounds } from '@coffic/buddy-types';
import { createViewArgs } from '@/types/args.js';
import { readFileSync } from 'fs';

const verbose = false;

export class ViewManager {
    private views: Map<string, WebContentsView> = new Map();

    /**
     * 创建视图
     */
    public async createView(args: createViewArgs): Promise<WebContentsView> {
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

        // 销毁已经存在的视图
        if (this.views.has(args.pagePath ?? "wild")) {
            this.destroyView(args.pagePath ?? "wild");
        }

        // 创建视图
        const view = new WebContentsView({
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
        const viewBounds = {
            x: args.x,
            y: args.y,
            width: args.width,
            height: args.height,
        };

        view.setBounds(viewBounds);

        // 设置视图自动调整大小
        mainWindow.on("resize", () => {
            logger.info('主窗口调整大小，调整视图大小');
        });

        mainWindow.on("maximize", () => {
            logger.info('主窗口最大化，调整视图大小');
        });

        mainWindow.on("unmaximize", () => {
            logger.info('主窗口取消最大化，调整视图大小');
        })

        mainWindow.on("minimize", () => {
            logger.info('主窗口最小化，调整视图大小');
        })

        mainWindow.on("restore", () => {
            logger.info('主窗口还原，调整视图大小');
        })

        mainWindow.on("close", () => {
            logger.info('主窗口关闭，销毁所有视图');
            this.destroyAllViews();
        })

        // 加载HTML内容，读取pagePath对应的文件内容, 如果文件不存在，则加载默认的HTML内容
        let htmlContent = '';
        try {
            htmlContent = readFileSync(args.pagePath, 'utf-8');
        } catch (error) {
            logger.warn('加载HTML内容失败:', error);
            htmlContent = "加载HTML内容失败: " + error;
        }

        view.webContents.loadURL(
            `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`
        );

        // 将视图添加到主窗口并保存到Map中
        mainWindow.contentView.addChildView(view);
        this.views.set(args.pagePath ?? "wild", view);

        logger.info('视图创建成功，当前视图个数', this.views.size);

        return view;
    }

    /**
     * 销毁视图
     */
    public destroyView(pagePath: string): void {
        if (verbose) {
            logger.info('destroy view:', pagePath);
        }

        const view = this.views.get(pagePath);
        if (!view) {
            logger.warn('试图销毁不存在的视图:', pagePath);
            return;
        }

        const mainWindow = windowManager.getMainWindow();
        if (!mainWindow) return;

        mainWindow.contentView.removeChildView(view);
        this.views.delete(pagePath);
        view.webContents.close();
    }

    /**
     * 更新视图位置
     * @param pagePath 视图标识
     * @param bounds 新的视图边界
     */
    public updateViewPosition(pagePath: string, bounds: ViewBounds): void {
        if (verbose) {
            logger.info('update view position:', pagePath, bounds);
        }

        const view = this.views.get(pagePath);
        if (!view) {
            logger.warn('试图更新不存在的视图:', pagePath);
            return;
        }

        view.setBounds(bounds);
    }

    public async upsertView(args: createViewArgs): Promise<void> {
        if (verbose) {
            logger.info('upsert view:', args);
        }

        const view = this.views.get(args.pagePath) ?? await this.createView(args)

        view.setBounds({
            x: args.x,
            y: args.y,
            width: args.width,
            height: args.height
        })
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
