/**
 * 远程插件数据库
 * 负责从远程 npm registry 获取插件并缓存
 */
import * as https from 'https';
import { SuperPlugin } from '@/types/super_plugin';
import { logger } from '../managers/LogManager';

export class RemotePluginDB {
  private static instance: RemotePluginDB;

  // NPM registry URL
  private readonly NPM_REGISTRY = 'https://registry.npmjs.org';

  // coffic 组织名
  private readonly COFFIC_SCOPE = '@coffic';

  // 缓存刷新时间间隔 (毫秒): 1小时
  private readonly CACHE_REFRESH_INTERVAL = 60 * 60 * 1000;

  // 上次缓存刷新时间
  private lastCacheRefreshTime: number = 0;

  // 插件列表缓存
  private cachedRemotePlugins: SuperPlugin[] = [];

  // 模拟远程插件列表 (作为后备数据)
  private fallbackPlugins: SuperPlugin[] = [
    {
      id: '@coffic/plugin-ide-workspace',
      name: 'IDE工作空间',
      version: '1.0.0',
      description: '显示当前IDE的工作空间信息',
      author: 'Coffic Lab',
      type: 'remote',
      path: '',
      npmPackage: '@coffic/plugin-ide-workspace',
    },
    {
      id: '@coffic/buddy-example-plugin',
      name: '示例插件',
      version: '1.0.0',
      description: '示例插件',
      author: 'Coffic Lab',
      type: 'remote',
      path: '',
      npmPackage: '@coffic/buddy-example-plugin',
    },
  ];

  /**
   * 刷新缓存标志，防止并发刷新
   */
  private isRefreshingCache = false;

  private constructor() {
    // 初始化时立即刷新插件列表
    this.refreshRemotePlugins();

    // 设置定时刷新
    setInterval(() => {
      this.refreshRemotePlugins();
    }, this.CACHE_REFRESH_INTERVAL);
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
  public async getRemotePlugins(): Promise<SuperPlugin[]> {
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
        logger.info(`远程插件列表缓存已更新`, {
          count: this.cachedRemotePlugins.length,
        });
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

      // 如果正在刷新缓存且没有缓存数据，返回预设插件列表
      return this.fallbackPlugins;
    } catch (error) {
      logger.error(
        `获取远程插件列表失败: ${error instanceof Error ? error.message : String(error)}`
      );
      return this.fallbackPlugins;
    }
  }

  /**
   * 搜索并处理插件
   */
  private async searchPlugins(): Promise<{
    plugins: SuperPlugin[];
    foundPackages: number;
    validPlugins: number;
  }> {
    logger.info(`搜索插件关键词: buddy-plugin`);

    try {
      // 主要搜索: buddy-plugin关键词
      const packages = await this.searchPackagesByKeyword('buddy-plugin');

      // 处理搜索结果
      const result = await this.processSearchResults(packages);

      return result;
    } catch (error) {
      logger.error(
        `搜索插件失败: ${error instanceof Error ? error.message : String(error)}`
      );
      return {
        plugins: this.fallbackPlugins,
        foundPackages: 0,
        validPlugins: this.fallbackPlugins.length,
      };
    }
  }

  /**
   * 处理搜索结果，筛选出符合条件的插件
   */
  private async processSearchResults(packages: any[]): Promise<{
    plugins: SuperPlugin[];
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
    const plugins: SuperPlugin[] = buddyPlugins.map((pkg) => ({
      id: pkg.name,
      name: this.formatPluginName(pkg.name),
      version: pkg.version || '0.0.0',
      description: pkg.description || '',
      author:
        pkg.publisher?.username || pkg.maintainers?.[0]?.name || 'unknown',
      homepage: pkg.links?.homepage || pkg.links?.npm || '',
      icon: '📦',
      installed: false,
      remote: true,
      path: '',
      type: 'remote', // 添加缺少的type属性
      npmPackage: pkg.name, // 确保npmPackage属性存在
    }));

    logger.info(`处理搜索结果`, {
      foundPackages,
      validPlugins: plugins.length,
    });

    return { plugins, foundPackages, validPlugins: plugins.length };
  }

  /**
   * 使用关键词搜索npm包
   * @param keyword 关键词
   */
  private async searchPackagesByKeyword(keyword: string): Promise<any[]> {
    return new Promise((resolve, reject) => {
      // npm registry 搜索 API
      const searchUrl = `${this.NPM_REGISTRY}/-/v1/search?text=keywords:${encodeURIComponent(keyword)}&size=250`;

      logger.info(`搜索关键词包(npm registry): ${keyword}`, { url: searchUrl });

      https
        .get(searchUrl, (res) => {
          let data = '';

          res.on('data', (chunk) => {
            data += chunk;
          });

          res.on('end', () => {
            if (res.statusCode === 200) {
              try {
                const response = JSON.parse(data);

                // 提取搜索结果中的包对象
                const foundPackages =
                  response.objects?.map((obj: any) => obj.package) || [];

                logger.info(`成功获取关键词包列表(npm registry): ${keyword}`, {
                  count: foundPackages.length,
                  total: response.total || 0,
                });

                // 如果搜索API返回了结果，使用这些结果
                if (foundPackages.length > 0) {
                  resolve(foundPackages);
                  return;
                }

                // 如果搜索结果为空，尝试使用npm search命令的方式获取包列表
                logger.warn(
                  `npm registry API未返回关键词 ${keyword} 的相关包，尝试回退到内置列表`
                );
                resolve(this.getFallbackPackagesList(this.COFFIC_SCOPE));
              } catch (err) {
                const errorMsg = `解析npm registry搜索结果失败: ${err instanceof Error ? err.message : String(err)}`;
                logger.error(errorMsg, {
                  responseData: data.substring(0, 1000),
                });
                reject(new Error(errorMsg));
              }
            } else {
              const errorMsg = `npm registry搜索失败，状态码: ${res.statusCode}`;
              logger.error(errorMsg, {
                keyword,
                statusCode: res.statusCode,
                headers: res.headers,
                responseBody: data,
              });
              reject(new Error(errorMsg));
            }
          });
        })
        .on('error', (err) => {
          const errorMsg = `npm registry请求失败: ${err.message}`;
          logger.error(errorMsg, { keyword, error: err });
          reject(new Error(errorMsg));
        });
    });
  }

  /**
   * 刷新远程插件列表缓存
   * 从 npm registry 获取 coffic 组织下的所有包
   */
  public async refreshRemotePlugins(): Promise<void> {
    try {
      logger.info('开始刷新远程插件列表缓存');

      // 搜索 buddy-plugin 关键词
      const packages = await this.searchPackagesByKeyword('buddy-plugin');

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
    return new Promise((resolve, reject) => {
      const url = `${this.NPM_REGISTRY}/${packageName}`;
      logger.info(`请求NPM包元数据: ${packageName}`, {
        url,
        registry: this.NPM_REGISTRY,
        packageName,
      });

      https
        .get(url, (res) => {
          let data = '';

          res.on('data', (chunk) => {
            data += chunk;
          });

          res.on('end', () => {
            if (res.statusCode === 200) {
              try {
                const metadata = JSON.parse(data);
                logger.info(`成功获取包元数据: ${packageName}`, {
                  url,
                  statusCode: res.statusCode,
                  headers: res.headers,
                  versions: Object.keys(metadata.versions || {}),
                  distTags: metadata['dist-tags'],
                });
                resolve(metadata);
              } catch (err) {
                const errorMsg = `解析元数据失败: ${err instanceof Error ? err.message : String(err)}`;
                logger.error(errorMsg, {
                  url,
                  packageName,
                  error: err,
                  responseData: data.substring(0, 1000), // 记录前1000个字符用于调试
                });
                reject(new Error(errorMsg));
              }
            } else {
              const errorMsg = `获取元数据失败，状态码: ${res.statusCode}`;
              logger.error(errorMsg, {
                url,
                packageName,
                statusCode: res.statusCode,
                headers: res.headers,
                responseBody: data, // 记录完整响应内容
              });
              reject(new Error(errorMsg));
            }
          });
        })
        .on('error', (err) => {
          const errorMsg = `请求失败: ${err.message}`;
          logger.error(errorMsg, {
            url,
            packageName,
            error: err,
          });
          reject(new Error(errorMsg));
        });
    });
  }

  /**
   * 格式化插件名称为更友好的显示名称
   * @param packageName 包名
   */
  private formatPluginName(packageName: string): string {
    // 移除作用域前缀
    let name = packageName.replace(this.COFFIC_SCOPE + '/', '');

    // 移除常见插件前缀
    const prefixes = ['plugin-', 'buddy-'];
    for (const prefix of prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
        break;
      }
    }

    // 转换为标题格式 (每个单词首字母大写)
    return name
      .split('-')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  /**
   * 获取@coffic作用域下的已知包列表（作为搜索API的备选方案）
   */
  private getFallbackPackagesList(scope: string): any[] {
    // 确保这是针对@coffic作用域的请求
    if (scope !== this.COFFIC_SCOPE) {
      return [];
    }

    // 手动维护的@coffic作用域下的包列表，从npm search获取
    return [
      {
        name: '@coffic/cosy-ui',
        version: '0.3.15',
        description: 'An astro component library',
        keywords: [
          'astro-integration',
          'astro-component',
          'withastro',
          'astro',
          'cosy-ui',
        ],
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
      {
        name: '@coffic/juice-editor-draw',
        version: '1.0.5',
        description: '![editor](./docs/hero.png)',
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
      {
        name: '@coffic/juice-editor',
        version: '0.9.122',
        description: '![JuiceEditor](./docs/hero.png)',
        keywords: [
          'tiptap',
          'headless',
          'wysiwyg',
          'text editor',
          'prosemirror',
        ],
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
      {
        name: '@coffic/buddy-example-plugin',
        version: '1.0.1',
        description: 'Buddy示例插件',
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
        keywords: ['buddy-plugin', 'gitok', 'plugin'],
      },
      {
        name: '@coffic/active-app-monitor',
        version: '1.0.1',
        description:
          '一个用于获取 macOS 系统当前活跃应用信息的 Node.js 原生模块',
        keywords: [
          'macos',
          'active-window',
          'frontmost-app',
          'native-module',
          'node-addon',
        ],
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
      {
        name: '@coffic/command-key-listener',
        version: '1.0.2',
        description: 'macOS系统Command键双击事件监听器',
        keywords: [
          'macos',
          'command-key',
          'hotkeys',
          'keyboard',
          'listener',
          'native',
        ],
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
      {
        name: '@coffic/plugin-ide-workspace',
        version: '1.1.1',
        description: 'GitOK插件 - IDE工作空间信息显示，支持Git自动提交',
        keywords: ['gitok', 'plugin', 'ide', 'workspace', 'vscode'],
        publisher: { username: 'nookery' },
        maintainers: [{ name: 'nookery' }],
      },
    ];
  }
}

// 导出单例
export const remotePluginDB = RemotePluginDB.getInstance();
