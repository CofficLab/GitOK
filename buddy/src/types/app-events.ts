/**
 * 应用事件类型定义
 *
 * 这个文件定义了应用中使用的各种事件名称常量，
 * 确保主进程和渲染进程使用统一的事件名称。
 */

export const AppEvents = {
  /**
   * 窗口激活事件
   * 当应用窗口获得焦点或被激活时触发
   */
  ActIVATED: 'app-activated',

  /**
   * 窗口失活事件
   * 当应用窗口失去焦点时触发
   */
  DEACTIVATED: 'app-deactivated',

  /**
   * 窗口最小化事件
   */
  MINIMIZED: 'app-minimized',

  /**
   * 窗口恢复事件
   */
  RESTORED: 'app-restored',

  /**
   * 窗口关闭事件
   */
  CLOSED: 'app-closed',

  /**
   * 覆盖应用变化事件
   * 当被覆盖的应用发生变化时触发
   */
  OVERLAID_APP_CHANGED: 'overlaid-app-changed',

  /**
   * 应用准备就绪事件
   */
  READY: 'app-ready',

  /**
   * 应用将要退出事件
   */
  WILL_QUIT: 'app-will-quit',

  /**
   * 应用配置变更事件
   */
  CONFIG_CHANGED: 'app-config-changed',

  /**
   * 插件列表更新事件
   */
  LIST_UPDATED: 'plugin-list-updated',

  /**
   * 插件动作执行事件
   */
  ACTION_EXECUTED: 'plugin-action-executed',

  /**
   * 插件安装事件
   */
  INSTALLED: 'plugin-installed',

  /**
   * 插件卸载事件
   */
  UNINSTALLED: 'plugin-uninstalled',
};
