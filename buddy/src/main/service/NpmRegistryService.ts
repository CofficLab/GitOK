/**
 * NPM Registry服务
 * 负责与npm registry交互，包括搜索包、获取元数据等功能
 */
import axios from 'axios';
import { logger } from '../managers/LogManager.js';
import { NpmPackageMetadata, PackageJson } from '@/types/package-json.js';

const verbose = false;

export class NpmRegistryService {
  private static instance: NpmRegistryService;

  // NPM registry URL
  private readonly NPM_REGISTRY = 'https://registry.npmjs.org';

  private constructor() { }

  public static getInstance(): NpmRegistryService {
    if (!NpmRegistryService.instance) {
      NpmRegistryService.instance = new NpmRegistryService();
    }
    return NpmRegistryService.instance;
  }

  /**
   * 使用关键词搜索npm包
   * @param keyword 关键词
   * @returns 符合关键词的NPM包列表
   */
  public async searchPackagesByKeyword(keyword: string): Promise<PackageJson[]> {
    const searchUrl = `${this.NPM_REGISTRY}/-/v1/search?text=keywords:${encodeURIComponent(keyword)}&size=250`;

    if (verbose) {
      logger.info(`搜索关键词包(npm registry)`, {
        url: searchUrl,
        keyword
      });
    }

    try {
      const response = await axios.get(searchUrl);

      // 提取搜索结果中的包对象
      const foundPackages = response.data.objects?.map((obj: any) => obj.package) || [];

      if (verbose) {
        logger.info(`成功获取关键词包列表，count`, foundPackages.length);
      }

      return foundPackages;
    } catch (error) {
      const errorMsg = error instanceof Error
        ? `npm registry请求失败: ${error.message}`
        : `npm registry请求失败: ${String(error)}`;

      logger.error(errorMsg, {
        keyword,
        error,
        response: axios.isAxiosError(error) ? (error as any).response?.data : undefined,
        status: axios.isAxiosError(error) ? (error as any).response?.status : undefined
      });

      throw new Error(errorMsg);
    }
  }

  /**
   * 从npm registry获取包的元数据
   * @param packageName NPM包名
   */
  public async fetchPackageMetadata(packageName: string): Promise<NpmPackageMetadata> {
    const url = `${this.NPM_REGISTRY}/${packageName}`;

    logger.info(`请求NPM包元数据: ${packageName}`, {
      url,
      registry: this.NPM_REGISTRY,
      packageName,
    });

    try {
      const response = await axios.get(url);
      const metadata = response.data;

      logger.info(`成功获取包元数据: ${packageName}`, {
        url,
        statusCode: response.status,
        headers: response.headers,
        versions: Object.keys(metadata.versions || {}),
        distTags: metadata['dist-tags'],
      });

      return metadata;
    } catch (error) {
      const errorMsg = error instanceof Error
        ? `获取元数据失败: ${error.message}`
        : `获取元数据失败: ${String(error)}`;

      logger.error(errorMsg, {
        url,
        packageName,
        error,
        response: axios.isAxiosError(error) ? (error as any).response?.data : undefined,
        status: axios.isAxiosError(error) ? (error as any).response?.status : undefined
      });

      throw new Error(errorMsg);
    }
  }
}

// 导出单例
export const npmRegistryService = NpmRegistryService.getInstance();