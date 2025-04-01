/**
 * 远程插件数据库
 * 负责从远程 npm registry 获取插件并缓存
 */
import { logger } from '../managers/LogManager';
import { NpmPackage, npmRegistryService } from '../service/NpmRegistryService';
import { PluginEntity } from '../entities/PluginEntity';

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
        this.cachedRemotePlugins = result.plugins;
        this.lastCacheRefreshTime = Date.now();
        this.isRefreshingCache = false;
        logger.info(`远程插件列表缓存已更新，数量`, this.cachedRemotePlugins.length);
        return this.cachedRemotePlugins;
      }

      // 返回缓存数据
      if (this.cachedRemotePlugins.length > 0) {
        return this.cachedRemotePlugins;
      }

      // 首次加载或缓存为空
      if (!this.isRefreshingCache) {
        this.isRefreshingCache = true;
        const result = await this.searchPlugins();
        this.cachedRemotePlugins = result.plugins;
        this.lastCacheRefreshTime = Date.now();
        this.isRefreshingCache = false;
        logger.info(`远程插件列表缓存已更新`, {
          count: this.cachedRemotePlugins.length,
        });
        return this.cachedRemotePlugins;
      }

      return [];
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
  private async searchPlugins(): Promise<{
    plugins: PluginEntity[];
    foundPackages: number;
    validPlugins: number;
  }> {
    try {
      // 主要搜索: buddy-plugin关键词
      const packages = await npmRegistryService.searchPackagesByKeyword('buddy-plugin');

      // 处理搜索结果
      const result = await this.processSearchResults(packages);

      return result;
    } catch (error) {
      logger.error(
        `搜索插件失败: ${error instanceof Error ? error.message : String(error)}`
      );
      return {
        plugins: [],
        foundPackages: 0,
        validPlugins: 0,
      };
    }
  }

  /**
   * 处理搜索结果，筛选出符合条件的插件
   */
  private async processSearchResults(packages: any[]): Promise<{
    plugins: PluginEntity[];
    foundPackages: number;
    validPlugins: number;
  }> {
    const foundPackages = packages.length;

    // 筛选出buddy插件
    const buddyPlugins = packages.filter((pkg) => {
      // 检查包名
      if (!pkg.name) return false;

      // 检查是否包含buddy-plugin关键词或是@coffic作用域下的包
      return (
        (pkg.name.includes('buddy-plugin') ||
          pkg.name.includes('plugin-') ||
          pkg.name.startsWith('@coffic/')) &&
        // 检查关键词
        pkg.keywords &&
        Array.isArray(pkg.keywords) &&
        (pkg.keywords.includes('buddy-plugin') ||
          pkg.keywords.includes('buddy') ||
          pkg.keywords.includes('gitok') ||
          pkg.keywords.includes('plugin'))
      );
    });

    // 将包信息转换为SuperPlugin对象
    const plugins: PluginEntity[] = buddyPlugins.map((pkg: NpmPackage) => PluginEntity.fromNpmPackage(pkg));

    logger.info(`处理搜索结果`, {
      foundPackages,
      validPlugins: plugins.length,
    });

    return { plugins, foundPackages, validPlugins: plugins.length };
  }

  /**
   * 刷新远程插件列表缓存
   * 从 npm registry 获取 coffic 组织下的所有包
   */
  public async refreshRemotePlugins(): Promise<void> {
    try {
      logger.info('开始刷新远程插件列表缓存');

      // 搜索 buddy-plugin 关键词
      const packages = await this.searchPlugins();

      if (packages && Array.isArray(packages) && packages.length > 0) {
        const result = await this.processSearchResults(packages);

        if (result.plugins.length > 0) {
          this.cachedRemotePlugins = result.plugins;
          this.lastCacheRefreshTime = Date.now();
          logger.info(`远程插件列表缓存已更新`, {
            count: result.plugins.length,
          });
          return;
        }
      }

      // 搜索失败，使用后备数据
      logger.warn('未能获取包列表，使用后备数据');
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

  /**
   * 从npm registry获取包的元数据
   * @param packageName NPM包名
   */
  public async fetchPackageMetadata(packageName: string): Promise<any> {
    return npmRegistryService.fetchPackageMetadata(packageName);
  }
}

// 导出单例
export const remotePluginDB = RemotePluginDB.getInstance();
