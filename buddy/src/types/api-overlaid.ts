/**
 * 被覆盖应用模块的类型定义
 * 处理应用被其他窗口覆盖的状态变化的接口
 */

// 覆盖应用的信息类型
export interface OverlaidApp {
  name: string;
  bundleId: string;
}

export interface OverlaidApi {
  /**
   * 监听覆盖应用变化事件
   * @param callback 当覆盖应用发生变化时的回调函数
   * @returns 取消监听的函数
   */
  onOverlaidAppChanged: (
    callback: (app: OverlaidApp | null) => void
  ) => () => void;
}
