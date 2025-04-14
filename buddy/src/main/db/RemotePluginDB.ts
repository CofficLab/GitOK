/**
 * 远程插件数据库
 * 负责从远程 npm registry 获取插件并缓存
 */
import { logger } from '../managers/LogManager';
import { NpmPackage, npmRegistryService } from '../service/NpmRegistryService';
import { PluginEntity } from '../entities/PluginEntity';

const verbose = false;

export class RemotePluginDB {
    private static instance: RemotePluginDB;

    // 缓存刷新时间间隔 (毫秒): 1小时
    private readonly CACHE_REFRESH_INTERVAL = 60 * 60 * 1000;

    // 上次缓存刷新时间
    private lastCacheRefreshTime: number = 0;

    // 插件列表缓存
    private cachedRemotePlugins: PluginEntity[] = [];

    /**
     * 刷新缓存标志，防止并发刷新
     */
    private isRefreshingCache = false;

    private constructor() {
        // 初始化时立即刷新插件列表
        this.refreshRemotePlugins();
    }

    public static getInstance(): RemotePluginDB {
        if (!RemotePluginDB.instance) {
            RemotePluginDB.instance = new RemotePluginDB();
        }
        return RemotePluginDB.instance;
    }

    /**
     * 获取远程插件列表
     * 从远程API获取包列表，筛选出符合条件的插件
     */
    public async getRemotePlugins(): Promise<PluginEntity[]> {
        try {
            // 检查缓存是否过期
            if (
                this.shouldRefreshCache() &&
                !this.isRefreshingCache // 防止并发刷新
            ) {
                this.isRefreshingCache = true;
                // 先返回缓存数据，在后台刷新
                const result = await this.searchPlugins();
                this.cachedRemotePlugins = result;
                this.lastCacheRefreshTime = Date.now();
                this.isRefreshingCache = false;

                if (verbose) {
                    logger.info(`远程插件列表缓存已更新，数量`, this.cachedRemotePlugins.length);
                }

                return this.cachedRemotePlugins;
            }

            // 返回缓存数据
            return this.cachedRemotePlugins;
        } catch (error) {
            logger.error(
                `获取远程插件列表失败: ${error instanceof Error ? error.message : String(error)}`
            );
            return [];
        }
    }

    /**
     * 搜索并处理插件
     */
    private async searchPlugins(): Promise<PluginEntity[]> {
        try {
            const packages = await npmRegistryService.searchPackagesByKeyword('buddy-plugin');
            return await this.processSearchResults(packages);
        } catch (error) {
            logger.error(
                `搜索插件失败: ${error instanceof Error ? error.message : String(error)}`
            );
            return [];
        }
    }

    /**
     * 处理搜索结果，筛选出符合条件的插件
     */
    private async processSearchResults(packages: NpmPackage[]): Promise<PluginEntity[]> {
        return packages.map((pkg: NpmPackage) => PluginEntity.fromNpmPackage(pkg)).filter((plugin) => plugin.isBuddyPlugin);
    }

    /**
     * 刷新远程插件列表缓存
     * 从 npm registry 获取 coffic 组织下的所有包
     */
    private async refreshRemotePlugins(): Promise<void> {
        try {
            if (verbose) {
                logger.info('开始刷新远程插件列表缓存');
            }

            // 搜索 buddy-plugin 关键词
            const packages = await this.searchPlugins();

            if (packages && Array.isArray(packages) && packages.length > 0) {
                const result = await this.processSearchResults(packages);

                if (result.length > 0) {
                    this.cachedRemotePlugins = result;
                    this.lastCacheRefreshTime = Date.now();
                    logger.info(`远程插件列表缓存已更新, count`, result.length);
                    return;
                }
            }

            logger.warn('未能获取远程包列表');
        } catch (error) {
            logger.error('刷新远程插件列表失败', {
                error: error instanceof Error ? error.message : String(error),
            });
        }

        // 设置定时刷新
        setInterval(() => {
            this.refreshRemotePlugins();
        }, this.CACHE_REFRESH_INTERVAL);
    }

    /**
     * 判断缓存是否需要刷新
     */
    private shouldRefreshCache(): boolean {
        const now = Date.now();
        return now - this.lastCacheRefreshTime > this.CACHE_REFRESH_INTERVAL;
    }
}

// 导出单例
export const remotePluginDB = RemotePluginDB.getInstance();
