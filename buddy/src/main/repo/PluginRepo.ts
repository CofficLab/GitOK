import { join } from 'path';
import fs from 'fs';
import { PluginEntity } from '../entities/PluginEntity.js';
import { logger } from '../managers/LogManager.js';
import { PluginType } from '@coffic/buddy-types';
import { SendablePlugin } from '@/types/sendable-plugin.js';

const verbose = true;

/**
 * 插件仓库
 * 负责从指定目录读取插件信息
 * 
 * 例如：
 * 
 * 用户插件目录：
 *  - packages/user-plugins/
 *      - plugin-time/
 *      - plugin-weather/
 * 
 * 开发插件目录：
 *  - packages/dev-plugins/
 *      - plugin-time-view/
 * 
 * 其中 packages/user-plugins/ 是插件仓库，plugin-time、plugin-weather 是插件
 * 
 */
export abstract class PluginRepo {
    protected rootDir: string;

    protected constructor(pluginsDir: string) {
        this.rootDir = pluginsDir;
    }

    /**
     * 获取仓库的根目录
     * 
     * 例如：packages/user-plugins/
     * 
     */
    public getRootDir(): string {
        return this.rootDir;
    }

    /**
     * 确保仓库目录存在
     */
    async ensureRepoDirs(): Promise<void> {
        if (!fs.existsSync(this.rootDir)) {
            throw new Error(`仓库目录不存在: ${this.rootDir}`);
        }
    }

    /**
     * 获取插件列表
     */
    async getAllPlugins(): Promise<PluginEntity[]> {
        if (verbose) {
            logger.info('获取插件列表，根目录是', this.rootDir);
        }

        if (!fs.existsSync(this.rootDir)) {
            return [];
        }

        const plugins: PluginEntity[] = [];

        try {
            const entries = await fs.promises.readdir(this.rootDir, { withFileTypes: true });

            for (const entry of entries) {
                if (!entry.isDirectory()) continue;

                const pluginPath = join(this.rootDir, entry.name);

                try {
                    const plugin = await PluginEntity.fromDir(pluginPath, this.getPluginType());
                    plugins.push(plugin);
                } catch (error) {
                    // logger.warn(`读取插件信息失败: ${pluginPath}`, error);
                }
            }

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

    public async getSendablePlugins(): Promise<SendablePlugin[]> {
        const plugins = await this.getAllPlugins();
        return await Promise.all(plugins.map((plugin) => plugin.getSendablePlugin()));
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



    /**
     * 根据插件ID判断插件是否存在
     * @param id 插件ID
     * @returns 插件是否存在
     */
    public async has(id: string): Promise<boolean> {
        if (typeof id !== 'string') {
            logger.error('插件ID必须是字符串, 但是传入的是', id);
            throw new Error('插件ID必须是字符串');
        }

        logger.debug('检查插件是否存在', id)

        return (await this.getAllPlugins()).some((plugin) => plugin.id === id);
    }

    protected abstract getPluginType(): PluginType;
}
