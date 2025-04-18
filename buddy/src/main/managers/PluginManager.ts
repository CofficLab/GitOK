/**
 * 插件管理器
 * 负责插件的加载、管理和通信
 */
import { BaseManager } from './BaseManager.js';
import { PluginEntity } from '../entities/PluginEntity.js';
import { userPluginDB } from '../db/UserPackageDB.js';
import { devPluginDB } from '../db/DevPluginDB.js';

class PluginManager extends BaseManager {
    private static instance: PluginManager;

    private constructor() {
        super({
            name: 'PluginManager',
            enableLogging: true,
            logLevel: 'info',
        });
    }

    public static getInstance(): PluginManager {
        if (!PluginManager.instance) {
            PluginManager.instance = new PluginManager();
        }
        return PluginManager.instance;
    }

    /**
     * 初始化插件系统
     */
    async initialize(): Promise<void> {
        try {
            await userPluginDB.ensurePluginDirs();
        } catch (error) {
            this.handleError(error, '插件系统初始化失败', true);
        }
    }

    async getPlugins(): Promise<PluginEntity[]> {
        return [...await userPluginDB.getAllPlugins(), ...await devPluginDB.getAllPlugins()];
    }

    async getPlugin(pluginId: string): Promise<PluginEntity | null> {
        return await userPluginDB.find(pluginId) || await devPluginDB.find(pluginId);
    }

    /**
     * 执行插件动作
     * @param actionGlobalId 要执行的动作的全局ID
     * @returns 执行结果
     */
    async executeAction(actionGlobalId: string, keyword: string): Promise<any> {
        const [pluginId, actionId] = actionGlobalId.split(':');
        const plugin = await this.getPlugin(pluginId);
        if (!plugin) {
            throw new Error(`插件不存在: ${pluginId}`);
        }

        return plugin.executeAction(actionId, keyword);
    }

    /**
     * 清理资源
     */
    public cleanup(): void {
        try {
            this.removeAllListeners();
        } catch (error) {
            this.handleError(error, '插件系统清理失败');
        }
    }
}

// 导出单例
export const pluginManager = PluginManager.getInstance();
