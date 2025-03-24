/**
 * 基础类型定义
 *
 * 设计思路：
 * 1. 提供最基础的插件信息接口，作为其他插件相关接口的基础
 * 2. 将共用的字段抽象到基础接口中，避免重复定义
 * 3. 使用严格的类型定义，确保类型安全
 *
 * 主要用途：
 * - 作为其他插件相关接口的基础接口
 * - 提供统一的插件基本信息结构
 * - 减少代码重复，提高维护性
 */

/**
 * 插件基础信息接口
 * 定义了插件最基本的属性，所有插件相关的接口都应该继承此接口
 */
export interface BasePluginInfo {
  /**
   * 插件唯一标识
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
}

/**
 * 插件验证状态
 * 用于表示插件的验证结果
 */
export interface PluginValidation {
  /**
   * 是否验证通过
   */
  isValid: boolean;

  /**
   * 验证错误信息列表
   */
  errors: string[];
}
