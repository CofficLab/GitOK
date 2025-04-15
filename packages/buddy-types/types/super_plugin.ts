/**
 * 插件核心类型定义
 *
 * 设计思路：
 * 1. 继承基础插件信息接口，扩展插件特定的属性
 * 2. 区分已安装插件和插件包的类型定义
 * 3. 使用严格的类型定义，确保类型安全
 *
 * 主要用途：
 * - 定义已安装插件的结构
 * - 定义插件包的结构
 * - 提供插件系统核心类型支持
 */

import { PluginValidation } from './plugin-validation';

/**
 * 插件类型
 * - user: 用户安装的插件
 * - dev: 开发中的插件
 */
export type PluginType = 'user' | 'dev' | 'remote';

/**
 * 插件信息接口
 */
export interface SuperPlugin {
  /**
   * 插件ID
   */
  id: string;

  /**
   * 插件名称
   */
  name: string;

  /**
   * 插件描述
   */
  description: string;

  /**
   * 插件版本
   */
  version: string;

  /**
   * 插件作者
   */
  author: string;

  /**
   * 插件主入口
   */
  main?: string;

  /**
   * 插件路径
   */
  path: string;

  /**
   * 插件验证状态
   */
  validation?: PluginValidation | null;

  /**
   * 插件类型
   */
  type: PluginType;

  /**
   * NPM包名称，用于远程插件
   */
  npmPackage?: string;

  /**
   * 插件页面视图路径
   * 如果存在，表示插件带有一个可以在主界面显示的视图
   */
  pagePath?: string;

  hasPage: boolean;
}
