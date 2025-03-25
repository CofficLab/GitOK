/**
 * 插件动作控制器
 * 负责处理与插件动作相关的业务逻辑
 */
import { IpcResponse } from '@/types/ipc';
import { SuperAction } from '@/types/super_action';
import { pluginActionManager } from '../managers/PluginActionManager';
import { ipcLogger as logger } from '../managers/LogManager';

export class PluginActionController {
  private static instance: PluginActionController;

  private constructor() {}

  /**
   * 获取 PluginActionController 实例
   */
  public static getInstance(): PluginActionController {
    if (!PluginActionController.instance) {
      PluginActionController.instance = new PluginActionController();
    }
    return PluginActionController.instance;
  }

  /**
   * 获取插件动作列表
   * @param keyword 搜索关键词
   */
  public async getActions(
    keyword: string = ''
  ): Promise<IpcResponse<SuperAction[]>> {
    try {
      const actions = await pluginActionManager.getActions(keyword);
      return { success: true, data: actions };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件动作失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 执行插件动作
   * @param actionId 动作ID
   */
  public async executeAction(actionId: string): Promise<IpcResponse<unknown>> {
    try {
      const result = await pluginActionManager.executeAction(actionId);
      return { success: true, data: result };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`执行插件动作失败: ${actionId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取动作视图内容
   * @param actionId 动作ID
   */
  public async getActionView(actionId: string): Promise<IpcResponse<string>> {
    logger.debug(`获取动作视图: ${actionId}`);
    try {
      const html = await pluginActionManager.getActionView(actionId);
      return { success: true, data: html };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`获取动作视图失败: ${actionId}`, { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }
}

export const pluginActionController = PluginActionController.getInstance();
