/**
 * 插件系统类型定义
 */

// 日志函数
const logInfo = (message: string, ...args: any[]) => {
  console.log(`[插件管理器] ${message}`, ...args);
};

const logError = (message: string, ...args: any[]) => {
  console.error(`[插件管理器] ${message}`, ...args);
};

const logDebug = (message: string, ...args: any[]) => {
  console.log(`[插件管理器:调试] ${message}`, ...args);
};

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

// 插件包接口
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

// 插件管理器类
export class PluginManager {
  private plugins: Map<string, Plugin> = new Map();

  // 注册插件
  registerPlugin(plugin: Plugin): void {
    if (this.plugins.has(plugin.id)) {
      logInfo(`更新插件: ${plugin.name} (${plugin.id})`);
    } else {
      logInfo(`注册新插件: ${plugin.name} (${plugin.id})`);
    }

    this.plugins.set(plugin.id, plugin);
    logDebug(
      `插件已注册/更新: ${plugin.name} (${plugin.id}), 目前有 ${this.plugins.size} 个已注册插件`
    );
  }

  // 获取插件
  getPlugin(pluginId: string): Plugin | undefined {
    const plugin = this.plugins.get(pluginId);

    if (plugin) {
      logDebug(`找到插件: ${pluginId}`);
    } else {
      logDebug(`未找到插件: ${pluginId}`);
    }

    return plugin;
  }

  // 获取所有插件信息
  getAllPlugins(): PluginInfo[] {
    logDebug(`获取所有插件信息, 共 ${this.plugins.size} 个`);

    return Array.from(this.plugins.values()).map((plugin) => ({
      id: plugin.id,
      name: plugin.name,
      description: plugin.description,
      version: plugin.version,
      author: plugin.author || '未知',
      isInstalled: true,
      isLocal: true, // 默认为本地插件
    }));
  }

  // 获取所有动作
  getAllActions(keyword: string = ''): Promise<PluginAction[]> {
    logDebug(
      `获取所有插件动作, 关键词: "${keyword}", 共 ${this.plugins.size} 个插件`
    );

    const promises = Array.from(this.plugins.values()).map((plugin) =>
      plugin
        .getActions(keyword)
        .then((actions) => {
          logDebug(`插件 ${plugin.id} 返回了 ${actions.length} 个动作`);
          return actions.map((action) => ({
            ...action,
            plugin: action.plugin || plugin.id,
          }));
        })
        .catch((err) => {
          logError(`获取插件 ${plugin.id} 的动作失败:`, err);
          return [];
        })
    );

    return Promise.all(promises).then((results) => {
      const allActions = results.flat();
      logDebug(`合并获取到 ${allActions.length} 个动作`);
      return allActions;
    });
  }

  // 执行动作
  async executeAction(actionId: string): Promise<any> {
    logDebug(`准备执行动作: ${actionId}`);

    // 获取所有动作
    const allActions = await this.getAllActions();
    logDebug(`找到 ${allActions.length} 个动作，搜索匹配的动作ID`);

    // 找到匹配的动作
    const action = allActions.find((a) => a.id === actionId);
    if (!action) {
      const errorMsg = `未找到动作: ${actionId}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    logDebug(
      `找到要执行的动作: ${action.id} (${action.title}), 来自插件: ${action.plugin}`
    );

    // 获取对应的插件
    const plugin = this.plugins.get(action.plugin);
    if (!plugin) {
      const errorMsg = `未找到插件: ${action.plugin}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    // 执行动作
    logDebug(`开始执行动作: ${action.id}`);
    try {
      const result = await plugin.executeAction(action);
      logDebug(`动作执行成功: ${action.id}`);
      return result;
    } catch (error) {
      logError(`动作执行失败: ${action.id}`, error);
      throw error;
    }
  }

  // 获取视图内容
  async getActionViewContent(actionId: string): Promise<string> {
    logDebug(`准备获取动作视图内容: ${actionId}`);

    // 获取所有动作
    const allActions = await this.getAllActions();

    // 找到匹配的动作
    const action = allActions.find((a) => a.id === actionId);
    if (!action) {
      const errorMsg = `未找到动作: ${actionId}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    logDebug(
      `找到动作: ${action.id} (${action.title}), 来自插件: ${action.plugin}`
    );

    // 检查动作是否有视图路径
    if (!action.viewPath) {
      const errorMsg = `动作没有自定义视图: ${actionId}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    logDebug(`动作具有视图路径: ${action.viewPath}`);

    // 获取对应的插件
    const plugin = this.plugins.get(action.plugin);
    if (!plugin) {
      const errorMsg = `未找到插件: ${action.plugin}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    // 检查插件是否支持获取视图内容
    if (!plugin.getViewContent) {
      const errorMsg = `插件不支持自定义视图: ${action.plugin}`;
      logError(errorMsg);
      throw new Error(errorMsg);
    }

    // 获取视图内容
    logDebug(`开始获取视图内容: ${action.viewPath}`);
    try {
      const content = await plugin.getViewContent(action.viewPath);
      logDebug(`成功获取视图内容，长度: ${content.length} 字节`);
      return content;
    } catch (error) {
      logError(`获取视图内容失败: ${action.viewPath}`, error);
      throw error;
    }
  }
}
