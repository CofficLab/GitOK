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
 * 插件信息接口
 */
export interface Plugin {
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
  main: string;

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
  type: 'user' | 'dev';
}
