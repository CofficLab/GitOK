/**
 * 配置相关类型定义
 *
 * 设计思路：
 * 1. 集中管理所有与配置相关的类型定义
 * 2. 使用明确的类型和注释说明每个配置项的用途
 * 3. 将目录配置抽象为独立接口，便于复用
 *
 * 主要用途：
 * - 定义插件系统的配置结构
 * - 提供目录配置的类型定义
 * - 确保配置的类型安全
 */

/**
 * 插件管理器配置
 * 定义了插件管理器的运行配置
 */
export interface PluginManagerConfig {
  /**
   * 是否启用日志
   */
  enableLogging: boolean;

  /**
   * 日志级别
   * - debug: 调试信息
   * - info: 普通信息
   * - warn: 警告信息
   * - error: 错误信息
   */
  logLevel: 'debug' | 'info' | 'warn' | 'error';
}
