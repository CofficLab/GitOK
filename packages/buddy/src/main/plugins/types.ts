/**
 * 插件系统类型定义
 */

// 插件动作接口
export interface PluginAction {
  id: string;
  title: string;
  description: string;
  icon: string;
  plugin: string;
}

// 插件接口
export interface Plugin {
  id: string;
  name: string;
  description: string;
  version: string;
  getActions(): PluginAction[];
  executeAction(actionId: string): Promise<any>;
}

// 插件管理器类
export class PluginManager {
  private plugins: Map<string, Plugin> = new Map();

  // 注册插件
  registerPlugin(plugin: Plugin): void {
    this.plugins.set(plugin.id, plugin);
    console.log(`插件已注册: ${plugin.name} (${plugin.id})`);
  }

  // 获取插件
  getPlugin(pluginId: string): Plugin | undefined {
    return this.plugins.get(pluginId);
  }

  // 获取所有插件
  getAllPlugins(): Plugin[] {
    return Array.from(this.plugins.values());
  }

  // 获取所有动作
  getAllActions(): PluginAction[] {
    const allActions: PluginAction[] = [];

    for (const plugin of this.plugins.values()) {
      allActions.push(...plugin.getActions());
    }

    return allActions;
  }

  // 执行动作
  async executeAction(actionId: string): Promise<any> {
    // 找到动作所属的插件
    for (const plugin of this.plugins.values()) {
      const actions = plugin.getActions();
      const actionExists = actions.some((action) => action.id === actionId);

      if (actionExists) {
        return plugin.executeAction(actionId);
      }
    }

    throw new Error(`未找到动作: ${actionId}`);
  }
}
