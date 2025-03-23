/**
 * 商店相关类型定义
 */

/**
 * 商店插件信息
 */
export interface MarketplacePlugin {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  downloads: number;
  rating: number;
  isInstalled: boolean;
}
