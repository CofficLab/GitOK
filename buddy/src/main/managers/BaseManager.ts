/**
 * 基础管理器类
 * 提供通用的错误处理、日志记录等基础功能
 */
import { EventEmitter } from 'events';

export interface ManagerConfig {
  name: string;
  enableLogging?: boolean;
  logLevel?: string;
}

export abstract class BaseManager extends EventEmitter {
  protected name: string;

  constructor(config: ManagerConfig) {
    super();
    this.name = config.name;
  }

  /**
   * 统一处理错误
   * @param error 错误对象
   * @param message 错误消息
   * @param throwError 是否抛出错误
   * @returns 格式化后的错误消息
   */
  protected handleError(
    error: unknown,
    message: string,
    throwError = false
  ): string {
    const errorMessage = error instanceof Error ? error.message : String(error);
    if (throwError) {
      throw new Error(`${message}: ${errorMessage}`);
    }
    return errorMessage;
  }

  /**
   * 清理资源
   * 子类应该重写此方法以实现自己的清理逻辑
   */
  public abstract cleanup(): void;

  /**
   * 获取管理器名称
   */
  public getName(): string {
    return this.name;
  }
}
