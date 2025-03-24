/**
 * 插件动作管理器
 * 负责管理和执行插件动作
 */
import { EventEmitter } from 'events';
import { Logger } from '../utils/Logger';
import { configManager } from './ConfigManager';
import { pluginManager } from './PluginManager';
import { BaseManager } from './BaseManager';
import type { PluginAction } from '../../types';

class PluginActionManager extends BaseManager {
  private static instance: PluginActionManager;
  private config: any;
  private actionCache: Map<string, PluginAction[]> = new Map();

  private constructor() {
    const config = configManager.getPluginConfig();
    super({
      name: 'PluginActionManager',
      enableLogging: config.enableLogging,
      logLevel: config.logLevel,
    });
    this.config = config;
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
  async getActions(keyword: string = ''): Promise<PluginAction[]> {
    this.logger.info(`获取插件动作，关键词: "${keyword}"`);
    let allActions: PluginAction[] = [];

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
    actions: PluginAction[],
    plugin: any
  ): PluginAction[] {
    return actions.filter((action) => {
      // 验证必要字段
      if (!action.id || !action.title) {
        this.logger.warn(`插件 ${plugin.id} 的动作缺少必要字段`, action);
        return false;
      }

      // 确保动作ID包含插件ID前缀
      if (!action.id.startsWith(`${plugin.id}:`)) {
        action.id = `${plugin.id}:${action.id}`;
      }

      // 添加默认值
      action.plugin = plugin.id;
      action.description = action.description || '';
      action.icon = action.icon || '';

      return true;
    });
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
      const actionInfo = actions.find((a) => a.id === actionId);

      if (!actionInfo) {
        throw new Error(`未找到动作: ${actionId}`);
      }

      // 执行前触发事件
      this.emit('action:before-execute', actionInfo);

      // 执行动作
      const result = await pluginModule.executeAction(actionInfo);

      // 执行后触发事件
      this.emit('action:after-execute', actionInfo, result);

      return result;
    } catch (error) {
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
      const actionInfo = actions.find((a) => a.id === actionId);

      if (!actionInfo || !actionInfo.viewPath) {
        throw new Error(`动作 ${actionId} 没有关联视图`);
      }

      // 加载插件模块
      const pluginModule = await pluginManager.loadPluginModule(plugin);
      if (!pluginModule || typeof pluginModule.getViewContent !== 'function') {
        throw new Error(`插件 ${pluginId} 不支持获取视图内容`);
      }

      // 获取视图内容
      return await pluginModule.getViewContent(actionInfo.viewPath);
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
