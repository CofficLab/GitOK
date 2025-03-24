/**
 * 插件商店相关类型定义
 *
 * 设计思路：
 * 1. 继承基础插件信息，扩展商店特有的属性
 * 2. 使用类型别名简化位置类型的定义
 * 3. 提供完整的商店插件信息结构
 *
 * 主要用途：
 * - 定义插件商店中插件的数据结构
 * - 提供插件位置和状态的类型支持
 * - 支持插件商店的功能实现
 */

import { BasePluginInfo, PluginValidation } from './base';
import { PluginDirectories } from './config';

/**
 * 插件位置类型
 * 定义了插件可以安装的位置
 */
export type PluginLocation = 'user' | 'dev';

/**
 * 商店插件信息
 * 继承基础插件信息，添加商店特有的属性
 */
export interface StorePlugin extends BasePluginInfo {
  /**
   * 插件目录信息
   */
  directories: PluginDirectories;

  /**
   * 推荐安装位置
   */
  recommendedLocation: PluginLocation;

  /**
   * 当前安装位置（如果已安装）
   */
  currentLocation?: PluginLocation;

  /**
   * 插件验证状态
   */
  validation?: PluginValidation;
}
