/**
 * 插件视图控制器
 * 负责处理与插件视图窗口相关的业务逻辑
 */
import { IpcResponse } from '@/types/ipc-methods';
import { pluginViewManager } from '../managers/PluginViewManager';
import { logger } from '../managers/LogManager';

interface WindowBounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

export class PluginViewController {
  private static instance: PluginViewController;

  private constructor() {}

  /**
   * 获取 PluginViewController 实例
   */
  public static getInstance(): PluginViewController {
    if (!PluginViewController.instance) {
      PluginViewController.instance = new PluginViewController();
    }
    return PluginViewController.instance;
  }

  /**
   * 创建插件视图窗口
   * @param viewId 视图ID
   * @param url 视图URL
   */
  public async createView(
    viewId: string,
    url: string
  ): Promise<IpcResponse<unknown>> {
    try {
      const mainWindowBounds = await pluginViewManager.createView({
        viewId,
        url,
      });
      return { success: true, data: mainWindowBounds };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`创建插件视图窗口失败: ${viewId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 显示插件视图窗口
   * @param viewId 视图ID
   * @param bounds 窗口位置和大小
   */
  public async showView(
    viewId: string,
    bounds?: WindowBounds
  ): Promise<IpcResponse<boolean>> {
    try {
      const result = await pluginViewManager.showView(viewId, bounds);
      return { success: true, data: result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`显示插件视图窗口失败: ${viewId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 隐藏插件视图窗口
   * @param viewId 视图ID
   */
  public async hideView(viewId: string): Promise<IpcResponse<boolean>> {
    try {
      const result = pluginViewManager.hideView(viewId);
      return { success: true, data: result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`隐藏插件视图窗口失败: ${viewId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 销毁插件视图窗口
   * @param viewId 视图ID
   */
  public async destroyView(viewId: string): Promise<IpcResponse<boolean>> {
    try {
      const result = await pluginViewManager.destroyView(viewId);
      return { success: true, data: result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`销毁插件视图窗口失败: ${viewId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 切换插件视图窗口的开发者工具
   * @param viewId 视图ID
   */
  public toggleDevTools(viewId: string): IpcResponse<boolean> {
    try {
      const result = pluginViewManager.toggleDevTools(viewId);
      return { success: true, data: result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`切换插件视图开发者工具失败: ${viewId}`, {
        error: errorMessage,
      });
      return { success: false, error: errorMessage };
    }
  }
}

export const pluginViewController = PluginViewController.getInstance();
