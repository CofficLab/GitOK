/**
 * 插件动作管理器
 * 负责管理和执行插件动作
 */
import { pluginManager } from './PluginManager';
import { BaseManager } from './BaseManager';
import { PluginActionEntity } from '../entities/PluginActionEntity';
import { logger } from './LogManager';
import { userPluginDB } from '../db/UserPluginDB';
import { appStateManager } from './StateManager';
import { devPluginDB } from '../db/DevPluginDB';
import { PluginContext, SuperAction } from '@coffic/buddy-types';

const verbose = false;

class PluginActionManager extends BaseManager {
  private static instance: PluginActionManager;

  private constructor() {
    super({
      name: 'PluginActionManager',
      enableLogging: true,
      logLevel: 'info',
    });
  }

  /**
   * 获取 PluginActionManager 实例
   */
  public static getInstance(): PluginActionManager {
    if (!PluginActionManager.instance) {
      PluginActionManager.instance = new PluginActionManager();
    }
    return PluginActionManager.instance;
  }

  /**
   * 获取插件动作
   * @param keyword 搜索关键词
   * @returns 匹配的插件动作列表
   */
  async getActions(keyword: string = ''): Promise<PluginActionEntity[]> {
    let allActions: PluginActionEntity[] = [];
    let overlaidApp = appStateManager.getOverlaidApp();

    if (verbose) {
      logger.info(`获取动作，当前应用`, overlaidApp?.name, `关键词: "${keyword}"`);
    }

    try {
      // 从所有加载的插件中获取动作
      const plugins = await pluginManager.getPlugins();
      for (const plugin of plugins) {
        if (verbose) {
          logger.info(`获取插件动作，当前插件: ${plugin.id}`);
        }
        try {
          // 动态加载插件模块
          const pluginModule = await pluginManager.loadPluginModule(plugin);

          if (!pluginModule) {
            logger.warn(`插件模块加载失败: ${plugin.id}，跳过该插件`);
            continue;
          }

          if (typeof pluginModule.getActions !== 'function') {
            logger.warn(`插件 ${plugin.id} 未实现 getActions 方法，跳过该插件`);
            continue;
          }

          const context: PluginContext = {
            keyword,
            overlaidApp: overlaidApp?.name || '',
          };

          if (verbose) {
            logger.info(`调用插件 getActions: ${plugin.id}`, {
              context,
              pluginPath: plugin.path,
            });
          }

          const pluginActions = await pluginModule.getActions(context);

          if (!Array.isArray(pluginActions)) {
            logger.warn(`插件 ${plugin.id} 返回的动作不是数组，跳过该插件`);
            continue;
          }

          // 验证和处理动作
          const validActions = this.validateAndProcessActions(
            pluginActions,
            plugin
          );
          allActions = [...allActions, ...validActions];

          // logger.info(`成功获取插件 ${plugin.id} 的动作`, {
          //   actionCount: validActions.length,
          // });
        } catch (error) {
          // 获取详细的错误信息
          const errorDetail =
            error instanceof Error
              ? {
                message: error.message,
                stack: error.stack,
                name: error.name,
              }
              : String(error);

          logger.error(`插件 ${plugin.id} 执行失败`, {
            error: errorDetail,
            pluginInfo: {
              id: plugin.id,
              name: plugin.name,
              version: plugin.version,
              path: plugin.path,
            },
          });

          // 记录错误但继续处理其他插件
          this.handleError(
            error,
            `获取插件 ${plugin.id} 的动作失败，但不影响其他插件`
          );
        }
      }

      // logger.info(`获取插件动作，所有动作`, allActions);

      if (verbose) {
        logger.info(`找到 ${allActions.length} 个动作`);
      }
      return allActions;
    } catch (error) {
      this.handleError(error, '获取插件动作失败');
      return [];
    }
  }

  /**
   * 验证和处理动作
   */
  private validateAndProcessActions(
    actions: SuperAction[],
    plugin: any
  ): PluginActionEntity[] {
    const actionEntities = actions.map((action) =>
      PluginActionEntity.fromRawAction(action, plugin.id)
    );

    // 过滤出验证通过的动作
    const validActions = actionEntities.filter((action) => {
      if (!action.validation?.isValid) {
        logger.warn(`插件 ${plugin.id} 的动作验证失败`, {
          action: action.id,
          errors: action.validation?.errors,
        });
        return false;
      }
      return true;
    });

    return validActions;
  }

  /**
   * 执行插件动作
   * @param actionGlobalId 要执行的动作的全局ID
   * @returns 执行结果
   */
  async executeAction(actionGlobalId: string, keyword: string): Promise<any> {
    logger.info(`执行插件动作: ${actionGlobalId}`);

    try {
      // 解析插件ID和动作ID
      const [pluginId, actionId] = actionGlobalId.split(':');
      if (!pluginId || !actionId) {
        throw new Error(`无效的动作ID: ${actionGlobalId}`);
      }

      // 首先从用户插件目录获取插件实例
      let plugin = await userPluginDB.find(pluginId);

      // 如果未找到，则尝试从开发插件目录获取
      if (!plugin) {
        plugin = await devPluginDB.find(pluginId);
      }

      if (!plugin) {
        throw new Error(`未找到插件: ${pluginId}`);
      } else {
        logger.debug(`找到插件: ${pluginId}`);
      }

      // 加载插件模块
      const pluginModule = await pluginManager.loadPluginModule(plugin);
      if (!pluginModule || typeof pluginModule.executeAction !== 'function') {
        throw new Error(`插件 ${pluginId} 不支持执行动作`);
      }

      // 获取动作信息
      const actions = await this.getActions(keyword);
      const actionEntity = actions.find((a) => a.id === actionId);

      if (!actionEntity) {
        throw new Error(`未找到动作: ${actionGlobalId}`);
      }

      // 检查动作是否可执行
      if (!actionEntity.canExecute()) {
        throw new Error(
          `动作 ${actionGlobalId} 当前不可执行: ${actionEntity.status}`
        );
      }

      // 执行前触发事件
      this.emit('action:before-execute', actionEntity);

      // 标记动作开始执行
      actionEntity.beginExecute();

      try {
        // 执行动作
        const result = await pluginModule.executeAction(actionEntity);

        // 标记动作执行完成
        actionEntity.completeExecute();

        // 执行后触发事件
        this.emit('action:after-execute', actionEntity, result);

        return result;
      } catch (error: any) {
        // 标记动作执行出错
        actionEntity.executeError(error.message);
        throw error;
      }
    } catch (error: any) {
      this.emit('action:execute-error', actionGlobalId, error);
      throw new Error(
        this.handleError(error, `执行插件动作失败: ${actionGlobalId}`, false)
      );
    }
  }

  /**
   * 获取动作视图内容
   * @param actionId 动作ID
   * @returns 视图内容
   */
  async getActionView(actionId: string): Promise<string> {
    logger.info(`获取动作视图: ${actionId}`);

    try {
      // 解析插件ID
      const [pluginId] = actionId.split(':');
      if (!pluginId) {
        throw new Error(`无效的动作ID: ${actionId}`);
      }

      // 获取插件实例
      const plugin = await userPluginDB.find(pluginId);
      if (!plugin) {
        throw new Error(`未找到插件: ${pluginId}`);
      }

      // 获取动作信息
      const actions = await this.getActions();
      const actionEntity = actions.find((a) => a.globalId === actionId);

      if (!actionEntity || !actionEntity.viewPath) {
        throw new Error(`动作 ${actionId} 没有关联视图`);
      }

      // 加载插件模块
      const pluginModule = await pluginManager.loadPluginModule(plugin);
      if (!pluginModule || typeof pluginModule.getViewContent !== 'function') {
        throw new Error(`插件 ${pluginId} 不支持获取视图内容`);
      }

      // 获取视图内容
      return await pluginModule.getViewContent(actionEntity.viewPath);
    } catch (error) {
      throw new Error(
        this.handleError(error, `获取动作视图失败: ${actionId}`, false)
      );
    }
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    logger.info('清理动作管理器资源');
    try {
      // 移除所有事件监听器
      this.removeAllListeners();
      logger.info('动作管理器资源清理完成');
    } catch (error) {
      this.handleError(error, '清理动作管理器资源失败');
    }
  }
}

// 导出单例
export const pluginActionManager = PluginActionManager.getInstance();
