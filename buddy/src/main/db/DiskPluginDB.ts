import { join } from 'path';
import fs from 'fs';
import { PluginEntity } from '../entities/PluginEntity.js';
import { logger } from '../managers/LogManager.js';
import { PluginType } from '@coffic/buddy-types';

const verbose = false;

export abstract class DiskPluginDB {
    protected pluginsDir: string;

    protected constructor(pluginsDir: string) {
        this.pluginsDir = pluginsDir;
    }

    /**
     * 获取插件目录信息
     */
    getPluginDirectory(): string {
        return this.pluginsDir;
    }

    /**
     * 确保插件目录存在
     */
    async ensurePluginDirs(): Promise<void> {
        try {
            if (!fs.existsSync(this.pluginsDir)) {
                throw new Error(`插件目录不存在: ${this.pluginsDir}`);
            }
        } catch (error) {
            logger.error('检查插件目录失败', error);
            throw error;
        }
    }

    /**
     * 从指定目录读取插件信息
     */
    protected async readPluginsFromDir(dir: string, type: PluginType): Promise<PluginEntity[]> {
        if (!fs.existsSync(dir)) {
            return [];
        }

        if (verbose) {
            logger.info('读取插件目录', { dir, type });
        }

        const plugins: PluginEntity[] = [];
        const entries = await fs.promises.readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
            if (!entry.isDirectory()) continue;

            const pluginPath = join(dir, entry.name);

            try {
                const plugin = await PluginEntity.fromDirectory(pluginPath, type);
                plugins.push(plugin);
            } catch (error) {
                // logger.warn(`读取插件信息失败: ${pluginPath}`, error);
            }
        }

        return plugins;
    }

    /**
     * 获取所有插件列表
     */
    async getAllPlugins(): Promise<PluginEntity[]> {
        if (verbose) {
            logger.info('获取插件列表，根目录是', this.pluginsDir);
        }
        try {
            const plugins = await this.readPluginsFromDir(
                this.pluginsDir,
                this.getPluginType()
            );

            // 过滤出有效的
            const validPlugins = plugins.filter((plugin) => plugin.validation?.isValid);
            if (validPlugins.length === 0) {
                return [];
            } else {
                if (verbose) {
                    logger.info('有效的插件数量', validPlugins.length);
                }
            }

            // 排序插件列表
            validPlugins.sort((a, b) => a.name.localeCompare(b.name));
            return validPlugins;
        } catch (error) {
            logger.error('获取插件列表失败', error);
            return [];
        }
    }

    /**
     * 加载插件模块
     */
    public async loadPluginModule(plugin: PluginEntity): Promise<any> {
        try {
            const mainFilePath = plugin.mainFilePath;
            if (!fs.existsSync(mainFilePath)) {
                throw new Error(`插件入口文件不存在: ${mainFilePath}`);
            }

            delete require.cache[require.resolve(mainFilePath)];
            const module = require(mainFilePath);
            plugin.markAsLoaded();
            return module;
        } catch (error: any) {
            plugin.setStatus('error', error.message);
            throw error;
        }
    }

    /**
     * 根据插件ID查找插件
     */
    public async find(id: string): Promise<PluginEntity | null> {
        try {
            const plugins = await this.getAllPlugins();
            return plugins.find((plugin) => plugin.id === id) || null;
        } catch (error) {
            logger.error(`查找插件失败: ${id}`, error);
            return null;
        }
    }

    protected abstract getPluginType(): 'dev' | 'user';
}
