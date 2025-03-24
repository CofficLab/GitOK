/**
 * 插件动作管理器
 * 负责管理和执行插件动作
 */
import { configManager } from './ConfigManager';
import { pluginManager } from './PluginManager';
import { BaseManager } from './BaseManager';
import type { SuperAction } from '@/types/super_action';
import { PluginActionEntity } from '../entities/PluginActionEntity';

class PluginActionManager extends BaseManager {
  private static instance: PluginActionManager;
  private actionCache: Map<string, PluginActionEntity[]> = new Map();

  private constructor() {
    const config = configManager.getPluginConfig();
    super({
      name: 'PluginActionManager',
      enableLogging: config.enableLogging,
      logLevel: config.logLevel,
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
    this.logger.info(`获取插件动作，关键词: "${keyword}"`);
    let allActions: PluginActionEntity[] = [];

    try {
      // 从所有加载的插件中获取动作
      const plugins = pluginManager.getPlugins();
      for (const plugin of plugins) {
        try {
          // 检查缓存
          const cacheKey = `${plugin.id}:${keyword}`;
          const cachedActions = this.actionCache.get(cacheKey);
          if (cachedActions) {
            allActions = [...allActions, ...cachedActions];
            continue;
          }

          // 动态加载插件模块
          const pluginModule = await pluginManager.loadPluginModule(plugin);

          if (pluginModule && typeof pluginModule.getActions === 'function') {
            const pluginActions = await pluginModule.getActions(keyword);
            if (Array.isArray(pluginActions)) {
              // 验证和处理动作
              const validActions = this.validateAndProcessActions(
                pluginActions,
                plugin
              );
              // 更新缓存
              this.actionCache.set(cacheKey, validActions);
              allActions = [...allActions, ...validActions];
            }
          }
        } catch (error) {
          this.handleError(error, `获取插件 ${plugin.id} 的动作失败`);
        }
      }

      // 过滤关键词匹配的动作
      if (keyword) {
        allActions = allActions.filter((action) =>
          action.matchKeyword(keyword)
        );
      }

      this.logger.info(`找到 ${allActions.length} 个匹配的动作`);
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
        this.logger.warn(`插件 ${plugin.id} 的动作验证失败`, {
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
   * @param actionId 要执行的动作ID
   * @returns 执行结果
   */
  async executeAction(actionId: string): Promise<any> {
    this.logger.info(`执行插件动作: ${actionId}`);

    try {
      // 解析插件ID和动作ID
      const [pluginId] = actionId.split(':');
      if (!pluginId) {
        throw new Error(`无效的动作ID: ${actionId}`);
      }

      // 获取插件实例
      const plugin = pluginManager.getPlugin(pluginId);
      if (!plugin) {
        throw new Error(`未找到插件: ${pluginId}`);
      }

      // 加载插件模块
      const pluginModule = await pluginManager.loadPluginModule(plugin);
      if (!pluginModule || typeof pluginModule.executeAction !== 'function') {
        throw new Error(`插件 ${pluginId} 不支持执行动作`);
      }

      // 获取动作信息
      const actions = await this.getActions();
      const actionEntity = actions.find((a) => a.id === actionId);

      if (!actionEntity) {
        throw new Error(`未找到动作: ${actionId}`);
      }

      // 检查动作是否可执行
      if (!actionEntity.canExecute()) {
        throw new Error(
          `动作 ${actionId} 当前不可执行: ${actionEntity.status}`
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
      this.emit('action:execute-error', actionId, error);
      throw new Error(
        this.handleError(error, `执行插件动作失败: ${actionId}`, false)
      );
    }
  }

  /**
   * 获取动作视图内容
   * @param actionId 动作ID
   * @returns 视图内容
   */
  async getActionView(actionId: string): Promise<string> {
    this.logger.info(`获取动作视图: ${actionId}`);

    try {
      // 解析插件ID
      const [pluginId] = actionId.split(':');
      if (!pluginId) {
        throw new Error(`无效的动作ID: ${actionId}`);
      }

      // 获取插件实例
      const plugin = pluginManager.getPlugin(pluginId);
      if (!plugin) {
        throw new Error(`未找到插件: ${pluginId}`);
      }

      // 获取动作信息
      const actions = await this.getActions();
      const actionEntity = actions.find((a) => a.id === actionId);

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
    this.logger.info('清理动作管理器资源');
    try {
      // 清空动作缓存
      this.actionCache.clear();
      // 移除所有事件监听器
      this.removeAllListeners();
      this.logger.info('动作管理器资源清理完成');
    } catch (error) {
      this.handleError(error, '清理动作管理器资源失败');
    }
  }
}

// 导出单例
export const pluginActionManager = PluginActionManager.getInstance();
