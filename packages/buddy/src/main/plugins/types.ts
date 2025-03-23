/**
 * 插件系统类型定义
 */
import { Logger } from '../utils/Logger';

// 创建日志记录器
const logger = new Logger('PluginManager');

// 插件动作接口
export interface PluginAction {
  id: string;
  title: string;
  description: string;
  icon: string;
  plugin: string;
  viewPath?: string; // 动作的自定义视图路径
}

// 插件信息接口
export interface PluginInfo {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  isInstalled: boolean;
  isLocal: boolean; // 是否为本地插件
}

// 插件接口
export interface Plugin {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  getActions(keyword: string): Promise<PluginAction[]>;
  executeAction(action: PluginAction): Promise<any>;
  getViewContent?(viewPath: string): Promise<string>; // 获取视图HTML内容
}

// 插件包信息
export interface PluginPackage {
  name: string;
  version: string;
  description: string;
  author: string;
  main: string;
  gitokPlugin: {
    id: string;
  };
}

/**
 * 插件管理器
 * 负责注册和管理插件
 */
export class PluginManager {
  private plugins: Map<string, Plugin> = new Map();

  /**
   * 注册插件
   */
  registerPlugin(plugin: Plugin): void {
    if (this.plugins.has(plugin.id)) {
      logger.warn(`插件ID ${plugin.id} 已存在，将被覆盖`);
    }

    this.plugins.set(plugin.id, plugin);
    logger.info(`已注册插件: ${plugin.name} (${plugin.id})`);
  }

  /**
   * 获取插件
   */
  getPlugin(pluginId: string): Plugin | undefined {
    if (!this.plugins.has(pluginId)) {
      logger.warn(`插件 ${pluginId} 不存在`);
      return undefined;
    }

    return this.plugins.get(pluginId);
  }

  /**
   * 获取所有插件
   */
  getAllPlugins(): PluginInfo[] {
    logger.debug(`获取所有插件, 共 ${this.plugins.size} 个`);
    return Array.from(this.plugins.values()).map((plugin) => ({
      id: plugin.id,
      name: plugin.name,
      description: plugin.description,
      version: plugin.version,
      author: plugin.author,
      isInstalled: true,
      isLocal: plugin.id.startsWith('local.'),
    }));
  }

  /**
   * 从所有插件获取匹配关键词的动作
   */
  getAllActions(keyword: string = ''): Promise<PluginAction[]> {
    logger.debug(`获取所有动作，关键词: "${keyword}"`);
    const promises = Array.from(this.plugins.values()).map(async (plugin) => {
      try {
        logger.debug(`从插件 ${plugin.name} 获取动作`);
        const actions = await plugin.getActions(keyword);
        logger.debug(`插件 ${plugin.name} 返回了 ${actions.length} 个动作`);
        return actions;
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error(`从插件 ${plugin.name} 获取动作失败`, {
          error: errorMessage,
        });
        return [];
      }
    });

    return Promise.all(promises).then((actionLists) => {
      const allActions = actionLists.flat();
      logger.debug(`所有插件共返回 ${allActions.length} 个动作`);
      return allActions;
    });
  }

  /**
   * 执行插件动作
   */
  async executeAction(actionId: string): Promise<any> {
    logger.debug(`执行动作: ${actionId}`);

    // 解析动作ID格式: pluginId/actionId
    const parts = actionId.split('/');
    if (parts.length !== 2) {
      const error = `无效的动作ID格式: ${actionId}，应为 "pluginId/actionId" 格式`;
      logger.error(error);
      throw new Error(error);
    }

    const [pluginId, id] = parts;
    logger.debug(`解析动作ID: 插件=${pluginId}, 动作=${id}`);

    // 获取插件
    const plugin = this.getPlugin(pluginId);
    if (!plugin) {
      const error = `未找到插件: ${pluginId}`;
      logger.error(error);
      throw new Error(error);
    }

    // 获取插件的所有动作
    logger.debug(`获取插件 ${plugin.name} 的所有动作`);
    const actions = await plugin.getActions('');
    logger.debug(`插件 ${plugin.name} 有 ${actions.length} 个动作`);

    // 查找要执行的动作
    const action = actions.find((a) => a.id === id);
    if (!action) {
      const error = `未找到动作: ${id} (在插件 ${plugin.name} 中)`;
      logger.error(error);
      throw new Error(error);
    }

    // 执行动作
    logger.info(`执行动作: ${action.title} (${actionId})`);
    try {
      const result = await plugin.executeAction(action);
      logger.debug(`动作执行成功: ${actionId}`);
      return result;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`动作执行失败: ${actionId}`, { error: errorMessage });
      throw error;
    }
  }

  /**
   * 获取动作视图内容
   */
  async getActionViewContent(actionId: string): Promise<string> {
    logger.debug(`获取动作视图内容: ${actionId}`);

    // 解析动作ID格式: pluginId/actionId
    const parts = actionId.split('/');
    if (parts.length !== 2) {
      const error = `无效的动作ID格式: ${actionId}，应为 "pluginId/actionId" 格式`;
      logger.error(error);
      throw new Error(error);
    }

    const [pluginId, id] = parts;
    logger.debug(`解析动作ID: 插件=${pluginId}, 动作=${id}`);

    // 获取插件
    const plugin = this.getPlugin(pluginId);
    if (!plugin) {
      const error = `未找到插件: ${pluginId}`;
      logger.error(error);
      throw new Error(error);
    }

    // 获取插件的所有动作
    logger.debug(`获取插件 ${plugin.name} 的所有动作`);
    const actions = await plugin.getActions('');
    logger.debug(`插件 ${plugin.name} 有 ${actions.length} 个动作`);

    // 查找要获取视图的动作
    const action = actions.find((a) => a.id === id);
    if (!action) {
      const error = `未找到动作: ${id} (在插件 ${plugin.name} 中)`;
      logger.error(error);
      throw new Error(error);
    }

    // 检查动作是否有视图路径
    if (!action.viewPath) {
      const error = `动作 ${action.title} 没有定义视图路径`;
      logger.error(error);
      throw new Error(error);
    }

    // 检查插件是否支持视图获取
    if (!plugin.getViewContent) {
      const error = `插件 ${plugin.name} 不支持视图获取功能`;
      logger.error(error);
      throw new Error(error);
    }

    // 获取视图内容
    logger.debug(`从插件 ${plugin.name} 获取视图: ${action.viewPath}`);
    try {
      const html = await plugin.getViewContent(action.viewPath);
      logger.debug(`成功获取视图: ${actionId}, HTML长度: ${html.length}字节`);
      return html;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`获取视图内容失败: ${actionId}`, { error: errorMessage });
      throw error;
    }
  }
}
