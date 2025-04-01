/**
 * NPM Registry服务
 * 负责与npm registry交互，包括搜索包、获取元数据等功能
 */
import axios from 'axios';
import { logger } from '../managers/LogManager';

/**
 * NPM包维护者信息
 */
export interface NpmMaintainer {
  name: string;
  email?: string;
  url?: string;
}

/**
 * NPM包发布者信息
 */
export interface NpmPublisher {
  username: string;
  email?: string;
}

/**
 * NPM包链接信息
 */
export interface NpmLinks {
  npm?: string;
  homepage?: string;
  repository?: string;
  bugs?: string;
}

/**
 * NPM包信息接口
 */
export interface NpmPackage {
  name: string;
  version: string;
  description?: string;
  keywords?: string[];
  date?: string;
  links?: NpmLinks;
  publisher?: NpmPublisher;
  maintainers?: NpmMaintainer[];
  scope?: string;
}

/**
 * NPM包版本信息
 */
export interface NpmPackageVersion {
  name: string;
  version: string;
  description?: string;
  main?: string;
  scripts?: Record<string, string>;
  repository?: {
    type: string;
    url: string;
  };
  keywords?: string[];
  author?: string | {
    name: string;
    email?: string;
    url?: string;
  };
  license?: string;
  bugs?: {
    url: string;
  };
  homepage?: string;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
  peerDependencies?: Record<string, string>;
  dist?: {
    shasum: string;
    tarball: string;
    integrity?: string;
    fileCount?: number;
    unpackedSize?: number;
    'npm-signature'?: string;
  };
}

/**
 * NPM包元数据接口
 */
export interface NpmPackageMetadata {
  name: string;
  'dist-tags': Record<string, string>;
  versions: Record<string, NpmPackageVersion>;
  time: Record<string, string>;
  maintainers: NpmMaintainer[];
  description?: string;
  homepage?: string;
  keywords?: string[];
  repository?: {
    type: string;
    url: string;
  };
  author?: string | {
    name: string;
    email?: string;
    url?: string;
  };
  bugs?: {
    url: string;
  };
  license?: string;
  readme?: string;
  readmeFilename?: string;
}

export class NpmRegistryService {
  private static instance: NpmRegistryService;

  // NPM registry URL
  private readonly NPM_REGISTRY = 'https://registry.npmjs.org';

  private constructor() {}

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
  public async searchPackagesByKeyword(keyword: string): Promise<NpmPackage[]> {
    const searchUrl = `${this.NPM_REGISTRY}/-/v1/search?text=keywords:${encodeURIComponent(keyword)}&size=250`;
    
    logger.info(`搜索关键词包(npm registry)`, { 
      url: searchUrl,
      keyword
    });

    try {
      const response = await axios.get(searchUrl);
      
      // 提取搜索结果中的包对象
      const foundPackages = response.data.objects?.map((obj: any) => obj.package) || [];
      
      logger.info(`成功获取关键词包列表(npm registry): ${keyword}`, {
        count: foundPackages.length,
        total: response.data.total || 0,
      });
      
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